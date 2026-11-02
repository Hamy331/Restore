import { z } from 'zod';
import { AppError } from '../../../common/errors/app-error.js';
import { int, oneOf, pageQuery, parse } from '../../../common/validation/schemas.js';
import { listingFilters } from '../listing.filters.js';

export const FEED_FILTERS = ['newest', 'nearby', 'exchange'] as const;
export type FeedFilter = (typeof FEED_FILTERS)[number];

const query = z.record(z.string(), z.unknown());

/**
 * Query của GET /listings.
 * - newest:   mới nhất (tin được đẩy xếp trước). Bỏ qua tọa độ nếu có.
 * - nearby:   bắt buộc latitude + longitude, lọc trong radiusKm (mặc định 5) và xếp gần nhất trước.
 * - exchange: chỉ tin cho phép trao đổi.
 * Các bộ lọc tìm kiếm (q, categoryId, condition, minPrice, maxPrice) dùng được với mọi filter.
 */
export const feedQuery = query.transform((raw) => {
  const filter = parse(oneOf('filter', FEED_FILTERS, 'newest'), raw.filter);
  const pagination = parse(pageQuery({ defaultLimit: 10, maxLimit: 50 }), raw);
  const { nearby, allowExchange, ...search } = listingFilters(raw);

  if (filter === 'nearby' && !nearby) {
    throw new AppError(400, 'LOCATION_REQUIRED', 'Cần latitude và longitude để xem tin gần bạn.', 'location');
  }
  const filters = {
    ...search,
    ...(filter === 'nearby' || (filter !== 'newest' && nearby) ? { nearby } : {}),
    ...(filter === 'exchange' || allowExchange ? { allowExchange: true } : {}),
  };
  return { filter, pagination, filters };
});

/** Query của GET /listings/recommended */
export const recommendedQuery = z.object({ limit: int('limit', { min: 1, max: 20, fallback: 10 }) });

export type FeedQuery = z.output<typeof feedQuery>;
export type RecommendedQuery = z.output<typeof recommendedQuery>;
