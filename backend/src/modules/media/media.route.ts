import { Router, raw, Response, NextFunction } from 'express';
import { created } from '../../common/http/response.js';
import { AuthRequest, verifyToken } from '../../middlewares/auth.middleware.js';
import { mediaPurpose, readMedia, uploadMedia } from './media.service.js';

/** /api/v1/media: ảnh bài viết bảng tin và ảnh đại diện (lưu qua storage.service) */
export const mediaRouter = Router();

/**
 * Tải ảnh lên. Body là byte ảnh JPEG/PNG/WebP, tối đa 5 MB.
 *
 * Query: purpose = feed (mặc định) | avatar
 *
 * Trả về: 201 { imageUrl: "/api/v1/media/<feeds|avatars>/<userId>_<uuid>.<ext>" }
 */
mediaRouter.post('/images', verifyToken, raw({ type: ['image/jpeg', 'image/png', 'image/webp'], limit: '5mb' }),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      const imageUrl = await uploadMedia(req.user!.userId, mediaPurpose(req.query.purpose), req.body);
      created(res, { imageUrl });
    } catch (error) { next(error); }
  });

/**
 * File ảnh. Ảnh bài viết và ảnh đại diện ai cũng xem được; tên file là UUID
 * nên không đoán được và có thể cache lâu.
 */
mediaRouter.get('/:area/:name', async (req, res, next) => {
  try {
    const { bytes, contentType } = await readMedia(req.params.area, req.params.name);
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    res.type(contentType).send(bytes);
  } catch (error) { next(error); }
});
