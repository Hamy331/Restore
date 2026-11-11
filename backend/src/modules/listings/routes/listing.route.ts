import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { optionalAuth, requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as listingController from '../controllers/listing.controller.js';
import { autoExtendBody, createListingBody, extendBody, featureBody, listingIdParams, mineQuery, statusBody } from '../listing.validator.js';

/** Tin đăng của chủ tin và chi tiết tin công khai, gắn tại /api/v1/listings (mount sau cùng vì có GET /:id) */
const listingRouter = Router();
const manageOwn = requirePermission(PERMISSION.LISTING_MANAGE_OWN);

/**
 * Đăng tin mới, tin vào hàng chờ duyệt (PENDING). Trừ lượt đăng trong ngày theo gói cửa hàng
 *
 * Body: title (5-70), description (10-1500), price (chuỗi số VND), condition, categoryId,
 *       isNegotiable?, allowSale?, allowExchange?, exchangeWish?, sellerType?, location, attributes?,
 *       payWithCredits? (true = đồng ý trả xu khi hết suất miễn phí),
 *       allowDuplicate? (true = vẫn đăng mới dù có tin giống vậy đã ẩn / hết hạn),
 *       displayDays?, startsAt?, originalPrice? (giá gốc trước giảm, chỉ gói Cửa hàng, phải cao hơn price;
 *       sửa tin thì không cao hơn giá gốc / giá bán cũ: 400 ORIGINAL_PRICE_RAISED { details: { maxOriginalPrice } })
 *
 * Trả về: 201 Listing (đủ địa chỉ)
 * Lỗi: 409 POSTING_LIMIT_REACHED { details: { categoryId, blockedBy, extraCredits, available, ... } },
 *      409 NOT_ENOUGH_CREDITS { details: { required, available, missing } }, 409 DAILY_LISTING_LIMIT,
 *      409 DUPLICATE_LISTING { details: { listingId } } (trùng tin đang hiển thị / chờ duyệt),
 *      409 DUPLICATE_INACTIVE { details: { listingId, expired } } (trùng tin đã ẩn / hết hạn),
 *      403 ORIGINAL_PRICE_NOT_ALLOWED (gói không phải Cửa hàng mà gửi originalPrice)
 */
listingRouter.post('/', manageOwn, validate({ body: createListingBody }), listingController.create);

/**
 * Hạn mức đăng tin của tôi (tài khoản Cá nhân: từng chuyên mục + tổng 5 tin; hết suất thì trả xu)
 *
 * Trả về: { accountType: personal | business, tier, displayDays, recentWindowDays, defaultLimit, businessLimit,
 *   total: { used, limit }, daily: { used, limit }, wallet: { available },
 *   boost: { freePerMonth, freeLeft, discountPercent },
 *   categories: [{ categoryId, used, limit, recentUsed, recentLimit, extraCredits, extendCredits, displayDays, boostCredits,
 *     freeAvailable, blockedBy }] }
 */
listingRouter.get('/posting-quota', manageOwn, listingController.postingQuota);

/**
 * Số tin đang bán và đã bán của tôi
 *
 * Trả về: { active, sold }
 */
listingRouter.get('/summary', manageOwn, listingController.summary);

/**
 * Trang Boost của tôi: tin đang hiển thị (sắp hết hạn trước, tối đa 100) kèm quảng bá đang chạy
 *
 * Trả về: { available, discountPercent, boost: { freeLeft, freePerMonth }, thisMonth: { boosts, features },
 *   items: [{ id, title, price, image, categoryId, viewCount, expiresAt, autoExtend, boostCredits,
 *     bumpUntil, featuredUntil }] }
 */
listingRouter.get('/promotions', manageOwn, listingController.promotionHub);

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
 * Hiện lại tin đã hết hạn (expiresAt đã qua) = kích hoạt lại: tính như đăng mới, hiển thị thêm một kỳ.
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Body:
 *  - status: 'AVAILABLE' | 'HIDDEN' | 'SOLD' | 'EXCHANGED'
 *  - payWithCredits?: boolean - đồng ý trả xu khi hiện lại / kích hoạt lại mà hết suất miễn phí
 *
 * Lỗi 409: POSTING_LIMIT_REACHED (hết suất, kèm giá xu), NOT_ENOUGH_CREDITS
 */
listingRouter.patch('/:id/status', manageOwn, validate({ params: listingIdParams, body: statusBody }), listingController.changeStatus);

/**
 * Gia hạn tin đang hiển thị (hoặc đang chờ ngày hẹn) thêm số ngày tuỳ chọn, trả xu theo giá ngày của chuyên mục
 * (mua đúng mốc 30 / 60 / 90 ngày rẻ hơn, gói cao được giảm; xem posting-quota.display)
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Body:
 *  - days: number - số ngày thêm, hạn mới không quá Category.maxDisplayDays ngày tính từ hôm nay
 *
 * Lỗi 409: EXTEND_TOO_LONG (details.addableDays), LISTING_NOT_EXTENDABLE, NOT_ENOUGH_CREDITS
 */
listingRouter.post('/:id/extend', manageOwn, validate({ params: listingIdParams, body: extendBody }), listingController.extend);

/**
 * Bật / tắt tự gia hạn 30 ngày khi tin sắp hết hạn (đủ xu thì trừ, thiếu xu thì để tin hết hạn)
 *
 * Body:
 *  - enabled: boolean
 *
 * Lỗi 403: AUTO_EXTEND_NOT_AVAILABLE (gói không có tự gia hạn)
 */
listingRouter.patch('/:id/auto-extend', manageOwn, validate({ params: listingIdParams, body: autoExtendBody }), listingController.autoExtend);

/**
 * Đẩy tin đang hiển thị lên đầu 1 ngày: dùng lượt tặng của gói trong tháng, hết lượt thì trả xu
 * (Category.boostCredits, giảm theo StorePackage.boostDiscountPercent)
 *
 * Path params:
 *  - id: string - mã tin
 *
 * Trả về: { listingId, free, credits, startsAt, endsAt, freeLeft }
 * Lỗi 409: BOOST_TOO_SOON { details: { availableAt } }, LISTING_NOT_BOOSTABLE, NOT_ENOUGH_CREDITS
 */
listingRouter.post('/:id/boost', manageOwn, validate({ params: listingIdParams }), listingController.boost);

/**
 * Trang quảng bá một tin của tôi: giá đẩy tin và các gói Hot sale, lượt đẩy tặng, số xu, hạn đang chạy, lịch sử
 *
 * Trả về: { listingId, title, price, image, status, promotable, available, discountPercent,
 *   boost: { credits, free, freeLeft, freePerMonth, runningUntil },
 *   feature: { runningUntil, options: [{ packageId, durationDays, credits }] },
 *   history: [{ id, kind: BUMP|FEATURED, packageId, durationDays, source, startsAt, endsAt }] }
 * Lỗi 404: LISTING_NOT_FOUND
 */
listingRouter.get('/:id/promotion', manageOwn, validate({ params: listingIdParams }), listingController.promotion);

/**
 * Báo giá tin ưu tiên (Hot sale) cho tin đang hiển thị
 *
 * Trả về: { listingId, discountPercent, available, runningUntil, options: [{ packageId, durationDays, credits }] }
 * Lỗi 409: LISTING_NOT_FEATURABLE
 */
listingRouter.get('/:id/feature', manageOwn, validate({ params: listingIdParams }), listingController.featureQuote);

/**
 * Mua tin ưu tiên bằng xu: đứng đầu danh sách và hiện ở mục Hot sale trong số ngày của gói
 * (giá gói / 1.000 cho nhóm A, nhóm khác theo tỉ lệ Category.boostCredits / 10, giảm theo gói tài khoản)
 *
 * Body: { packageId: string } - gói FEATURED đang bán
 * Trả về: { listingId, packageId, credits, startsAt, endsAt }
 * Lỗi 409: FEATURE_ALREADY_ACTIVE { details: { availableAt } }, LISTING_NOT_FEATURABLE, NOT_ENOUGH_CREDITS
 */
listingRouter.post('/:id/feature', manageOwn, validate({ params: listingIdParams, body: featureBody }),
  listingController.feature);

/**
 * Chi tiết tin công khai, tăng lượt xem (không tính chủ tin và người kiểm duyệt)
 *
 * Path params:
 *  - id: string - mã tin
 */
listingRouter.get('/:id', optionalAuth, validate({ params: listingIdParams }), listingController.getById);

export default listingRouter;
