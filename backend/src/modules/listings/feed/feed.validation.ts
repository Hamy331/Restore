import { AppError } from '../../../common/errors/app-error.js';
import { parsePagination } from '../../../common/http/pagination.js';
import { integerInRange, oneOf } from '../../../common/validation/parsers.js';
import { listingFilters } from '../listing.filters.js';

export const FEED_FILTERS = ['newest', 'nearby', 'exchange'] as const;
export type FeedFilter = (typeof FEED_FILTERS)[number];

/**
 * Query của GET /listings.
 * - newest:   mới nhất (tin được đẩy xếp trước). Bỏ qua tọa độ nếu có.
 * - nearby:   bắt buộc latitude + longitude, lọc trong radiusKm (mặc định 5) và xếp gần nhất trước.
 * - exchange: chỉ tin cho phép trao đổi.
 * Các bộ lọc tìm kiếm (q, categoryId, condition, minPrice, maxPrice) dùng được với mọi filter.
 */
export function parseFeedQuery(query: Record<string, unknown>) {
  const filter = oneOf(query.filter, 'filter', FEED_FILTERS, 'newest');
  const pagination = parsePagination(query, { defaultLimit: 10, maxLimit: 50 });
  const { nearby, allowExchange, ...search } = listingFilters(query);

  if (filter === 'nearby' && !nearby) {
    throw new AppError(400, 'LOCATION_REQUIRED', 'Cần latitude và longitude để xem tin gần bạn.', 'location');
  }
  const filters = {
    ...search,
    ...(filter === 'nearby' || (filter !== 'newest' && nearby) ? { nearby } : {}),
    ...(filter === 'exchange' || allowExchange ? { allowExchange: true } : {}),
  };
  return { filter, pagination, filters };
}

/** Query của GET /listings/recommended */
export function parseRecommendedQuery(query: Record<string, unknown>) {
  return { limit: integerInRange(query.limit, 'limit', { min: 1, max: 20, fallback: 10 }) };
}

export type FeedQuery = ReturnType<typeof parseFeedQuery>;
export type RecommendedQuery = ReturnType<typeof parseRecommendedQuery>;
