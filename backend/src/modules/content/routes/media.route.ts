import express, { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { optionalAuth, requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { mediaParams } from '../content.validator.js';
import * as mediaController from '../controllers/media.controller.js';

/** Ảnh nội dung (bìa bài viết), gắn tại /api/v1/content */
const mediaRouter = Router();

/**
 * Tải ảnh bìa lên (JPEG, PNG, WebP tối đa 5 MB)
 *
 * Header: Content-Type: image/jpeg | image/png | image/webp, body là byte ảnh
 *
 * Trả về: { url }
 */
mediaRouter.post(
  '/media',
  requirePermission(PERMISSION.CONTENT_MANAGE),
  express.raw({ type: () => true, limit: '5mb' }),
  mediaController.upload,
);

/**
 * File ảnh. Ảnh bìa của bài đã đăng ai cũng xem được; ảnh khác chỉ người quản lý nội dung
 *
 * Path params:
 *  - filename: string - "<uuid>.jpg|png|webp"
 */
mediaRouter.get('/media/:filename', optionalAuth, validate({ params: mediaParams }), mediaController.read);

export default mediaRouter;
