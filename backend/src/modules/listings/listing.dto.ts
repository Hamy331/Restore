import { Prisma } from '@prisma/client';
import type { z } from 'zod';
import { publicLocation } from '../catalog/index.js';
import { findSubcategory } from '../catalog/category-tree.js';
import type {
  adminDecisionBody, autoExtendBody, extendBody, adminListingQuery, createListingBody, decisionBody, draftBody, favoritesQuery, featureBody, feedQuery, mineQuery, recommendedQuery, searchQuery, statusBody,
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
export type SearchQuery = z.output<typeof searchQuery>;
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
  isNegotiable: true,
  isFree: true,
  multipleUnits: true,
  meetUp: true,
  ownerId: true, categoryId: true, subcategoryId: true, status: true, updatedAt: true,
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
  owner: { select: {
    id: true, fullName: true, avatarUrl: true, ratingAverage: true, ratingCount: true,
    storeSubscription: { select: { startsAt: true, endsAt: true, package: { select: { tier: true } } } },
    shop: { select: { id: true, name: true, logoUrl: true, accentColor: true, status: true, verificationType: true } },
    _count: { select: { listings: { where: { status: 'SOLD' } } } },
  } },
} as const;

export type ListingRecord = Prisma.ListingGetPayload<{ select: typeof listingSelect }>;

/** Nội dung bản sửa của tin đã duyệt (ListingRevision), chỉ chủ tin và người duyệt thấy */
export const revisionSelect = {
  status: true, title: true, description: true, price: true, isNegotiable: true,
  isFree: true, multipleUnits: true, meetUp: true, condition: true,
  allowSale: true, allowExchange: true, exchangeWish: true, attributes: true, location: true, images: true,
  reviewReason: true, submittedAt: true, updatedAt: true,
} as const satisfies Prisma.ListingRevisionSelect;

export type RevisionRecord = Prisma.ListingRevisionGetPayload<{ select: typeof revisionSelect }>;

/** Cột tin cho chủ tin: thêm bản sửa đang chờ / bị từ chối */
export const ownerListingSelect = { ...listingSelect, revision: { select: revisionSelect } } as const;

export type OwnerListingRecord = Prisma.ListingGetPayload<{ select: typeof ownerListingSelect }>;

/** Bản sửa cho app: giá dạng chuỗi số như tin */
export const toRevisionDto = (revision: RevisionRecord) => ({
  ...revision, price: revision.price.toString(),
});

/**
 * Listing cho app: { id, ownerId, title, description, price (chuỗi số), isNegotiable (false = giá cố định),
 *   isFree (cho tặng), multipleUnits (có nhiều món giống nhau), meetUp (gặp mặt giao dịch), condition, status,
 *   allowSale, allowExchange, exchangeWish, sellerType, attributes, location, images[], reviewReason,
 *   categoryId, subcategoryId, category { id, name }, owner { id, fullName, ratingAverage, ratingCount },
 *   isPartner (cửa hàng đã duyệt / đã xác minh, gói nào cũng được), shopId (chỉ có khi isPartner: trang shop của người bán),
 *   viewCount, createdAt, updatedAt, publishedAt, expiresAt, startsAt, displayDays, areaLabel }
 *   (+ paidCredits, paidDays, autoExtend cho chủ tin)
 *
 * Người xem không phải chủ tin chỉ thấy vị trí tới mức phường (không lộ số nhà).
 * areaLabel: "Phường, Tỉnh" để hiện trên thẻ tin.
 */
export function toListingDto(listing: ListingRecord, owner = false) {
  const { paidCredits, paidDays, autoExtend, owner: { storeSubscription: _plan, shop, _count, ...publicOwner }, ...rest } = listing;
  // Đối tác: đã lên cửa hàng và shop đã duyệt / đã xác minh (không phụ thuộc gói tài khoản), giống điều kiện trang shop
  const isPartner = !!shop && (shop.status === 'APPROVED' || shop.verificationType !== null);
  const location = owner ? listing.location : publicLocation(listing.location);
  const address = listing.location as { province?: { name?: string }; ward?: { name?: string } } | null;
  const shopSummary = isPartner ? {
    id: shop!.id, ownerId: publicOwner.id, name: shop!.name, logoUrl: shop!.logoUrl,
    accentColor: shop!.accentColor, verificationType: shop!.verificationType,
    ratingAverage: publicOwner.ratingAverage, ratingCount: publicOwner.ratingCount,
    soldCount: _count?.listings ?? 0,
  } : null;
  return { ...rest, owner: { ...publicOwner, soldCount: _count.listings }, isPartner, ...(isPartner && { shopId: shop!.id }), shopSummary, ...(owner && { paidCredits, paidDays, autoExtend }), price: listing.price.toString(),
    location,
    areaLabel: address ? [address.ward?.name, address.province?.name].filter(Boolean).join(', ') : '' };
}

/**
 * Listing cho chủ tin: đủ địa chỉ. Tin đã duyệt có bản sửa thì thêm pendingEdit
 * { status: PENDING | REJECTED, reviewReason, submittedAt, updatedAt, title, description, price,
 *   isNegotiable, isFree, multipleUnits, meetUp, condition, allowSale, allowExchange, exchangeWish, attributes, location, images[] }
 * (không có bản sửa thì không có trường này).
 */
export const toOwnerListingDto = (listing: ListingRecord & { revision?: RevisionRecord | null }) => {
  const { revision, ...rest } = listing;
  return { ...toListingDto(rest, true), ...(revision && { pendingEdit: toRevisionDto(revision) }) };
};

/** Listing trong danh sách trang chủ: thêm khoảng cách, đẩy tin, đã lưu */
export const toFeedItemDto = (listing: ListingRecord, extra: { distanceKm: number | null; isFeatured: boolean; isFavorite: boolean }) =>
  ({ ...toListingDto(listing), ...extra });

export type ListingDto = ReturnType<typeof toListingDto>;

/** Cột tin trả cho trang quản trị (/admin/listings, đối tượng của báo cáo); trả nguyên bản ghi, không qua DTO */
export const adminListingSelect = {
  id: true, title: true, description: true, price: true, status: true, images: true, reviewReason: true,
  updatedAt: true, categoryId: true, subcategoryId: true, ownerId: true, condition: true, flagged: true,
  owner: {
    select: {
      id: true, fullName: true, email: true,
      storeSubscription: { select: { startsAt: true, endsAt: true, package: { select: { tier: true } } } },
      shop: { select: { name: true, status: true, verificationType: true } },
    },
  },
  category: { select: { id: true, name: true, metadata: true } },
} as const satisfies Prisma.ListingSelect;

type AdminOwnerRecord = Prisma.UserGetPayload<{ select: typeof adminListingSelect.owner.select }>;

/** Người đăng cho trang quản trị: gói đang dùng (hết hạn hoặc chưa bắt đầu tính là Cá nhân) và shop nếu có */
function toAdminOwner({ storeSubscription: plan, shop, ...owner }: AdminOwnerRecord, now: Date) {
  const active = plan && plan.startsAt <= now && plan.endsAt > now;
  return {
    ...owner, planTier: active ? plan.package.tier : 'PERSONAL',
    shop: shop && { name: shop.name, status: shop.status, verified: shop.verificationType !== null },
  };
}

/** Tin cho trang quản trị: tên danh mục kèm danh mục con ("Điện tử › Điện thoại"), không trả metadata danh mục */
export function toAdminListing<T extends { subcategoryId: string | null; category: { id: string; name: string; metadata: Prisma.JsonValue } | null;
  owner?: AdminOwnerRecord }>({ category, owner, ...item }: T, now = new Date()) {
  const name = findSubcategory(category?.metadata, item.subcategoryId)?.name as string | { vi?: string } | undefined;
  const sub = typeof name === 'string' ? name : name?.vi;
  return {
    ...item, ...(owner && { owner: toAdminOwner(owner, now) }),
    category: category && { id: category.id, name: sub ? `${category.name} › ${sub}` : category.name },
  };
}
