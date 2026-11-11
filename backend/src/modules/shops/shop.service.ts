import type { Prisma } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import { toCategoryDto } from '../catalog/catalog.dto.js';
import { toFeedItemDto, type ListingRecord } from '../listings/listing.dto.js';
import { findFavoriteIds } from '../listings/repositories/feed.repository.js';
import { visible } from '../listings/repositories/listing.repository.js';
import { toBannerDto, toShopDto, type ShopDto } from './shop.dto.js';
import * as shopRepository from './shop.repository.js';
import type { ShopRecord } from './shop.repository.js';
import type { ShopListingsQuery } from './shop.validator.js';

/** Shop mới: xác minh trong 180 ngày gần đây */
const NEW_SHOP_DAYS = 180;
const DAY = 86_400_000;
const SHOWCASE_SIZE = 6;

/** Gắn số tin đang bán và trạng thái theo dõi của người xem cho các shop */
async function shopDtos(viewerId: string | undefined, shops: ShopRecord[]) {
  const [counts, followed] = await Promise.all([
    shopRepository.countListingsByOwner(shops.map((shop) => shop.ownerId)),
    shopRepository.findFollowedShopIds(viewerId, shops.map((shop) => shop.id)),
  ]);
  return shops.map((shop) => toShopDto(shop, { listingCount: counts.get(shop.ownerId) ?? 0, isFollowing: followed.has(shop.id) }));
}

/** Thẻ tin (như trang chủ) cho danh sách tin, tính isFavorite theo người xem */
async function cards(viewerId: string | undefined, listings: ListingRecord[]) {
  const favorites = await findFavoriteIds(viewerId, listings.map((listing) => listing.id));
  return listings.map((listing) => toFeedItemDto(listing, { distanceKm: null, isFeatured: false, isFavorite: favorites.has(listing.id) }));
}

const byFollowers = (a: ShopDto, b: ShopDto) => b.followerCount - a.followerCount || a.name.localeCompare(b.name);

/**
 * Mọi khu của trang Shop uy tín trừ lưới "Tất cả sản phẩm":
 * stats, categories, banners, famousShops (shop chính hãng nhiều người theo dõi), newShops (xác minh trong 180 ngày),
 * deals (đang giảm giá), newReleases (tin mới của shop chính hãng, kèm shop), showcases (mỗi shop vài tin).
 */
export async function overview(viewerId: string | undefined, now = new Date()) {
  const shops = await shopDtos(viewerId, await shopRepository.findTrustedShops());
  const byOwner = new Map(shops.map((shop) => [shop.ownerId, shop]));
  const byId = new Map(shops.map((shop) => [shop.id, shop]));
  const official = shops.filter((shop) => shop.verificationType === 'OFFICIAL_BRAND').sort(byFollowers);

  const [listingCount, categories, banners, dealIds, releases] = await Promise.all([
    shopRepository.countListings(shopRepository.trustedListing),
    shopRepository.findTrustedCategories(),
    shopRepository.findActiveBanners(now),
    shopRepository.findDealIds(10),
    shopRepository.findListings({ ...visible, ownerId: { in: official.map((shop) => shop.ownerId) } }, 8),
  ]);
  const dealRecords = await shopRepository.findListings({ id: { in: dealIds } }, dealIds.length);
  const dealOrder = new Map(dealIds.map((id, index) => [id, index]));
  dealRecords.sort((a, b) => (dealOrder.get(a.id) ?? 0) - (dealOrder.get(b.id) ?? 0));

  const showcaseShops = [...shops].sort(byFollowers).filter((shop) => shop.listingCount > 0).slice(0, 12);
  const showcases = await Promise.all(showcaseShops.map(async (shop) => ({
    shop,
    listings: await cards(viewerId, await shopRepository.findListings({ ...visible, ownerId: shop.ownerId }, SHOWCASE_SIZE)),
  })));
  const releaseCards = await cards(viewerId, releases);

  return {
    stats: { shopCount: shops.length, listingCount },
    categories: categories.map(toCategoryDto),
    banners: banners.flatMap((banner) => {
      const shop = byId.get(banner.shopId);
      return shop ? [toBannerDto(banner, shop)] : [];
    }),
    famousShops: official.slice(0, 10),
    newShops: shops
      .filter((shop) => shop.verifiedAt && now.getTime() - shop.verifiedAt.getTime() <= NEW_SHOP_DAYS * DAY)
      .sort((a, b) => b.verifiedAt!.getTime() - a.verifiedAt!.getTime())
      .slice(0, 10),
    deals: await cards(viewerId, dealRecords),
    newReleases: releaseCards.map((card) => ({ ...card, shop: byOwner.get(card.ownerId) })),
    showcases,
  };
}

async function requireShop(viewerId: string | undefined, id: string) {
  const shop = await shopRepository.findShop(id);
  if (!shop) throw new AppError(404, 'SHOP_NOT_FOUND', 'Không tìm thấy shop.');
  const [dto] = await shopDtos(viewerId, [shop]);
  return dto;
}

export const getShop = (viewerId: string | undefined, id: string) => requireShop(viewerId, id);

export async function getBanners(viewerId: string | undefined, id: string, now = new Date()) {
  const shop = await requireShop(viewerId, id);
  return (await shopRepository.findActiveBanners(now, id)).map((banner) => toBannerDto(banner, shop));
}

/** Tin đang bán của shop theo bộ lọc, có phân trang */
export async function listShopListings(viewerId: string | undefined, id: string, query: ShopListingsQuery) {
  const shop = await requireShop(viewerId, id);
  const { page, limit, skip } = query.pagination;
  const price: Prisma.DecimalFilter = {
    ...(query.minPrice !== undefined ? { gte: query.minPrice } : {}),
    ...(query.maxPrice !== undefined ? { lte: query.maxPrice } : {}),
  };
  const where: Prisma.ListingWhereInput = {
    ...visible, ownerId: shop.ownerId,
    ...(query.categoryId ? { categoryId: query.categoryId } : {}),
    ...(query.conditions.length ? { condition: { in: query.conditions } } : {}),
    ...(Object.keys(price).length ? { price } : {}),
  };
  const orderBy: Prisma.ListingOrderByWithRelationInput[] = query.sort === 'price_asc' ? [{ price: 'asc' }, { id: 'asc' }]
    : query.sort === 'price_desc' ? [{ price: 'desc' }, { id: 'asc' }]
    : [{ publishedAt: 'desc' }, { id: 'desc' }];
  const [listings, totalItems] = await Promise.all([
    shopRepository.findListings(where, limit, skip, orderBy),
    shopRepository.countListings(where),
  ]);
  return { items: await cards(viewerId, listings), page: { page, limit, totalItems } };
}

export async function setFollowing(userId: string, id: string, following: boolean) {
  const shop = await requireShop(userId, id);
  if (shop.ownerId === userId) throw new AppError(409, 'CANNOT_FOLLOW_OWN_SHOP', 'Không thể theo dõi shop của chính mình.');
  if (following) await shopRepository.follow(userId, id);
  else await shopRepository.unfollow(userId, id);
}
