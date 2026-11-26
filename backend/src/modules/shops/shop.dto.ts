import type { ShopBanner } from '@prisma/client';
import type { ShopRecord } from './shop.repository.js';

/**
 * Shop cho app (khớp ShopModel): { id, ownerId, name, tagline, description, logoUrl, coverUrl, accentColor,
 *   verificationType (OFFICIAL_BRAND | CERTIFIED), verifiedAt, certificateCode, categoryIds, address,
 *   openingHours ([{ day 1-7 (1 = thứ Hai), open, close "HH:MM" }] | null), contactPhone, businessEmail, website,
 *   ratingAverage, ratingCount, ownerUsername, followerCount (của chủ shop), listingCount (tin đang bán), createdAt,
 *   isFollowing (đang theo dõi chủ shop) }
 */
export function toShopDto(shop: ShopRecord, extra: { listingCount: number; isFollowing: boolean }) {
  const { owner, ...rest } = shop;
  return {
    ...rest, ratingAverage: owner.ratingAverage, ratingCount: owner.ratingCount, ownerUsername: owner.username,
    followerCount: owner._count.followers, ...extra,
  };
}

export type ShopDto = ReturnType<typeof toShopDto>;

/** Banner shop kèm khóa `shop` (ShopBannerItem của app); listingId = bấm vào mở tin đó, null = mở trang shop */
export const toBannerDto = (banner: ShopBanner, shop: ShopDto) => ({
  id: banner.id, shopId: banner.shopId, title: banner.title, imageUrl: banner.imageUrl, status: banner.status,
  startsAt: banner.startsAt, endsAt: banner.endsAt, listingId: banner.listingId, createdAt: banner.createdAt, shop,
});
