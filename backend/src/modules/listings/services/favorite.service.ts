import { AppError } from '../../../common/errors/app-error.js';
import { FavoritesQuery, toListingDto } from '../listing.dto.js';
import * as favoriteRepository from '../repositories/favorite.repository.js';

export async function addFavorite(userId: string, listingId: string) {
  const listing = await favoriteRepository.findVisibleListingId(listingId);
  if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Tin không còn hiển thị.');
  await favoriteRepository.upsertFavorite(userId, listing.id);
  return { listingId: listing.id, isFavorite: true };
}

export async function removeFavorite(userId: string, listingId: string) {
  await favoriteRepository.deleteFavorite(userId, listingId);
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
