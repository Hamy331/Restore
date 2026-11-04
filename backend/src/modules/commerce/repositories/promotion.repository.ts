import { Prisma, PromotionKind } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { prisma } from '../../../lib/prisma.js';
import type { Db } from './quota.repository.js';

/* ---------- Gói đẩy tin ---------- */

export const findAllPackages = () =>
  prisma.promotionPackage.findMany({ orderBy: [{ kind: 'asc' }, { durationDays: 'asc' }] });

export const findActivePackage = (tx: Db, id: string) => tx.promotionPackage.findFirst({ where: { id, active: true } });

export const createPackage = (tx: Db, data: Omit<Prisma.PromotionPackageCreateInput, 'id'>) =>
  tx.promotionPackage.create({ data: { id: randomUUID(), ...data } });

export const findPackageWithUsage = (tx: Db, id: string) =>
  tx.promotionPackage.findUnique({ where: { id }, include: { _count: { select: { promotions: true, orders: true } } } });

export async function updatePackage(tx: Db, id: string, data: Prisma.PromotionPackageUpdateManyMutationInput) {
  return (await tx.promotionPackage.updateMany({ where: { id }, data })).count;
}

export const findPackage = (tx: Db, id: string) => tx.promotionPackage.findUniqueOrThrow({ where: { id } });

/* ---------- Đẩy tin ---------- */

export const findAvailableListingOf = (tx: Db, id: string, ownerId: string) =>
  tx.listing.findFirst({ where: { id, ownerId, status: 'AVAILABLE' } });

export const findMyPromotions = (userId: string) =>
  prisma.promotion.findMany({
    where: { userId },
    include: { package: true, listing: { select: { id: true, title: true, status: true } } },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });

/** Quảng cáo cùng loại còn hiệu lực trên tin, hết hạn muộn nhất trước */
export const findRunningPromotion = (tx: Db, listingId: string, kind: PromotionKind, now: Date) =>
  tx.promotion.findFirst({
    where: { listingId, endsAt: { gt: now }, package: { kind } },
    orderBy: { endsAt: 'desc' },
  });

export const createPromotion = (tx: Db, data: Prisma.PromotionUncheckedCreateInput) =>
  tx.promotion.create({ data, include: { package: true } });

/* ---------- Đơn mua đẩy tin ---------- */

export const findPendingOrderFor = (tx: Db, userId: string, listingId: string) =>
  tx.promotionOrder.findFirst({ where: { userId, listingId, status: 'PENDING' } });

export const createOrder = (tx: Db, data: Prisma.PromotionOrderUncheckedCreateInput) =>
  tx.promotionOrder.create({ data, include: { package: true, listing: { select: { id: true, title: true } } } });

export const findPendingOrders = () =>
  prisma.promotionOrder.findMany({
    where: { status: 'PENDING' },
    include: {
      user: { select: { id: true, email: true, fullName: true } },
      listing: { select: { id: true, title: true, status: true } },
      package: true,
    },
    orderBy: { createdAt: 'asc' },
    take: 100,
  });

export const findOrderForApproval = (tx: Db, id: string) =>
  tx.promotionOrder.findUnique({
    where: { id },
    include: { package: true, user: { select: { role: true, status: true } }, listing: { select: { ownerId: true, status: true } } },
  });

/** Đổi trạng thái đơn khi còn PENDING; trả về số dòng đổi */
export async function decidePendingOrder(tx: Db, id: string, status: 'CONFIRMED' | 'REJECTED', decidedAt: Date) {
  return (await tx.promotionOrder.updateMany({ where: { id, status: 'PENDING' }, data: { status, decidedAt } })).count;
}

/** Đơn đẩy tin cho trang quản trị, mới trước, kèm người mua, gói, tin */
export function findOrderPage(status: Prisma.PromotionOrderWhereInput['status'] | undefined, skip: number, take: number) {
  const where: Prisma.PromotionOrderWhereInput = status ? { status } : {};
  return prisma.$transaction([
    prisma.promotionOrder.findMany({ where, take, skip, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      include: { user: { select: { fullName: true, email: true } }, package: true, listing: { select: { id: true, title: true } } } }),
    prisma.promotionOrder.count({ where }),
  ]);
}
