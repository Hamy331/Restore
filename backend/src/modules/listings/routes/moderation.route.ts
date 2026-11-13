import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as moderationController from '../controllers/moderation.controller.js';
import { decisionBody, listingIdParams } from '../listing.validator.js';

/** Duyệt tin, gắn tại /api/v1/listings/admin */
const moderationRouter = Router();
const moderate = requirePermission(PERMISSION.LISTING_MODERATE);

/**
 * Duyệt hoặc từ chối tin đang chờ, ghi AdminAudit.
 * Tin đã duyệt có bản sửa chờ duyệt: duyệt thì bản sửa thay vào tin, từ chối thì tin giữ bản cũ
 * (updatedAt lúc này là updatedAt của bản sửa, lấy từ /admin/pending).
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Body:
 *  - decision: 'APPROVED' | 'REJECTED'
 *  - reason?: string - bắt buộc 5-300 ký tự khi REJECTED
 *  - updatedAt: ISO 8601 - updatedAt của tin lúc admin mở, để tránh duyệt đè
 *
 * Trả về: { success: true } (không có data)
 */
moderationRouter.post('/admin/:id/decision', moderate, validate({ params: listingIdParams, body: decisionBody }), moderationController.decide);

/**
 * Tối đa 100 tin chờ duyệt, gửi sớm trước, rồi tối đa 100 bản sửa của tin đã duyệt
 * (edit: true, nội dung là bản sửa, current: nội dung đang hiển thị, updatedAt của bản sửa)
 */
moderationRouter.get('/admin/pending', moderate, moderationController.listPending);

export default moderationRouter;
