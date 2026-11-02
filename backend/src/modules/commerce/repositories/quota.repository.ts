import { Prisma, StoreTier } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';

export type Db = Prisma.TransactionClient;

/**
 * Transaction SERIALIZABLE cho thao tác đụng tới quota (đăng tin, đẩy tin, duyệt đơn).
 * Postgres báo xung đột (P2034) thì thử lại tối đa 3 lần; trả null nếu vẫn xung đột.
 */
export async function serializableTransaction<T>(work: (tx: Db) => Promise<T>): Promise<{ value: T } | null> {
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      return { value: await prisma.$transaction(work, { isolationLevel: Prisma.TransactionIsolationLevel.Serializable }) };
    } catch (error) {
      if (!(error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2034')) throw error;
    }
  }
  return null;
}

export const findSubscription = (tx: Db, userId: string) =>
  tx.storeSubscription.findUnique({ where: { userId }, include: { package: true, category: true } });

export const findPersonalPackage = (tx: Db) => tx.storePackage.findUnique({ where: { tier: StoreTier.PERSONAL } });

export const countPublishedSince = (tx: Db, ownerId: string, since: Date) =>
  tx.listing.count({ where: { ownerId, publishedAt: { gte: since } } });

export const countActiveListings = (tx: Db, ownerId: string) =>
  tx.listing.count({ where: { ownerId, status: { in: ['PENDING', 'AVAILABLE', 'RESERVED'] } } });

export const countIncludedPromotionsSince = (tx: Db, userId: string, since: Date) =>
  tx.promotion.count({ where: { userId, source: 'INCLUDED', createdAt: { gte: since } } });

/** Transaction thường, chỉ để đọc nhất quán */
export const transaction = <T>(work: (tx: Db) => Promise<T>) => prisma.$transaction(work);
