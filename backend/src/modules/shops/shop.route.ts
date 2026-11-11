import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { optionalAuth, requirePermission, verifyToken } from '../../middlewares/auth.middleware.js';
import { requireJson } from '../../middlewares/require-json.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import * as myShopController from './my-shop.controller.js';
import { shopCreateBody, shopUpdateBody } from './my-shop.validator.js';
import { posterRouter } from './poster.route.js';
import * as shopController from './shop.controller.js';
import { shopIdParams, shopListingsQuery } from './shop.validator.js';

/**
 * /api/v1/shops: trang "Shop uy tín" và trang của từng shop. Xem công khai; có token thì tính
 * isFollowing (shop) và isFavorite (tin). Chỉ shop đã xác minh (verificationType khác null) mới hiện.
 * Lưới "Tất cả sản phẩm" dùng GET /listings?verifiedShop=true&onSale=true.
 */
const shopRouter = Router();

/**
 * Trả về: { stats { shopCount, listingCount }, categories, banners: [ShopBanner + shop], famousShops, newShops,
 *   deals: [Listing], newReleases: [Listing + shop], showcases: [{ shop, listings }] }
 */
shopRouter.get('/trusted/overview', optionalAuth, shopController.overview);

const manageOwn = requirePermission(PERMISSION.LISTING_MANAGE_OWN);

/**
 * Trang Quản lý shop của chính mình. Trả về: { shop | null, storePlan, planEndsAt, canCreate, nameLocked,
 *   stats { followerCount, listingCount, runningPosters, pendingPosters } | null }
 */
shopRouter.get('/me', manageOwn, myShopController.get);

/** Mở shop (gói Cửa hàng). Body: name, tagline?, description?, address?. Lỗi 403 SHOP_PLAN_REQUIRED, 409 SHOP_EXISTS */
shopRouter.post('/me', manageOwn, requireJson, validate({ body: shopCreateBody }), myShopController.create);

/**
 * Sửa shop. Body (đều không bắt buộc, null = xoá): name, tagline, description, address, logoUrl, coverUrl
 * (ảnh tải lên qua /media/images?purpose=shop), accentColor (#RRGGBB).
 * Lỗi 404 SHOP_REQUIRED, 409 SHOP_NAME_LOCKED (shop đã xác minh), 400 INVALID_IMAGE_URL
 */
shopRouter.patch('/me', manageOwn, requireJson, validate({ body: shopUpdateBody }), myShopController.update);

/** Poster của shop mình (gói Cửa hàng), xem poster.route.ts */
shopRouter.use('/me/posters', posterRouter);

/** Trả về: Shop + isFollowing. Lỗi 404 SHOP_NOT_FOUND */
shopRouter.get('/:id', optionalAuth, validate({ params: shopIdParams }), shopController.getShop);

/** Banner đã duyệt đang chạy của shop: [ShopBanner + shop] */
shopRouter.get('/:id/banners', optionalAuth, validate({ params: shopIdParams }), shopController.getBanners);

/**
 * Tin đang bán của shop
 *
 * Query: categoryId?, minPrice?, maxPrice?, condition? (vd NEW,LIKE_NEW), sort? (newest | price_asc | price_desc),
 *   page?, limit? (1-50, mặc định 10)
 */
shopRouter.get('/:id/listings', optionalAuth, validate({ params: shopIdParams, query: shopListingsQuery }),
  shopController.listListings);

/** Theo dõi / bỏ theo dõi shop (cần đăng nhập). Trả 204. Lỗi 409 CANNOT_FOLLOW_OWN_SHOP */
shopRouter.post('/:id/follow', verifyToken, validate({ params: shopIdParams }), shopController.follow);
shopRouter.delete('/:id/follow', verifyToken, validate({ params: shopIdParams }), shopController.unfollow);

export default shopRouter;
