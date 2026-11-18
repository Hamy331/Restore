import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { notificationSelect } from './notification.dto.js';

type Db = Prisma.TransactionClient;

export const findPage = (where: Prisma.NotificationWhereInput, limit: number, skip: number) =>
  prisma.$transaction([
    prisma.notification.findMany({ where, select: notificationSelect, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit, skip }),
    prisma.notification.count({ where }),
  ]);

export const countUnread = (userId: string) => prisma.notification.count({ where: { userId, readAt: null } });

export const markRead = (userId: string, id: string, at: Date) =>
  prisma.notification.updateMany({ where: { id, userId, readAt: null }, data: { readAt: at } });

export const markAllRead = (userId: string, at: Date) =>
  prisma.notification.updateMany({ where: { userId, readAt: null }, data: { readAt: at } });

export const exists = (userId: string, id: string) =>
  prisma.notification.count({ where: { id, userId } }).then((count) => count > 0);

export const remove = (userId: string, id: string) => prisma.notification.deleteMany({ where: { id, userId } });

/** Thêm nhiều thông báo; dòng trùng (userId, dedupeKey) bị bỏ qua */
export const createMany = (db: Db, data: Prisma.NotificationCreateManyInput[]) =>
  db.notification.createMany({ data, skipDuplicates: true });

/** Xoá thông báo cũ quá [keep] cái mới nhất của mỗi người trong [userIds] */
export async function trim(db: Db, userIds: string[], keep: number) {
  for (const userId of userIds) {
    const edge = await db.notification.findFirst({
      where: { userId }, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], skip: keep, select: { createdAt: true },
    });
    if (edge) await db.notification.deleteMany({ where: { userId, createdAt: { lte: edge.createdAt } } });
  }
}
