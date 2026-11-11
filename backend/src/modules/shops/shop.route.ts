import { Router } from 'express';
import { optionalAuth, verifyToken } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
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
