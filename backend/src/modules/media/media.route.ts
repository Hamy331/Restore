import { Router, raw, Response, NextFunction } from 'express';
import { hasPermission, PERMISSION } from '../../common/auth/permissions.js';
import { AppError } from '../../common/errors/app-error.js';
import { created } from '../../common/http/response.js';
import { AuthRequest, verifyToken } from '../../middlewares/auth.middleware.js';
import { sendStored } from '../../common/http/stored-file.js';
import { thumbWidth } from '../../services/storage.service.js';
import { MEDIA_AREAS, mediaPurpose, PRIVATE_AREAS, readMedia, readPrivateMedia, uploadMedia } from './media.service.js';

/** /api/v1/media: ảnh bài viết bảng tin và ảnh đại diện (lưu qua storage.service) */
export const mediaRouter = Router();

/**
 * Tải ảnh lên. Body là byte ảnh JPEG/PNG/WebP, tối đa 5 MB.
 *
 * Query: purpose = feed (mặc định) | avatar | poster | shop | verification (giấy tờ xác minh shop, khu riêng)
 *
 * Trả về: 201 { imageUrl: "/api/v1/media/<feeds|avatars|posters|shops|verifications>/<userId>_<uuid>.<ext>" }
 */
mediaRouter.post('/images', verifyToken, raw({ type: ['image/jpeg', 'image/png', 'image/webp'], limit: '5mb' }),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const imageUrl = await uploadMedia(req.user!.userId, mediaPurpose(req.query.purpose), req.body);
      created(res, { imageUrl });
    } catch (error) { next(error); }
  });

/**
 * Giấy tờ xác minh shop: chỉ chủ ảnh (tên file bắt đầu bằng userId) hoặc admin duyệt tin xem được, không cache.
 * Người khác nhận 404 như ảnh không tồn tại.
 */
mediaRouter.get(`/${MEDIA_AREAS.verification}/:name`, verifyToken, async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { userId, role } = req.user!;
    const name = String(req.params.name);
    if (!name.startsWith(`${userId}_`) && !hasPermission(role, PERMISSION.LISTING_MODERATE)) {
      throw new AppError(404, 'MEDIA_NOT_FOUND', 'Không tìm thấy ảnh.');
    }
    const { bytes, contentType } = await readPrivateMedia(MEDIA_AREAS.verification, name);
    res.setHeader('Cache-Control', 'private, no-store');
    res.type(contentType).send(bytes);
  } catch (error) { next(error); }
});

/**
 * File ảnh. Ảnh bài viết, ảnh đại diện, shop, poster ai cũng xem được; tên file là UUID
 * nên không đoán được và có thể cache lâu. Lưu trên Cloudinary thì chuyển hướng 302 sang CDN.
 *
 * Query: w? = bề ngang cần hiển thị; trả bản thu nhỏ cỡ 240 | 480 | 960 nhỏ nhất đủ rộng
 * (lớn hơn 960 hoặc không gửi: ảnh gốc)
 */
mediaRouter.get('/:area/:name', async (req, res, next) => {
  try {
    if (PRIVATE_AREAS.includes(req.params.area)) throw new AppError(404, 'MEDIA_NOT_FOUND', 'Không tìm thấy ảnh.');
    const file = await readMedia(req.params.area, req.params.name, thumbWidth(req.query.w));
    sendStored(res, file, 'public, max-age=31536000, immutable');
  } catch (error) { next(error); }
});
