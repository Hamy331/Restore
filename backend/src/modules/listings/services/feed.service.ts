import { FeedQuery, RecommendedQuery, SearchQuery, toFeedItemDto } from '../listing.dto.js';
import type { SearchSort } from '../listing.validator.js';
import * as feedRepository from '../repositories/feed.repository.js';

/**
 * Danh sách tin cho trang chủ / gần bạn / trao đổi.
 * Mỗi item = Listing + areaLabel, distanceKm, isFeatured, isFavorite (theo người xem).
 */
export const listFeed = (viewerId: string | undefined, { filter, filters, pagination, sort }: FeedQuery, now = new Date()) =>
  rankedPage(viewerId, {
    ...filters, chronological: filter === 'recent', interestUserId: filter === 'forYou' ? viewerId : undefined,
    ...(filter === 'certified' && { verifiedShop: true }),
    ...(filter === 'free' && { freeOnly: true }),
    // Chưa đăng nhập thì không theo dõi ai: danh sách rỗng
    ...(filter === 'following' && { followerId: viewerId ?? '' }),
  }, pagination, now, sort);

/** Kết quả tìm kiếm: như feed nhưng xếp theo [sort] (mặc định phù hợp nhất) */
export const searchListings = (viewerId: string | undefined, { filters, pagination, sort }: SearchQuery, now = new Date()) =>
  rankedPage(viewerId, filters, pagination, now, sort);

async function rankedPage(viewerId: string | undefined, filters: Parameters<typeof feedRepository.findRankedPage>[0],
  pagination: FeedQuery['pagination'], now: Date, sort?: SearchSort) {
  const { page, limit, skip } = pagination;
  const { rows, totalItems } = await feedRepository.findRankedPage(filters, now, limit, skip, sort);
  const ids = rows.map((row) => row.id);
  const [listings, favoriteIds] = await Promise.all([
    feedRepository.findVisibleByIds(ids),
    feedRepository.findFavoriteIds(viewerId, ids),
  ]);
  const byId = new Map(listings.map((listing) => [listing.id, listing]));

  // Giữ đúng thứ tự xếp hạng của câu SQL
  const items = rows.flatMap((row) => {
    const listing = byId.get(row.id);
    if (!listing) return [];
    return [toFeedItemDto(listing, { distanceKm: row.distanceKm, isFeatured: row.isFeatured, isFavorite: favoriteIds.has(row.id) })];
  });
  return { items, page: { page, limit, totalItems } };
}

/** Tin Hot sale: các tin đang có tin ưu tiên (FEATURED), lọc theo chuyên mục nếu có */
export async function listRecommended(viewerId: string | undefined, { limit, page, categoryId }: RecommendedQuery,
  now = new Date()) {
  const listings = await feedRepository.findFeatured(now, limit, categoryId, (page - 1) * limit);
  const favoriteIds = await feedRepository.findFavoriteIds(viewerId, listings.map((listing) => listing.id));
  return listings.map((listing) =>
    toFeedItemDto(listing, { distanceKm: null, isFeatured: true, isFavorite: favoriteIds.has(listing.id) }));
}
