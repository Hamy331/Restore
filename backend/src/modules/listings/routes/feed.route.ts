import { Router } from 'express';
import { optionalAuth } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as feedController from '../controllers/feed.controller.js';
import { feedQuery, recommendedQuery } from '../listing.validator.js';

/** Danh sách tin công khai cho trang chủ, gắn tại /api/v1/listings. Có token thì tính isFavorite */
const feedRouter = Router();

/**
 * Tin mới nhất / gần bạn / trao đổi, có phân trang
 *
 * Query params:
 *  - filter?: 'newest' | 'nearby' | 'exchange' (mặc định newest)
 *  - page?: number (mặc định 1)
 *  - limit?: number (1-50, mặc định 10; nhận cả tên cũ pageSize)
 *  - latitude?, longitude?: number - bắt buộc khi filter = nearby
 *  - radiusKm?: number (1-100, mặc định 5) - chỉ dùng với nearby
 *  - q?, categoryId?, condition?, minPrice?, maxPrice? - bộ lọc tìm kiếm
 *
 * Trả về: Listing[] + areaLabel, distanceKm, isFeatured, isFavorite; pagination, meta
 */
feedRouter.get('/', optionalAuth, validate({ query: feedQuery }), feedController.listFeed);

/**
 * Tin Hot sale (đang có tin ưu tiên FEATURED) cho trang chủ và đầu trang chuyên mục
 *
 * Query params:
 *  - limit?: number (1-20, mặc định 10)
 *  - page?: number (từ 1, mặc định 1) - trang Hot sale tải thêm
 *  - categoryId?: string - chỉ lấy tin của chuyên mục này
 */
feedRouter.get('/recommended', optionalAuth, validate({ query: recommendedQuery }), feedController.listRecommended);

export default feedRouter;
