import { AppError } from '../../../common/errors/app-error.js';
import { FavoritesQuery, toListingDto } from '../listing.dto.js';
import * as favoriteRepository from '../repositories/favorite.repository.js';
import { findFavoriteIds } from '../repositories/feed.repository.js';
import { emit } from '../../../common/events/domain-events.js';

export async function addFavorite(userId: string, listingId: string) {
  const listing = await favoriteRepository.findVisibleListingId(listingId);
  if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Tin không còn hiển thị.');
  await favoriteRepository.upsertFavorite(userId, listing.id);
  await emit('listing.favorited', { userId, listingId: listing.id });
  return { listingId: listing.id, isFavorite: true };
}

export async function removeFavorite(userId: string, listingId: string) {
  await favoriteRepository.deleteFavorite(userId, listingId);
}

/** Số tin giữ trong Xem gần đây của mỗi người */
export const MAX_RECENT_VIEWS = 30;

/** Ghi tin [listingId] vào Xem gần đây; lỗi chỉ ghi log để không làm hỏng trang chi tiết */
export const recordRecentView = (userId: string, listingId: string) =>
  favoriteRepository.recordRecentView(userId, listingId, MAX_RECENT_VIEWS).catch((error: unknown) => {
    console.error('recordRecentView failed', error);
  });

/** Xem gần đây: tin còn hiển thị, mới xem trước, kèm isFavorite */
export async function listRecentViews(userId: string, { page, limit, skip }: FavoritesQuery) {
  const [rows, totalItems] = await favoriteRepository.findRecentViewListings(userId, limit, skip);
  const favorites = await findFavoriteIds(userId, rows.map((row) => row.listing.id));
  return {
    items: rows.map((row) => ({ ...toListingDto(row.listing), isFavorite: favorites.has(row.listing.id) })),
    page: { page, limit, totalItems },
  };
}

export const isFavorite = (userId: string, listingId: string) =>
  favoriteRepository.existsFavorite(userId, listingId);

export async function listFavorites(userId: string, { page, limit, skip }: FavoritesQuery) {
  const [rows, totalItems] = await favoriteRepository.findFavoriteListings(userId, limit, skip);
  return {
    items: rows.map((row) => ({ ...toListingDto(row.listing), isFavorite: true })),
    page: { page, limit, totalItems },
  };
}
