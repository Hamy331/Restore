import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { listingSelect } from '../listings/listing.dto.js';
import { visible } from '../listings/repositories/listing.repository.js';

/** Cột shop trả cho app, kèm điểm đánh giá của chủ shop và số người theo dõi */
export const shopSelect = {
  id: true, ownerId: true, name: true, tagline: true, description: true, logoUrl: true, coverUrl: true,
  accentColor: true, verificationType: true, verifiedAt: true, certificateCode: true, categoryIds: true,
  address: true, createdAt: true,
  owner: { select: { ratingAverage: true, ratingCount: true, status: true } },
  _count: { select: { followers: true } },
} as const satisfies Prisma.ShopSelect;

export type ShopRecord = Prisma.ShopGetPayload<{ select: typeof shopSelect }>;

/** Shop hiện ở "Shop uy tín": đã xác minh và chủ shop còn hoạt động */
export const trusted = { verificationType: { not: null }, owner: { status: 'ACTIVE' } } as const satisfies Prisma.ShopWhereInput;

/** Tin đang bán của các shop uy tín */
export const trustedListing = {
  status: 'AVAILABLE', owner: { status: 'ACTIVE', shop: { is: { verificationType: { not: null } } } },
} as const satisfies Prisma.ListingWhereInput;

export const findTrustedShops = () =>
  prisma.shop.findMany({ where: trusted, select: shopSelect });

export const findShop = (id: string) => prisma.shop.findFirst({ where: { id, ...trusted }, select: shopSelect });

/** Số tin đang bán theo chủ shop */
export async function countListingsByOwner(ownerIds: string[]) {
  if (!ownerIds.length) return new Map<string, number>();
  const rows = await prisma.listing.groupBy({ by: ['ownerId'], where: { ...visible, ownerId: { in: ownerIds } }, _count: true });
  return new Map(rows.map((row) => [row.ownerId, row._count]));
}

export async function findFollowedShopIds(userId: string | undefined, shopIds: string[]) {
  if (!userId || !shopIds.length) return new Set<string>();
  const rows = await prisma.shopFollow.findMany({ where: { userId, shopId: { in: shopIds } }, select: { shopId: true } });
  return new Set(rows.map((row) => row.shopId));
}

/** Banner đã duyệt đang trong thời gian chạy, của shop [shopId] nếu có */
export const findActiveBanners = (now: Date, shopId?: string) =>
  prisma.shopBanner.findMany({
    where: {
      status: 'APPROVED', shop: { ...trusted, ...(shopId ? { id: shopId } : {}) },
      AND: [{ OR: [{ startsAt: null }, { startsAt: { lte: now } }] }, { OR: [{ endsAt: null }, { endsAt: { gt: now } }] }],
    },
    orderBy: [{ createdAt: 'desc' }, { id: 'asc' }],
    take: 10,
  });

const newestFirst = [{ publishedAt: 'desc' }, { id: 'desc' }] satisfies Prisma.ListingOrderByWithRelationInput[];

export const findListings = (where: Prisma.ListingWhereInput, take: number, skip = 0,
  orderBy: Prisma.ListingOrderByWithRelationInput[] = newestFirst) =>
  prisma.listing.findMany({ where, select: listingSelect, take, skip, orderBy });

export const countListings = (where: Prisma.ListingWhereInput) => prisma.listing.count({ where });

/** Tin đang giảm giá (giá gốc > giá bán) của shop uy tín, giảm nhiều trước */
export async function findDealIds(limit: number) {
  const rows = await prisma.$queryRaw<{ id: string }[]>`
    SELECT l.id FROM "Listing" l
    JOIN "User" u ON u.id = l."ownerId" AND u.status = 'ACTIVE'
    JOIN "Shop" s ON s."ownerId" = l."ownerId" AND s."verificationType" IS NOT NULL
    WHERE l.status = 'AVAILABLE' AND l."originalPrice" > l.price
    ORDER BY (l."originalPrice" - l.price) / l."originalPrice" DESC, l.id
    LIMIT ${limit}`;
  return rows.map((row) => row.id);
}

/** Danh mục có ít nhất một tin đang bán của shop uy tín */
export async function findTrustedCategories() {
  const rows = await prisma.listing.groupBy({ by: ['categoryId'], where: trustedListing });
  const ids = rows.map((row) => row.categoryId).filter((id): id is string => Boolean(id));
  return prisma.category.findMany({ where: { id: { in: ids }, active: true }, orderBy: { id: 'asc' } });
}

export const follow = (userId: string, shopId: string) =>
  prisma.shopFollow.upsert({ where: { userId_shopId: { userId, shopId } }, create: { userId, shopId }, update: {} });

export const unfollow = (userId: string, shopId: string) =>
  prisma.shopFollow.deleteMany({ where: { userId, shopId } });
