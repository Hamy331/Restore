import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { authorizePermission, requirePermission } from '../../middlewares/auth.middleware.js';
import { requireJson } from '../../middlewares/require-json.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import * as posterController from './poster.controller.js';
import { adminPosterQuery, posterCreateBody, posterRejectBody, posterUpdateBody } from './poster.validator.js';
import { shopIdParams } from './shop.validator.js';

/**
 * Poster shop của chủ shop, gắn tại /api/v1/shops/me/posters.
 * Gói Cửa hàng: StorePackage.posterActiveLimit poster chạy hoặc chờ duyệt cùng lúc (khung giờ chồng nhau),
 * posterMonthlyLimit poster gửi mỗi tháng; mỗi poster 3-14 ngày, hẹn trước tối đa 14 ngày.
 * Bị từ chối 3 lần trong 30 ngày thì khóa gửi 7 ngày. Chỉ poster đã duyệt, trong khung giờ, của shop đã xác minh
 * và gói còn hạn mới hiện ở trang shop và Shop uy tín.
 */
export const posterRouter = Router();
const manageOwn = requirePermission(PERMISSION.LISTING_MANAGE_OWN);

/** Trả về: { shop, plan { tier, endsAt }, limits { activeLimit, monthlyLimit, usedThisMonth, slotsInUse, minDays, maxDays,
 *  maxLeadDays, cooldownUntil }, posters: [Poster] } */
posterRouter.get('/', manageOwn, posterController.mine);

/**
 * Gửi poster, trạng thái chờ duyệt. Trả 201 Poster
 *
 * Body: title (1-80), imageUrl (từ POST /media/images?purpose=poster), listingId? (tin đang bán của mình),
 *   startsAt? (ISO, mặc định bây giờ), days (3-14)
 *
 * Lỗi: 409 SHOP_REQUIRED | POSTER_COOLDOWN {until} | POSTER_MONTHLY_LIMIT | POSTER_SLOT_FULL, 403 POSTER_PLAN_REQUIRED,
 *   400 POSTER_START_TOO_LATE | INVALID_IMAGE_URL | POSTER_LISTING_INVALID
 */
posterRouter.post('/', manageOwn, requireJson, validate({ body: posterCreateBody }), posterController.create);

/** Sửa poster (mọi trường không bắt buộc, listingId null = mở trang shop, startsAt null = chạy ngay khi duyệt);
 *  poster quay về chờ duyệt.
 *  Lỗi thêm: 404 POSTER_NOT_FOUND, 409 POSTER_NOT_EDITABLE */
posterRouter.patch('/:id', manageOwn, requireJson, validate({ params: shopIdParams, body: posterUpdateBody }), posterController.update);

/** Dừng poster đang chạy / đã lên lịch hoặc hủy poster chờ duyệt. Lỗi 409 POSTER_NOT_STOPPABLE */
posterRouter.post('/:id/stop', manageOwn, validate({ params: shopIdParams }), posterController.stop);

/** Duyệt poster shop, gắn tại /api/v1/admin (adminRouter đã xác thực token) */
export const posterAdminRouter = Router();
const manageBanners = authorizePermission(PERMISSION.BANNER_MANAGE);

/** Query: status? = PENDING (mặc định, cũ nhất trước) | APPROVED | REJECTED | STOPPED | ALL.
 *  Trả về: { pendingCount, items: [Poster + shop { id, name, logoUrl, verified, ownerEmail, planTier, planEndsAt }] } */
posterAdminRouter.get('/shop-posters', manageBanners, validate({ query: adminPosterQuery }), posterController.adminList);

/** Duyệt; ghi AdminAudit. Lỗi 409 POSTER_NOT_PENDING | POSTER_EXPIRED */
posterAdminRouter.post('/shop-posters/:id/approve', manageBanners, validate({ params: shopIdParams }), posterController.approve);

/** Từ chối. Body: reason (WRONG_SIZE | MISLEADING_PRICE | BRAND_MISUSE | PROHIBITED | TOO_MUCH_TEXT | OTHER), note? (bắt buộc khi OTHER) */
posterAdminRouter.post('/shop-posters/:id/reject', manageBanners, requireJson,
  validate({ params: shopIdParams, body: posterRejectBody }), posterController.reject);
