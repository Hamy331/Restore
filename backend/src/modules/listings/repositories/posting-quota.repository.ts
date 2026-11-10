import { ListingStatus } from '@prisma/client';
import type { Db } from './listing.repository.js';

/** Trạng thái chiếm suất đăng tin */
export const COUNTED_STATUSES: ListingStatus[] = [ListingStatus.PENDING, ListingStatus.AVAILABLE, ListingStatus.RESERVED];

export const findCategoryRules = (tx: Db) =>
  tx.category.findMany({ where: { active: true }, select: { id: true, freeListingLimit: true, extraListingCredits: true, displayDays: true } });

/**
 * Số tin miễn phí theo chuyên mục: [used] đang chiếm suất, [recent] đã đăng trong cửa sổ chống đăng lại.
 * Bỏ qua tin [excludeId] (tin đang sửa / đang đăng lại).
 */
export async function countFreeByCategory(tx: Db, ownerId: string, since: Date, excludeId?: string) {
  const base = { ownerId, paidCredits: 0, categoryId: { not: null }, ...(excludeId && { id: { not: excludeId } }) };
  const [used, recent] = await Promise.all([
    tx.listing.groupBy({ by: ['categoryId'], where: { ...base, status: { in: COUNTED_STATUSES } }, _count: { _all: true } }),
    tx.listing.groupBy({
      by: ['categoryId'],
      where: { ...base, status: { notIn: [ListingStatus.DRAFT, ListingStatus.REJECTED] }, publishedAt: { gte: since } },
      _count: { _all: true },
    }),
  ]);
  const ids = new Set([...used, ...recent].map((row) => row.categoryId!));
  return [...ids].map((categoryId) => ({
    categoryId,
    used: used.find((row) => row.categoryId === categoryId)?._count._all ?? 0,
    recent: recent.find((row) => row.categoryId === categoryId)?._count._all ?? 0,
  }));
}

/** Số tin đang chiếm suất theo chuyên mục (gói cửa hàng, tính cả tin trả xu) */
export async function countActiveByCategory(tx: Db, ownerId: string) {
  const rows = await tx.listing.groupBy({
    by: ['categoryId'], where: { ownerId, status: { in: COUNTED_STATUSES }, categoryId: { not: null } }, _count: { _all: true },
  });
  return new Map(rows.map((row) => [row.categoryId!, row._count._all]));
}
