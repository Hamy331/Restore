import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';

export type SavedAddressRow = Prisma.SavedAddressGetPayload<object>;
type Db = Prisma.TransactionClient;

export const transaction = <T>(fn: (tx: Db) => Promise<T>) => prisma.$transaction(fn);

/** Địa chỉ đã lưu của [userId], mới dùng gần nhất trước */
export const listByUser = (userId: string, db: Db = prisma) =>
  db.savedAddress.findMany({ where: { userId }, orderBy: [{ lastUsedAt: 'desc' }, { createdAt: 'desc' }] });

export const findOwned = (userId: string, id: string, db: Db = prisma) =>
  db.savedAddress.findFirst({ where: { id, userId } });

export const findByKey = (tx: Db, userId: string, wardCode: string, streetKey: string) =>
  tx.savedAddress.findUnique({ where: { userId_wardCode_streetKey: { userId, wardCode, streetKey } } });

export const create = (tx: Db, data: Prisma.SavedAddressUncheckedCreateInput) => tx.savedAddress.create({ data });

export const update = (id: string, data: Prisma.SavedAddressUpdateInput, db: Db = prisma) =>
  db.savedAddress.update({ where: { id }, data });

export const removeMany = (tx: Db, ids: string[]) => tx.savedAddress.deleteMany({ where: { id: { in: ids } } });

export const remove = (userId: string, id: string) => prisma.savedAddress.deleteMany({ where: { id, userId } });
