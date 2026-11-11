import type { Prisma, ShopBannerStatus } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';

type Db = Prisma.TransactionClient;

export const posterSelect = {
  id: true, shopId: true, title: true, imageUrl: true, status: true, startsAt: true, endsAt: true,
  listingId: true, rejectReason: true, rejectNote: true, reviewedAt: true, createdAt: true, updatedAt: true,
  listing: { select: { id: true, title: true, images: true, status: true } },
} as const satisfies Prisma.ShopBannerSelect;

export type PosterRecord = Prisma.ShopBannerGetPayload<{ select: typeof posterSelect }>;

export const findOwnShop = (db: Db, ownerId: string) =>
  db.shop.findUnique({ where: { ownerId }, select: { id: true, name: true, logoUrl: true, verificationType: true } });

/** Khóa theo shop trong transaction để hai lần gửi cùng lúc không vượt hạn mức */
export const lockShop = (db: Db, shopId: string) =>
  db.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${`shop-poster:${shopId}`}))`;

export const findPosters = (db: Db, shopId: string, take = 50) =>
  db.shopBanner.findMany({ where: { shopId }, select: posterSelect, orderBy: [{ createdAt: 'desc' }, { id: 'asc' }], take });

export const findPoster = (db: Db, shopId: string, id: string) =>
  db.shopBanner.findFirst({ where: { id, shopId }, select: posterSelect });

/** Poster đã gửi trong tháng (tính theo ngày tạo, gồm cả bị từ chối hay đã dừng) */
export const countCreatedSince = (db: Db, shopId: string, since: Date) =>
  db.shopBanner.count({ where: { shopId, createdAt: { gte: since } } });

/** Poster chờ duyệt hoặc đã duyệt có khung giờ chồng lên [from, to) */
export const countOverlapping = (db: Db, shopId: string, from: Date, to: Date, exceptId?: string) =>
  db.shopBanner.count({
    where: {
      shopId, status: { in: ['PENDING', 'APPROVED'] }, endsAt: { gt: from }, startsAt: { lt: to },
      ...(exceptId ? { id: { not: exceptId } } : {}),
    },
  });

/** Poster đang giữ suất: chờ duyệt hoặc đã duyệt và chưa kết thúc */
export const countHoldingSlots = (db: Db, shopId: string, now: Date) =>
  db.shopBanner.count({ where: { shopId, status: { in: ['PENDING', 'APPROVED'] }, endsAt: { gt: now } } });

/** Thời điểm admin từ chối poster của shop từ [since], mới nhất trước (lấy từ nhật ký admin nên sửa poster không xóa được) */
export async function findRejectionTimes(db: Db, shopId: string, since: Date) {
  const rows = await db.$queryRaw<{ createdAt: Date }[]>`
    SELECT a."createdAt" FROM "AdminAudit" a
    JOIN "ShopBanner" b ON b.id = a."targetId"
    WHERE a.action = 'SHOP_POSTER_REJECT' AND b."shopId" = ${shopId} AND a."createdAt" >= ${since}
    ORDER BY a."createdAt" DESC`;
  return rows.map((row) => row.createdAt);
}

/** Tin còn đang bán của chủ shop (để poster mở tin đó) */
export const findOwnAvailableListing = (db: Db, ownerId: string, id: string) =>
  db.listing.findFirst({ where: { id, ownerId, status: 'AVAILABLE' }, select: { id: true } });

export const createPoster = (db: Db, data: Prisma.ShopBannerUncheckedCreateInput) =>
  db.shopBanner.create({ data, select: posterSelect });

export const updatePoster = (db: Db, id: string, data: Prisma.ShopBannerUncheckedUpdateInput) =>
  db.shopBanner.update({ where: { id }, data, select: posterSelect });

/* ---------- admin ---------- */

export const adminPosterSelect = {
  ...posterSelect,
  reviewedById: true,
  shop: {
    select: {
      id: true, name: true, logoUrl: true, accentColor: true, verificationType: true, ownerId: true,
      owner: { select: { email: true, fullName: true, storeSubscription: { select: { endsAt: true, package: { select: { tier: true } } } } } },
    },
  },
} as const satisfies Prisma.ShopBannerSelect;

export type AdminPosterRecord = Prisma.ShopBannerGetPayload<{ select: typeof adminPosterSelect }>;

/** Danh sách duyệt: chờ duyệt cũ nhất trước, trạng thái khác mới nhất trước */
export const findPostersForAdmin = (status: ShopBannerStatus | undefined, take = 100) =>
  prisma.shopBanner.findMany({
    where: status ? { status } : {},
    select: adminPosterSelect,
    orderBy: status === 'PENDING' ? [{ createdAt: 'asc' }, { id: 'asc' }] : [{ updatedAt: 'desc' }, { id: 'asc' }],
    take,
  });

export const findPosterForAdmin = (db: Db, id: string) =>
  db.shopBanner.findUnique({ where: { id }, select: adminPosterSelect });

export const countPending = () => prisma.shopBanner.count({ where: { status: 'PENDING' } });
