import { Prisma, StoreTier } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../errors/app-error.js';

export const utcDayStart = (date: Date) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));

export const utcMonthStart = (date: Date) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));

export async function storePackageForUser(tx: Prisma.TransactionClient, userId: string, now: Date) {
  const subscription = await tx.storeSubscription.findUnique({
    where: { userId },
    include: { package: true, category: true },
  });
  if (subscription && subscription.startsAt <= now && subscription.endsAt > now) {
    return { package: subscription.package, endsAt: subscription.endsAt, category: subscription.category };
  }
  const personal = await tx.storePackage.findUnique({ where: { tier: StoreTier.PERSONAL } });
  if (!personal) throw new AppError(503, 'STORE_CATALOG_UNAVAILABLE', 'Gói tài khoản chưa được cấu hình.');
  return { package: personal, endsAt: null, category: null };
}

export async function storeUsage(tx: Prisma.TransactionClient, userId: string, now: Date) {
  const [today, active, promotionsThisMonth] = await Promise.all([
    tx.listing.count({ where: { ownerId: userId, publishedAt: { gte: utcDayStart(now) } } }),
    tx.listing.count({ where: { ownerId: userId, status: { in: ['AVAILABLE', 'RESERVED'] } } }),
    tx.promotion.count({ where: { userId, source: 'INCLUDED', createdAt: { gte: utcMonthStart(now) } } }),
  ]);
  return { today, active, promotionsThisMonth };
}

export async function withQuotaTransaction<T>(work: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T> {
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      return await prisma.$transaction(work, {
        isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      });
    } catch (error) {
      if (!(error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2034')) throw error;
    }
  }
  throw new AppError(503, 'QUOTA_BUSY', 'Có thao tác đồng thời trên tài khoản. Vui lòng thử lại.');
}
