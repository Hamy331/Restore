import express, { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { optionalAuth, requirePermission, type AuthRequest } from '../../../middlewares/auth.middleware.js';
import { MemoryRateStore, rateLimit } from '../../../middlewares/rate-limit.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as imageController from '../controllers/image.controller.js';
import { aiComposeQuery, listingIdParams, mediaParams } from '../listing.validator.js';

/** Ảnh tin đăng, gắn tại /api/v1/listings */
const imageRouter = Router();
const manageOwn = requirePermission(PERMISSION.LISTING_MANAGE_OWN);

/** AI soạn tin tốn hạn mức Gemini: 20 lần / giờ cho mỗi người */
const composeStore = new MemoryRateStore();
setInterval(() => composeStore.sweep(), 10 * 60_000).unref();
const composeLimit = rateLimit([{
  name: 'ai-compose', limit: 20, windowMs: 60 * 60_000, key: (req) => (req as AuthRequest).user?.userId,
  message: 'Bạn đã dùng AI soạn tin quá nhiều lần.',
}], composeStore);

/**
 * File ảnh tin. Tin đang hiển thị thì ai cũng xem được; tin khác chỉ chủ tin và người kiểm duyệt
 *
 * Path params:
 *  - filename: string - "<uuid>.jpg|png|webp"
 *
 * Query:
 *  - w?: number - bề ngang cần hiển thị; trả thumbnail WebP cỡ 240 | 480 | 960 nhỏ nhất đủ rộng
 *    (lớn hơn 960 hoặc không gửi: ảnh gốc)
 *
 * Trả về: file ảnh (Cache-Control: private, max-age=604800, immutable)
 */
imageRouter.get('/media/:filename', optionalAuth, validate({ params: mediaParams }), imageController.read);

/**
 * Thêm ảnh vào cuối danh sách (tối đa 20 ảnh, 5 MB). Tin không phải nháp quay lại chờ duyệt
 *
 * Header: Content-Type: image/jpeg | image/png | image/webp, body là byte ảnh
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Trả về: 201 { url }
 */
imageRouter.post(
  '/:id/images',
  manageOwn,
  express.raw({ type: () => true, limit: '5mb' }),
  validate({ params: listingIdParams }),
  imageController.add,
);

/**
 * AI soạn nội dung tin từ một ảnh (ảnh bìa) và xem món có phải hàng cấm không; không lưu gì.
 * Chỉ là gợi ý cho người bán sửa lại. 20 lần / giờ mỗi người.
 *
 * Header: Content-Type: image/jpeg | image/png | image/webp, body là byte ảnh (tối đa 5 MB)
 *
 * Query:
 *  - categoryId?: string - danh mục đã chọn, để AI viết đúng loại hàng
 *
 * Trả về: { title, description, condition (NEW | LIKE_NEW | USED_GOOD | USED_FAIR | FOR_PARTS | null),
 *   prohibited (AI nghi là hàng cấm), reason (lý do khi prohibited, còn lại rỗng) }
 * Lỗi: 503 AI_NOT_CONFIGURED (chưa bật AI), 503 AI_NO_ANSWER / AI_UNAVAILABLE / AI_PROVIDER_RATE_LIMIT, 429 khi dùng quá nhiều
 */
imageRouter.post(
  '/ai/compose',
  manageOwn,
  composeLimit,
  express.raw({ type: () => true, limit: '5mb' }),
  validate({ query: aiComposeQuery }),
  imageController.compose,
);

/**
 * Sắp xếp lại hoặc bỏ bớt ảnh (chỉ gồm ảnh đang có); file ảnh bị bỏ được xóa
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Body:
 *  - images: string[] - URL ảnh theo thứ tự mới
 *
 * Trả về: { images }
 */
imageRouter.put('/:id/images', manageOwn, validate({ params: listingIdParams }), imageController.reorder);

export default imageRouter;
