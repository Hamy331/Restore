import { FeedQuery, RecommendedQuery, toFeedItemDto } from '../listing.dto.js';
import * as feedRepository from '../repositories/feed.repository.js';

/**
 * Danh sách tin cho trang chủ / gần bạn / trao đổi.
 * Mỗi item = Listing + areaLabel, distanceKm, isFeatured, isFavorite (theo người xem).
 */
export async function listFeed(viewerId: string | undefined, { filters, pagination }: FeedQuery, now = new Date()) {
  const { page, limit, skip } = pagination;
  const { rows, totalItems } = await feedRepository.findRankedPage(filters, now, limit, skip);
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

/** Tin gợi ý: các tin đang được đẩy FEATURED */
export async function listRecommended(viewerId: string | undefined, { limit }: RecommendedQuery, now = new Date()) {
  const listings = await feedRepository.findFeatured(now, limit);
  const favoriteIds = await feedRepository.findFavoriteIds(viewerId, listings.map((listing) => listing.id));
  return listings.map((listing) =>
    toFeedItemDto(listing, { distanceKm: null, isFeatured: true, isFavorite: favoriteIds.has(listing.id) }));
}
