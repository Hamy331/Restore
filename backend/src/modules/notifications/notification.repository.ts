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

/* ---------- Đọc dữ liệu cho thông báo hoạt động (mục 3) ---------- */

/** Tên hiển thị của người dùng, chỉ tài khoản còn hoạt động */
export const findActiveUser = (id: string) =>
  prisma.user.findFirst({ where: { id, status: 'ACTIVE' }, select: { id: true, fullName: true, avatarUrl: true } });

export const findListingBrief = (id: string) =>
  prisma.listing.findUnique({ where: { id }, select: { id: true, ownerId: true, title: true, images: true, status: true } });

export const findShopOfOwner = (ownerId: string) =>
  prisma.shop.findUnique({ where: { ownerId }, select: { id: true, name: true, logoUrl: true } });

export const findShop = (id: string) =>
  prisma.shop.findUnique({ where: { id }, select: { id: true, ownerId: true, name: true } });

/** Người theo dõi [ownerId] hoặc shop của người đó (tài khoản còn hoạt động, không gồm chính chủ) */
export async function findFollowerIds(ownerId: string) {
  const [users, shops] = await Promise.all([
    prisma.userFollow.findMany({ where: { followingId: ownerId, follower: { status: 'ACTIVE' } }, select: { followerId: true } }),
    prisma.shopFollow.findMany({ where: { shop: { ownerId }, user: { status: 'ACTIVE' } }, select: { userId: true } }),
  ]);
  return [...new Set([...users.map((row) => row.followerId), ...shops.map((row) => row.userId)])].filter((id) => id !== ownerId);
}

/** Người đã lưu tin (tài khoản còn hoạt động, không gồm chủ tin) */
export const findSaverIds = async (listingId: string, ownerId: string) =>
  (await prisma.listingFavorite.findMany({
    where: { listingId, userId: { not: ownerId }, user: { status: 'ACTIVE' } }, select: { userId: true },
  })).map((row) => row.userId);

export const findPost = (id: string) =>
  prisma.feedPost.findUnique({ where: { id }, select: { id: true, authorId: true, text: true, imageUrl: true } });

export const findComment = (id: string) =>
  prisma.feedComment.findUnique({ where: { id }, select: { id: true, authorId: true, postId: true, text: true, parentId: true } });

/** Thành viên khác của cuộc trò chuyện và số tin chưa đọc của họ trong cuộc đó */
export async function findChatRecipients(conversationId: string, senderId: string) {
  const members = await prisma.conversationMember.findMany({
    where: { conversationId, userId: { not: senderId }, user: { status: 'ACTIVE' } },
    select: { userId: true, lastReadSequence: true },
  });
  return Promise.all(members.map(async (member) => ({
    userId: member.userId,
    unread: await prisma.message.count({
      where: { conversationId, senderId: { not: member.userId }, sequence: { gt: member.lastReadSequence } },
    }),
  })));
}
