import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { authorizePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as moderationController from '../controllers/moderation.controller.js';
import { adminDecisionBody, adminListingQuery, listingIdParams } from '../listing.validator.js';

/** Quản trị tin, gắn tại /api/v1/admin (adminRouter đã xác thực token) */
const adminListingRouter = Router();
const moderate = authorizePermission(PERMISSION.LISTING_MODERATE);

/**
 * Mọi tin, cập nhật gần nhất trước, 25 tin mỗi trang
 *
 * Query params:
 *  - status?: ListingStatus
 *  - q?: string (1-100) - tìm trong tiêu đề, không phân biệt hoa thường
 *  - page?: number (mặc định 1)
 *
 * Trả về: { items: [tin kèm owner, category], total, page }
 */
adminListingRouter.get('/listings', moderate, validate({ query: adminListingQuery }), moderationController.listForAdmin);

/**
 * Duyệt / từ chối / yêu cầu sửa tin đang chờ, hoặc gỡ tin đang hiển thị; ghi AdminAudit
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Body:
 *  - action: 'APPROVE' | 'REJECT' | 'REQUEST_CHANGES' | 'REMOVE'
 *  - reason: string (5-300, APPROVE thì 0-300)
 *  - updatedAt: ISO 8601 - updatedAt của tin lúc admin mở
 *
 * Trả về: { updated: true }
 */
adminListingRouter.post('/listings/:id/decision', moderate, validate({ params: listingIdParams, body: adminDecisionBody }),
  moderationController.adminDecide);

export default adminListingRouter;
