import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { listingSelect } from '../listings/listing.dto.js';
import { visible } from '../listings/repositories/listing.repository.js';

/**
 * Cột shop trả cho app, kèm điểm đánh giá, username và số người theo dõi của chủ shop.
 * Theo dõi shop = theo dõi chủ shop (bảng UserFollow), nên số người theo dõi là của chủ shop.
 */
export const shopSelect = {
  id: true, ownerId: true, name: true, tagline: true, description: true, logoUrl: true, coverUrl: true,
  accentColor: true, verificationType: true, verifiedAt: true, certificateCode: true, categoryIds: true,
  address: true, createdAt: true,
  owner: { select: { ratingAverage: true, ratingCount: true, status: true, username: true, _count: { select: { followers: true } } } },
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

/** Shop có trang công khai: đã duyệt hoặc đã xác minh (shop uy tín), chủ shop còn hoạt động */
export const published = {
  owner: { status: 'ACTIVE' }, OR: [{ status: 'APPROVED' }, { verificationType: { not: null } }],
} as const satisfies Prisma.ShopWhereInput;

export const findShop = (id: string) => prisma.shop.findFirst({ where: { id, ...published }, select: shopSelect });

/** Số tin đang bán theo chủ shop */
export async function countListingsByOwner(ownerIds: string[]) {
  if (!ownerIds.length) return new Map<string, number>();
  const rows = await prisma.listing.groupBy({ by: ['ownerId'], where: { ...visible, ownerId: { in: ownerIds } }, _count: true });
  return new Map(rows.map((row) => [row.ownerId, row._count]));
}

/** Chủ shop (trong [ownerIds]) mà [userId] đang theo dõi */
export async function findFollowedOwnerIds(userId: string | undefined, ownerIds: string[]) {
  if (!userId || !ownerIds.length) return new Set<string>();
  const rows = await prisma.userFollow.findMany({ where: { followerId: userId, followingId: { in: ownerIds } }, select: { followingId: true } });
  return new Set(rows.map((row) => row.followingId));
}

/** Banner (poster) đã duyệt đang trong thời gian chạy của shop uy tín còn gói Cửa hàng, của shop [shopId] nếu có */
export const findActiveBanners = (now: Date, shopId?: string) =>
  prisma.shopBanner.findMany({
    where: {
      status: 'APPROVED',
      shop: {
        verificationType: { not: null }, ...(shopId ? { id: shopId } : {}),
        // gói hết hạn hoặc không còn quyền đăng poster thì poster tạm ẩn
        owner: { status: 'ACTIVE', storeSubscription: { is: { startsAt: { lte: now }, endsAt: { gt: now }, package: { posterActiveLimit: { gt: 0 } } } } },
      },
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

/** Theo dõi shop = theo dõi chủ shop */
export const follow = (userId: string, ownerId: string) =>
  prisma.userFollow.upsert({
    where: { followerId_followingId: { followerId: userId, followingId: ownerId } },
    create: { followerId: userId, followingId: ownerId }, update: {},
  });

export const unfollow = (userId: string, ownerId: string) =>
  prisma.userFollow.deleteMany({ where: { followerId: userId, followingId: ownerId } });
