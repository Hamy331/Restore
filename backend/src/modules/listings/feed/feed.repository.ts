import { prisma } from '../../../lib/prisma.js';
import type { ListingFilters } from '../listing.filters.js';
import { listingQuery } from '../listing-query.js';
import { fields, visible } from '../listing.mapper.js';

export type RankedRow = { id: string; distanceKm: number | null; isFeatured: boolean };

/**
 * Lấy một trang id tin đã xếp hạng (đẩy tin, gói cửa hàng, khoảng cách, thời gian)
 * cùng tổng số tin khớp bộ lọc.
 */
export async function findRankedPage(filters: ListingFilters, now: Date, limit: number, skip: number) {
  const query = listingQuery(filters, now);
  const [rows, totals] = await prisma.$transaction([
    prisma.$queryRaw<RankedRow[]>`${query} LIMIT ${limit} OFFSET ${skip}`,
    prisma.$queryRaw<{ n: number }[]>`SELECT COUNT(*)::int AS n FROM (${query}) ranked`,
  ]);
  return { rows, totalItems: totals[0]?.n ?? 0 };
}

export const findVisibleByIds = (ids: string[]) =>
  ids.length ? prisma.listing.findMany({ where: { ...visible, id: { in: ids } }, select: fields }) : Promise.resolve([]);

/** Tin đang có gói đẩy FEATURED còn hiệu lực, mới nhất trước */
export const findFeatured = (now: Date, limit: number) =>
  prisma.listing.findMany({
    where: {
      ...visible,
      promotions: { some: { startsAt: { lte: now }, endsAt: { gt: now }, package: { kind: 'FEATURED' } } },
    },
    select: fields,
    take: limit,
    orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
  });

/** Trong [listingIds], những tin mà [userId] đã lưu */
export async function findFavoriteIds(userId: string | undefined, listingIds: string[]) {
  if (!userId || !listingIds.length) return new Set<string>();
  const rows = await prisma.listingFavorite.findMany({
    where: { userId, listingId: { in: listingIds } },
    select: { listingId: true },
  });
  return new Set(rows.map((row) => row.listingId));
}
