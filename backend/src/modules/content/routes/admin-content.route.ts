import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { authorizePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import {
  adminPostListQuery, adminReportQuery, adminTicketReplyBody, idParams, knowledgeBody, pageOnlyQuery, postBody, resolveReportBody, ticketStatusBody, versionBody,
} from '../content.validator.js';
import * as knowledgeController from '../controllers/knowledge.controller.js';
import * as postController from '../controllers/post.controller.js';
import * as reportController from '../controllers/report.controller.js';
import * as ticketController from '../controllers/ticket.controller.js';

/**
 * Quản trị nội dung, gắn tại /api/v1/admin (adminRouter đã xác thực token).
 * Danh sách đều 25 bản ghi mỗi trang, trả { items, total, page }.
 * Mọi thao tác ghi đều kèm updatedAt lúc đọc (409 ADMIN_STALE nếu đã đổi) và ghi AdminAudit.
 */
const adminContentRouter = Router();
const manageContent = authorizePermission(PERMISSION.CONTENT_MANAGE);
const manageUsers = authorizePermission(PERMISSION.USER_MANAGE);

/* ---------- Bài viết ---------- */

/**
 * Mọi bài viết, cập nhật gần nhất trước
 *
 * Query params:
 *  - page?: number (mặc định 1)
 */
adminContentRouter.get('/posts', manageContent, validate({ query: adminPostListQuery }), postController.listForAdmin);

/**
 * Tạo bài viết (POST) hoặc sửa bài (PUT /posts/:id)
 *
 * Body:
 *  - title: string (5-160), slug: string (3-160, a-z 0-9 -), category: string (2-100), content: string (20-50000)
 *  - status: 'DRAFT' | 'PUBLISHED' | 'HIDDEN' | 'ARCHIVED'
 *  - coverUrl?: string - ảnh đã tải lên /content/media
 *  - listingIds: string[] (tối đa 10) - tin đang hiển thị
 *  - updatedAt: ISO 8601 - chỉ khi sửa
 */
adminContentRouter.post('/posts', manageContent, validate({ body: postBody }), postController.create);
adminContentRouter.put('/posts/:id', manageContent, validate({ params: idParams, body: postBody }), postController.update);

/* ---------- Hỗ trợ ---------- */

/**
 * Mọi yêu cầu hỗ trợ kèm tin nhắn, cập nhật gần nhất trước
 *
 * Query params:
 *  - page?: number (mặc định 1)
 */
adminContentRouter.get('/tickets', manageContent, validate({ query: pageOnlyQuery }), ticketController.listForAdmin);

/**
 * Trả lời yêu cầu đang mở
 *
 * Body:
 *  - content: string (1-4000)
 *  - updatedAt: ISO 8601
 *
 * Trả về: SupportMessage vừa tạo
 */
adminContentRouter.post('/tickets/:id/reply', manageContent, validate({ params: idParams, body: adminTicketReplyBody }), ticketController.adminReply);

/**
 * Đổi trạng thái yêu cầu
 *
 * Body:
 *  - status: 'OPEN' | 'RESOLVED'
 *  - updatedAt: ISO 8601
 *
 * Trả về: { updated: true }
 */
adminContentRouter.post('/tickets/:id/status', manageContent, validate({ params: idParams, body: ticketStatusBody }), ticketController.setStatus);

/* ---------- Tài liệu kiến thức ---------- */

/**
 * Mọi tài liệu, cập nhật gần nhất trước
 *
 * Query params:
 *  - page?: number (mặc định 1)
 */
adminContentRouter.get('/knowledge', manageContent, validate({ query: pageOnlyQuery }), knowledgeController.listForAdmin);

/**
 * Đồng bộ danh mục đang dùng vào tài liệu hệ thống 'system-catalog' và lập chỉ mục
 *
 * Trả về: { categories: number, syncedAt }
 */
adminContentRouter.post('/knowledge/catalog-sync', manageContent, knowledgeController.syncCatalog);

/**
 * Tạo tài liệu (POST) hoặc sửa (PUT /knowledge/:id); cần lập chỉ mục lại sau khi lưu
 *
 * Body:
 *  - title: string (3-160), content: string (10-100000), active: boolean
 *  - updatedAt: ISO 8601 - chỉ khi sửa
 */
adminContentRouter.post('/knowledge', manageContent, validate({ body: knowledgeBody }), knowledgeController.create);
adminContentRouter.put('/knowledge/:id', manageContent, validate({ params: idParams, body: knowledgeBody }), knowledgeController.update);

/**
 * Lập chỉ mục tìm kiếm cho tài liệu
 *
 * Body:
 *  - updatedAt: ISO 8601
 *
 * Trả về: { indexed: true }
 */
adminContentRouter.post('/knowledge/:id/sync', manageContent, validate({ params: idParams, body: versionBody }), knowledgeController.index);

/**
 * Xóa tài liệu và chỉ mục
 *
 * Body:
 *  - updatedAt: ISO 8601
 *
 * Trả về: { deleted: true }
 */
adminContentRouter.delete('/knowledge/:id', manageContent, validate({ params: idParams, body: versionBody }), knowledgeController.remove);

/* ---------- Báo cáo vi phạm ---------- */

/**
 * Báo cáo, mới trước
 *
 * Query params:
 *  - page?: number (mặc định 1)
 *  - status?: 'OPEN' | 'RESOLVED' | 'DISMISSED'
 */
adminContentRouter.get('/reports', manageUsers, validate({ query: adminReportQuery }), reportController.listForAdmin);

/**
 * Xử lý báo cáo đang mở
 *
 * Body:
 *  - action: báo cáo tin 'DISMISS' | 'KEEP' | 'REMOVE'; báo cáo thành viên 'DISMISS' | 'WARN' | 'SUSPEND' | 'BAN'
 *  - reason: string (5-300)
 *  - updatedAt: ISO 8601 - của báo cáo
 *  - targetUpdatedAt?: ISO 8601 - của tin / thành viên, bắt buộc với REMOVE, WARN, SUSPEND, BAN
 *  - days?: number (1-365, mặc định 7) - số ngày tạm khóa
 *
 * Trả về: { updated: true }
 */
adminContentRouter.post('/reports/:id/resolve', manageUsers, validate({ params: idParams, body: resolveReportBody }), reportController.resolve);

/**
 * Đối tượng bị báo cáo: hồ sơ thành viên hoặc tin (kèm owner, category); null nếu đã mất
 */
adminContentRouter.get('/reports/:id/target', manageUsers, validate({ params: idParams }), reportController.getTarget);

export default adminContentRouter;
