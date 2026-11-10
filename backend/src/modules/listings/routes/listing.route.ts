import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { optionalAuth, requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as listingController from '../controllers/listing.controller.js';
import { createListingBody, listingIdParams, mineQuery, statusBody } from '../listing.validator.js';

/** Tin đăng của chủ tin và chi tiết tin công khai, gắn tại /api/v1/listings (mount sau cùng vì có GET /:id) */
const listingRouter = Router();
const manageOwn = requirePermission(PERMISSION.LISTING_MANAGE_OWN);

/**
 * Đăng tin mới, tin vào hàng chờ duyệt (PENDING). Trừ lượt đăng trong ngày theo gói cửa hàng
 *
 * Body: title (5-70), description (10-1500), price (chuỗi số VND), condition, categoryId,
 *       isNegotiable?, allowSale?, allowExchange?, exchangeWish?, sellerType?, location, attributes?,
 *       payWithCredits? (true = đồng ý trả xu khi hết suất miễn phí)
 *
 * Trả về: 201 Listing (đủ địa chỉ)
 * Lỗi: 409 POSTING_LIMIT_REACHED { details: { categoryId, blockedBy, extraCredits, available, ... } },
 *      409 NOT_ENOUGH_CREDITS { details: { required, available, missing } }, 409 DAILY_LISTING_LIMIT
 */
listingRouter.post('/', manageOwn, validate({ body: createListingBody }), listingController.create);

/**
 * Hạn mức đăng tin của tôi (tài khoản Cá nhân: từng chuyên mục + tổng 5 tin; hết suất thì trả xu)
 *
 * Trả về: { accountType: personal | business, tier, displayDays, recentWindowDays, defaultLimit, businessLimit,
 *   total: { used, limit }, daily: { used, limit }, wallet: { available },
 *   categories: [{ categoryId, used, limit, recentUsed, recentLimit, extraCredits, freeAvailable, blockedBy }] }
 */
listingRouter.get('/posting-quota', manageOwn, listingController.postingQuota);

/**
 * Số tin đang bán và đã bán của tôi
 *
 * Trả về: { active, sold }
 */
listingRouter.get('/summary', manageOwn, listingController.summary);

/**
 * Tin của tôi, mới tạo trước (status=DRAFT: vừa sửa trước)
 *
 * Query params:
 *  - page?: number (mặc định 1)
 *  - pageSize?: number (1-100, mặc định 20)
 *  - status?: ListingStatus
 *
 * Trả về: Listing[] + pagination { page, pageSize, totalItems, totalPages }
 */
listingRouter.get('/mine', manageOwn, validate({ query: mineQuery }), listingController.listMine);

/**
 * Một tin của tôi, mọi trạng thái
 *
 * Path params:
 *  - id: string - mã tin
 */
listingRouter.get('/mine/:id', manageOwn, validate({ params: listingIdParams }), listingController.getMine);

/**
 * Sửa tin đang hiển thị, đã ẩn, chờ duyệt hoặc bị từ chối; tin quay lại chờ duyệt
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Body: như khi đăng tin
 */
listingRouter.put('/:id', manageOwn, validate({ params: listingIdParams, body: createListingBody }), listingController.update);

/**
 * Đổi trạng thái tin: AVAILABLE ↔ HIDDEN, hoặc SOLD / EXCHANGED (không mở lại được)
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Body:
 *  - status: 'AVAILABLE' | 'HIDDEN' | 'SOLD' | 'EXCHANGED'
 */
listingRouter.patch('/:id/status', manageOwn, validate({ params: listingIdParams, body: statusBody }), listingController.changeStatus);

/**
 * Chi tiết tin công khai, tăng lượt xem (không tính chủ tin và người kiểm duyệt)
 *
 * Path params:
 *  - id: string - mã tin
 */
listingRouter.get('/:id', optionalAuth, validate({ params: listingIdParams }), listingController.getById);

export default listingRouter;
