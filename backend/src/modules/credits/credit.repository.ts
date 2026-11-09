import { CreditBucket, CreditTxnType, Prisma, TopupStatus } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';

export type Db = Prisma.TransactionClient;

export const findActivePackages = () =>
  prisma.creditPackage.findMany({ where: { active: true }, orderBy: [{ sortOrder: 'asc' }, { priceVnd: 'asc' }] });

export const findActivePackage = (tx: Db, id: string) => tx.creditPackage.findFirst({ where: { id, active: true } });

/** Tổng xu theo loại (nạp / tặng) của một người */
export async function sumByBucket(userId: string) {
  const rows = await prisma.creditTransaction.groupBy({ by: ['bucket'], where: { userId }, _sum: { amount: true } });
  return rows.map((row) => ({ bucket: row.bucket, amount: row._sum.amount ?? 0 }));
}

/** Hạn gần nhất của các lần được tặng xu còn hiệu lực */
export const findNextBonusExpiry = (userId: string, now: Date) =>
  prisma.creditTransaction.findFirst({
    where: { userId, bucket: CreditBucket.BONUS, amount: { gt: 0 }, expiresAt: { gt: now } },
    orderBy: { expiresAt: 'asc' },
    select: { expiresAt: true },
  });

export const countTransactions = (userId: string, types?: CreditTxnType[]) =>
  prisma.creditTransaction.count({ where: { userId, ...(types && { type: { in: types } }) } });

export const findTransactions = (userId: string, types: CreditTxnType[] | undefined, skip: number, take: number) =>
  prisma.creditTransaction.findMany({
    where: { userId, ...(types && { type: { in: types } }) },
    orderBy: { createdAt: 'desc' },
    skip,
    take,
    include: { topupOrder: { select: { code: true, method: true, amountVnd: true } } },
  });

/** Đơn chờ trả đã quá hạn của người dùng → EXPIRED */
export const expireStalePending = (tx: Db, userId: string, now: Date) =>
  tx.creditTopupOrder.updateMany({ where: { userId, status: TopupStatus.PENDING, expiresAt: { lte: now } }, data: { status: TopupStatus.EXPIRED } });

export const countPending = (tx: Db, userId: string) =>
  tx.creditTopupOrder.count({ where: { userId, status: TopupStatus.PENDING } });

export const createOrder = (tx: Db, data: Prisma.CreditTopupOrderUncheckedCreateInput) => tx.creditTopupOrder.create({ data });

export const findOrder = (tx: Db, id: string) => tx.creditTopupOrder.findUnique({ where: { id } });

/** Đổi trạng thái chỉ khi đơn còn PENDING; trả về số dòng đã đổi (0 = người khác đã xử lý) */
export const decidePending = async (tx: Db, id: string, data: Prisma.CreditTopupOrderUncheckedUpdateInput) =>
  (await tx.creditTopupOrder.updateMany({ where: { id, status: TopupStatus.PENDING }, data })).count;

export const createTransactions = (tx: Db, data: Prisma.CreditTransactionUncheckedCreateInput[]) =>
  tx.creditTransaction.createMany({ data });
