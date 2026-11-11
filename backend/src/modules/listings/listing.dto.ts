import { Prisma } from '@prisma/client';
import type { z } from 'zod';
import { publicLocation } from '../catalog/index.js';
import type {
  adminDecisionBody, autoExtendBody, extendBody, adminListingQuery, createListingBody, decisionBody, draftBody, favoritesQuery, featureBody, feedQuery, mineQuery, recommendedQuery, statusBody,
} from './listing.validator.js';

/* ---------- Vào (suy ra từ schema) ---------- */

export type ListingInput = z.output<typeof createListingBody>;
export type DraftInput = z.output<typeof draftBody>;
export type StatusInput = z.output<typeof statusBody>;
export type FeatureInput = z.output<typeof featureBody>;
export type ExtendInput = z.output<typeof extendBody>;
export type AutoExtendInput = z.output<typeof autoExtendBody>;
export type MineQuery = z.output<typeof mineQuery>;
export type DecisionInput = z.output<typeof decisionBody>;
export type FeedQuery = z.output<typeof feedQuery>;
export type RecommendedQuery = z.output<typeof recommendedQuery>;
export type FavoritesQuery = z.output<typeof favoritesQuery>;
export type ListingIdParams = { id: string };
export type AdminListingQuery = z.output<typeof adminListingQuery>;
export type AdminDecisionInput = z.output<typeof adminDecisionBody>;

/* ---------- Ra ---------- */

/** Các cột của Listing trả về cho app */
export const listingSelect = {
  id: true,
  title: true,
  description: true,
  price: true,
  originalPrice: true,
  isNegotiable: true,
  ownerId: true, categoryId: true, status: true, updatedAt: true,
  allowSale: true, allowExchange: true, exchangeWish: true, sellerType: true, attributes: true, location: true, reviewReason: true,
  condition: true,
  category: { select: { id: true, name: true } },
  images: true,
  createdAt: true,
  viewCount: true,
  publishedAt: true,
  expiresAt: true,
  startsAt: true,
  displayDays: true,
  paidCredits: true,
  paidDays: true,
  autoExtend: true,
  owner: { select: { id: true, fullName: true, ratingAverage: true, ratingCount: true } },
} as const;

export type ListingRecord = Prisma.ListingGetPayload<{ select: typeof listingSelect }>;

/**
 * Listing cho app: { id, ownerId, title, description, price (chuỗi số), isNegotiable, condition, status,
 *   originalPrice (giá trước giảm, null = không giảm), allowSale, allowExchange, exchangeWish, sellerType, attributes, location, images[], reviewReason,
 *   categoryId, category { id, name }, owner { id, fullName, ratingAverage, ratingCount },
 *   viewCount, createdAt, updatedAt, publishedAt, expiresAt, startsAt, displayDays, areaLabel }
 *   (+ paidCredits, paidDays, autoExtend cho chủ tin)
 *
 * Người xem không phải chủ tin chỉ thấy vị trí tới mức phường (không lộ số nhà).
 * areaLabel: "Phường, Tỉnh" để hiện trên thẻ tin.
 */
export function toListingDto(listing: ListingRecord, owner = false) {
  const { paidCredits, paidDays, autoExtend, ...rest } = listing;
  const location = owner ? listing.location : publicLocation(listing.location);
  const address = listing.location as { province?: { name?: string }; ward?: { name?: string } } | null;
  return { ...rest, ...(owner && { paidCredits, paidDays, autoExtend }), price: listing.price.toString(),
    originalPrice: listing.originalPrice?.toString() ?? null, location,
    areaLabel: address ? [address.ward?.name, address.province?.name].filter(Boolean).join(', ') : '' };
}

/** Listing cho chủ tin: đủ địa chỉ */
export const toOwnerListingDto = (listing: ListingRecord) => toListingDto(listing, true);

/** Listing trong danh sách trang chủ: thêm khoảng cách, đẩy tin, đã lưu */
export const toFeedItemDto = (listing: ListingRecord, extra: { distanceKm: number | null; isFeatured: boolean; isFavorite: boolean }) =>
  ({ ...toListingDto(listing), ...extra });

export type ListingDto = ReturnType<typeof toListingDto>;

/** Cột tin trả cho trang quản trị (/admin/listings, đối tượng của báo cáo); trả nguyên bản ghi, không qua DTO */
export const adminListingSelect = {
  id: true, title: true, description: true, price: true, status: true, images: true, reviewReason: true,
  updatedAt: true, categoryId: true, ownerId: true, condition: true,
  owner: { select: { id: true, fullName: true } }, category: { select: { id: true, name: true } },
} as const satisfies Prisma.ListingSelect;
