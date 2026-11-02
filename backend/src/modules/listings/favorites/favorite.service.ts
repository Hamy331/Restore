import { AppError } from '../../../common/errors/app-error.js';
import type { Pagination } from '../../../common/http/pagination.js';
import { output } from '../listing.mapper.js';
import * as favoriteRepository from './favorite.repository.js';

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

export async function listFavorites(userId: string, { page, limit, skip }: Pagination) {
  const [rows, totalItems] = await favoriteRepository.findFavoriteListings(userId, limit, skip);
  return {
    items: rows.map((row) => ({ ...output(row.listing), isFavorite: true })),
    page: { page, limit, totalItems },
  };
}
