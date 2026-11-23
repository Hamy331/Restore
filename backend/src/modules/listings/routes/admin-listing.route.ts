import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { authorizePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as moderationController from '../controllers/moderation.controller.js';
import { notifyViewers } from '../services/listing.events.js';
import { adminDecisionBody, adminListingQuery, bannedTermBody, bannedTermParams, listingIdParams } from '../listing.validator.js';

/** Quản trị tin, gắn tại /api/v1/admin (adminRouter đã xác thực token) */
const adminListingRouter = Router();
const moderate = authorizePermission(PERMISSION.LISTING_MODERATE);

/**
 * Mọi tin, cập nhật gần nhất trước, 25 tin mỗi trang
 *
 * Query params:
 *  - status?: ListingStatus
 *  - q?: string (1-100) - tìm trong tiêu đề, không phân biệt hoa thường
 *  - edit?: 'PENDING' - chỉ tin có bản sửa chờ duyệt, gửi sớm trước
 *  - tier?: PERSONAL | BASIC | PRO - gói của người đăng
 *  - flagged?: '1' - chỉ tin / bản sửa bị gắn cờ lúc gửi duyệt
 *  - offender?: '1' - chỉ tin của người đăng tái phạm (từ 3 lần bị từ chối / gỡ trong 30 ngày)
 *  - page?: number (mặc định 1)
 *
 * Trả về: { items: [tin kèm owner (planTier, shop, history { rejected, changesRequested, removed, recentStrikes }), category], total, page }
 * Tin có bản sửa thêm pendingEdit (nội dung bản sửa, updatedAt của bản sửa) và current (nội dung đang hiển thị để so sánh).
 */
adminListingRouter.get('/listings', moderate, validate({ query: adminListingQuery }), moderationController.listForAdmin);

/**
 * Lịch sử vi phạm của người đăng tin (theo nhật ký quản trị, gồm cả quyết định trên bản sửa)
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Trả về: { rejected, changesRequested, removed, recentStrikes, recent: [{ listingId, title, action, reason, createdAt }] (5 lần gần nhất) }
 * Lỗi 404: LISTING_NOT_FOUND
 */
adminListingRouter.get('/listings/:id/seller-history', moderate, validate({ params: listingIdParams }), moderationController.sellerHistory);

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
  notifyViewers, moderationController.adminDecide);

/**
 * Từ / cụm từ admin thêm vào bộ lọc nội dung tin (ngoài luật có sẵn), mới trước. Khớp nguyên từ, không phân biệt
 * hoa thường; có dấu và không dấu là hai từ khác nhau. Áp dụng ngay cho tin gửi sau đó (máy chủ khác trễ tối đa 1 phút).
 *
 * Trả về: [{ id, term, code: CONTACT | BANNED, createdAt }]
 */
adminListingRouter.get('/banned-terms', moderate, moderationController.bannedTerms);

/**
 * Thêm từ vào bộ lọc; ghi AdminAudit TERM_ADD
 *
 * Body: term (2-60 ký tự, lưu chữ thường), code: 'CONTACT' | 'BANNED'
 * Trả về: 201 { id, term, code, createdAt }
 * Lỗi: 409 TERM_EXISTS
 */
adminListingRouter.post('/banned-terms', moderate, validate({ body: bannedTermBody }), moderationController.addBannedTerm);

/**
 * Bỏ từ khỏi bộ lọc; ghi AdminAudit TERM_REMOVE. Trả 204
 * Lỗi: 404 TERM_NOT_FOUND
 */
adminListingRouter.delete('/banned-terms/:id', moderate, validate({ params: bannedTermParams }), moderationController.removeBannedTerm);

export default adminListingRouter;
