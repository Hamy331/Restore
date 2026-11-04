import { Prisma, StoreTier } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import type { Db } from './quota.repository.js';

const orderUser = { select: { id: true, email: true, fullName: true } } as const;

export const findAllCategories = () => prisma.category.findMany({ orderBy: { name: 'asc' } });

export const findPackagesByTier = (tiers: StoreTier[]) =>
  prisma.storePackage.findMany({ where: { tier: { in: tiers } }, orderBy: { priorityLevel: 'asc' } });

export const findPackage = (tx: Db, id: string) => tx.storePackage.findUnique({ where: { id } });

export const findActiveCategory = (tx: Db, id: string) => tx.category.findFirst({ where: { id, active: true } });

export const findPendingOrder = (tx: Db, userId: string) => tx.storeOrder.findFirst({ where: { userId, status: 'PENDING' } });

export const findLatestPendingOrderSummary = (tx: Db, userId: string) =>
  tx.storeOrder.findFirst({
    where: { userId, status: 'PENDING' },
    select: { id: true, createdAt: true, amount: true },
    orderBy: { createdAt: 'desc' },
  });

export const createOrder = (tx: Db, data: Prisma.StoreOrderUncheckedCreateInput) =>
  tx.storeOrder.create({ data, include: { package: true, category: true } });

export const findPendingOrders = () =>
  prisma.storeOrder.findMany({
    where: { status: 'PENDING' },
    include: { user: orderUser, package: true, category: true },
    orderBy: { createdAt: 'asc' },
    take: 100,
  });

export const findOrderForApproval = (tx: Db, id: string) =>
  tx.storeOrder.findUnique({
    where: { id },
    include: { user: { select: { role: true, status: true } }, category: { select: { active: true } } },
  });

/** Đổi trạng thái đơn khi còn PENDING; trả về số dòng đổi */
export async function decidePendingOrder(tx: Db, id: string, status: 'CONFIRMED' | 'REJECTED', decidedAt: Date) {
  return (await tx.storeOrder.updateMany({ where: { id, status: 'PENDING' }, data: { status, decidedAt } })).count;
}

export const findSubscription = (tx: Db, userId: string) => tx.storeSubscription.findUnique({ where: { userId } });

export const upsertSubscription = (tx: Db, userId: string, data: { packageId: string; categoryId: string; startsAt: Date; endsAt: Date }) =>
  tx.storeSubscription.upsert({
    where: { userId },
    create: { userId, ...data },
    update: data,
    include: { package: true, category: true },
  });

/* ---------- Quản trị ---------- */

/** Mọi gói cửa hàng (kể cả PERSONAL), ưu tiên thấp trước */
export const findAllPackages = () => prisma.storePackage.findMany({ orderBy: { priorityLevel: 'asc' } });

/** Đơn mua gói, mới trước, kèm người mua, gói, danh mục */
export function findOrderPage(status: Prisma.StoreOrderWhereInput['status'] | undefined, skip: number, take: number) {
  const where: Prisma.StoreOrderWhereInput = status ? { status } : {};
  return prisma.$transaction([
    prisma.storeOrder.findMany({ where, take, skip, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      include: { user: { select: { fullName: true, email: true } }, package: true, category: true } }),
    prisma.storeOrder.count({ where }),
  ]);
}

export const findPackageOrThrow = (tx: Db, id: string) => tx.storePackage.findUniqueOrThrow({ where: { id } });

export const updatePackage = (tx: Db, id: string, data: Prisma.StorePackageUpdateInput) => tx.storePackage.update({ where: { id }, data });
