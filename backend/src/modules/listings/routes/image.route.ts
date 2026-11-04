import express, { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { optionalAuth, requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as imageController from '../controllers/image.controller.js';
import { listingIdParams, mediaParams } from '../listing.validator.js';

/** Ảnh tin đăng, gắn tại /api/v1/listings */
const imageRouter = Router();
const manageOwn = requirePermission(PERMISSION.LISTING_MANAGE_OWN);

/**
 * File ảnh tin. Tin đang hiển thị thì ai cũng xem được; tin khác chỉ chủ tin và người kiểm duyệt
 *
 * Path params:
 *  - filename: string - "<uuid>.jpg|png|webp"
 *
 * Trả về: file ảnh (Cache-Control: private, no-store)
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
