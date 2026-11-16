import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { optionalAuth, requirePermission } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import { searchQuery } from '../listings/index.js';
import * as searchController from './search.controller.js';
import { historyIdParams, suggestionsQuery } from './search.validator.js';

/**
 * /api/v1/search: gợi ý cho trang tìm kiếm. Tìm tin dùng GET /listings/search
 * (trang đầu tự lưu từ khoá vào lịch sử khi đã đăng nhập).
 */
const searchRouter = Router();
const signedIn = requirePermission(PERMISSION.PROFILE_READ);

/**
 * Từ khoá "Tìm nhiều" (từ 2 người trở lên tìm trong 7 ngày qua; thiếu thì bù tên chuyên mục). Không cần đăng nhập
 *
 * Trả về: string[] (tối đa 8)
 */
searchRouter.get('/trending', searchController.trending);

/**
 * Gợi ý theo nội dung đang gõ (không phân biệt dấu), từ từ khoá có từ 2 người trở lên tìm và tiêu đề tin
 *
 * Query params:
 *  - q: string (tối đa 100 ký tự)
 *  - limit?: number (1-20, mặc định 8)
 *
 * Trả về: string[]
 */
searchRouter.get('/suggestions', validate({ query: suggestionsQuery }), searchController.suggestions);

/**
 * Lịch sử tìm kiếm của tôi, mới nhất trước (tối đa 10)
 *
 * Trả về: { id, keyword, searchedAt }[]
 */
searchRouter.get('/history', signedIn, searchController.history);

/** Xoá một từ khoá khỏi lịch sử của tôi (không có cũng trả 204) */
searchRouter.delete('/history/:id', signedIn, validate({ params: historyIdParams }), searchController.deleteHistory);

/** Xoá toàn bộ lịch sử tìm kiếm của tôi */
searchRouter.delete('/history', signedIn, searchController.clearHistory);

export default searchRouter;

/** Gắn tại /api/v1/listings, trước listingsRouter (để /search không bị GET /:id bắt) */
export const listingSearchRouter = Router();

/**
 * Tìm tin đang hiển thị theo từ khoá, không phân biệt dấu: tiêu đề phải chứa đủ mọi từ đã gõ.
 * Trang đầu (page=1) có từ khoá và có token thì lưu từ khoá vào lịch sử tìm kiếm.
 *
 * Query params:
 *  - q?: string (tối đa 100 ký tự)
 *  - sort?: 'relevance' | 'newest' | 'price_asc' | 'price_desc' | 'nearest' (mặc định relevance;
 *    nearest cần latitude + longitude). Giá: tin chỉ trao đổi xếp cuối
 *  - deal?: 'buy' | 'exchange' | 'buy,exchange' - khớp một trong các kiểu đã chọn
 *  - condition?: ListingCondition, nhiều giá trị cách nhau dấu phẩy
 *  - categoryId?, minPrice?, maxPrice?; latitude?, longitude?, radiusKm? (1-100, mặc định 5)
 *  - page?: number (mặc định 1), limit?: number (1-50, mặc định 10)
 *
 * Trả về: Listing[] + areaLabel, distanceKm, isFeatured, isFavorite; pagination, meta { hasMore }
 */
listingSearchRouter.get('/search', optionalAuth, validate({ query: searchQuery }), searchController.listings);
