import { Router } from 'express';
import { optionalAuth } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as feedController from './feed.controller.js';
import { feedQuery, recommendedQuery } from './feed.validation.js';

/**
 * Danh sách tin công khai, gắn tại /api/v1/listings
 * Header chung: Accept: application/json
 *               Authorization: Bearer <accessToken>  (không bắt buộc; có thì tính isFavorite)
 *
 * Mỗi item trả về là một Listing:
 *   { id, ownerId, title, description, price (chuỗi số), isNegotiable, condition, status,
 *     allowSale, allowExchange, exchangeWish, sellerType, attributes, location, images[],
 *     categoryId, category { id, name }, owner { id, fullName, ratingAverage, ratingCount },
 *     viewCount, createdAt, updatedAt, publishedAt,
 *     areaLabel, distanceKm (number | null), isFeatured, isFavorite }
 */
const router = Router();

/**
 * GET /api/v1/listings
 * Mô tả:    Danh sách "Tin đăng mới" ở trang chủ, có phân trang.
 * Quyền:    Công khai. Có token hợp lệ thì trả thêm isFavorite đúng theo người xem.
 * Query:    filter?       newest (mặc định) | nearby | exchange
 *           page?         số trang, từ 1 (mặc định 1)
 *           limit?        số tin mỗi trang, 1-50 (mặc định 10; nhận cả tên cũ pageSize)
 *           latitude?, longitude?   bắt buộc khi filter=nearby
 *           radiusKm?     1-100, mặc định 5 (chỉ dùng với nearby)
 *           q?, categoryId?, condition?, minPrice?, maxPrice?   bộ lọc tìm kiếm
 * Trả về:   200 { success, data: Listing[],
 *                 pagination: { page, limit, pageSize, totalItems, totalPages, hasMore },
 *                 meta: { page, limit, hasMore } }
 * Lỗi:      400 INVALID_INPUT | INVALID_QUERY | LOCATION_REQUIRED | INVALID_LOCATION,
 *           401 khi gửi token sai/hết hạn
 */
router.get('/', optionalAuth, validate({ query: feedQuery }), feedController.listFeed);

/**
 * GET /api/v1/listings/recommended
 * Mô tả:    Tin gợi ý (đang được đẩy nổi bật) cho mục "Dành cho bạn".
 * Quyền:    Công khai. Có token hợp lệ thì trả thêm isFavorite đúng theo người xem.
 * Query:    limit?   1-20, mặc định 10
 * Trả về:   200 { success, data: Listing[] }   (isFeatured luôn là true)
 * Lỗi:      400 INVALID_INPUT, 401 khi gửi token sai/hết hạn
 */
router.get('/recommended', optionalAuth, validate({ query: recommendedQuery }), feedController.listRecommended);

export default router;
