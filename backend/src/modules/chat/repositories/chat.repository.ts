import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { AppError } from '../../../common/errors/app-error.js';

const previewSelect = { id: true, title: true, images: true, price: true, allowSale: true } as const;
export const listingPreview = (listing: Prisma.ListingGetPayload<{ select: typeof previewSelect }>) => ({
  id: listing.id,
  title: listing.title,
  image: listing.images[0] ?? null,
  price: listing.allowSale ? listing.price.toString() : null,
});

const userSelect = { id: true, fullName: true, username: true, avatarUrl: true, lastActiveAt: true } as const;
const messageSelect = {
  id: true,
  sequence: true,
  conversationId: true,
  senderId: true,
  clientId: true,
  text: true,
  createdAt: true,
  listingPreview: true,
  mediaName: true,
} as const;
const productContext = {
  id: true,
  listing: {
    select: {
      ...previewSelect,
      ownerId: true,
      status: true,
      isNegotiable: true,
      _count: { select: { conversations: { where: { trade: { isNot: null } } } } },
    },
  },
  trade: {
    select: { title: true, sellerId: true, confirmedAt: true, reviews: { select: { authorId: true } } },
  },
} as const;
const threadSelect = {
  id: true,
  createdAt: true,
  updatedAt: true,
  members: { select: { userId: true, blocked: true, user: { select: userSelect } } },
  contexts: { orderBy: [{ updatedAt: 'desc' }, { id: 'asc' }], take: 1, select: productContext },
} satisfies Prisma.ConversationSelect;

export const findRecipient = (id: string) =>
  prisma.user.findUnique({ where: { id }, select: { status: true } });

export async function threadFor(id: string, userId: string) {
  const row = await prisma.conversation.findFirst({
    where: { id, members: { some: { userId } } },
    select: { threadId: true },
  });
  if (!row) throw new AppError(404, 'CONVERSATION_NOT_FOUND', 'Không tìm thấy cuộc trò chuyện.');
  return row.threadId ?? id;
}

export function startThread(selfId: string, recipientId: string, listingId?: string) {
  const pairKey = [selfId, recipientId].sort().join(':');
  return prisma.$transaction(async (tx) => {
    // Serializes the initial upsert (including its nested member inserts).
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtextextended(${pairKey}, 0))`;
    const members = { create: [{ userId: selfId }, { userId: recipientId }] };
    const root = await tx.conversation.upsert({
      where: { pairKey },
      create: { pairKey, members },
      update: {},
      select: { id: true, createdAt: true, members: { select: { userId: true } } },
    });
    if (listingId) {
      await writableThread(tx, root.id);
      const key = JSON.stringify([listingId, selfId, recipientId]);
      await tx.conversation.upsert({
        where: { pairKey: key },
        create: { pairKey: key, threadId: root.id, listingId, members },
        update: {},
      });
    }
    return root;
  });
}

export const findThread = (id: string) =>
  prisma.conversation.findUniqueOrThrow({ where: { id }, select: threadSelect });
export const findThreads = (userId: string) =>
  prisma.conversation.findMany({
    where: { threadId: null, members: { some: { userId, hidden: false } } },
    orderBy: { updatedAt: 'desc' },
    take: 100,
    select: threadSelect,
  });
export const findContext = (id: string) =>
  prisma.conversation.findUnique({ where: { id }, select: productContext });
export const inThread = (id: string) => ({ OR: [{ id }, { threadId: id }] });

export async function threadStats(userId: string, ids?: string[]) {
  if (ids?.length === 0) return [];
  return prisma.$queryRaw<{ id: string; unread: number; latest: number | null }[]>`
    SELECT coalesce(c."threadId",c.id) id,
      count(m.sequence) FILTER (WHERE m."senderId" <> ${userId} AND m.sequence > cm."lastReadSequence")::int unread,
      max(m.sequence) latest
    FROM "ConversationMember" cm JOIN "Conversation" c ON c.id=cm."conversationId"
    LEFT JOIN "Message" m ON m."conversationId"=c.id
    WHERE cm."userId"=${userId}
    ${
      ids
        ? Prisma.sql`AND coalesce(c."threadId",c.id) IN (${Prisma.join(ids)})`
        : Prisma.sql`AND EXISTS (SELECT 1 FROM "ConversationMember" root
        WHERE root."conversationId"=coalesce(c."threadId",c.id) AND root."userId"=${userId} AND root.hidden=false)`
    }
    GROUP BY coalesce(c."threadId",c.id)`;
}

export const latestMessages = (sequences: number[]) =>
  prisma.message.findMany({ where: { sequence: { in: sequences } }, select: messageSelect });
export const findMessages = (id: string, limit: number, before?: number, mediaOnly = false) =>
  prisma.message.findMany({
    where: {
      conversation: inThread(id),
      ...(before && { sequence: { lt: before } }),
      ...(mediaOnly && { mediaName: { not: null } }),
    },
    orderBy: { sequence: 'desc' },
    take: limit + 1,
    select: messageSelect,
  });

export async function writableThread(tx: Prisma.TransactionClient, root: string) {
  await tx.$queryRaw`SELECT id FROM "Conversation" WHERE id=${root} FOR UPDATE`;
  if (
    await tx.conversationMember.findFirst({
      where: { conversationId: root, blocked: true },
      select: { userId: true },
    })
  ) {
    throw new AppError(403, 'CHAT_BLOCKED', 'Đã chặn nhắn tin trong hội thoại này.');
  }
}

export const touchThread = async (tx: Prisma.TransactionClient, root: string, contextId: string) => {
  await tx.conversation.updateMany({
    where: { id: { in: [root, contextId] } },
    data: { updatedAt: new Date() },
  });
  await tx.conversationMember.updateMany({
    where: { conversationId: root, hidden: true },
    data: { hidden: false },
  });
};

export async function createMessage(
  root: string,
  senderId: string,
  clientId: string,
  text: string,
  contextId?: string,
  mediaName?: string,
) {
  return prisma.$transaction(async (tx) => {
    await writableThread(tx, root);
    let preview;
    if (contextId) {
      const listing = await tx.listing.findFirst({
        where: { conversations: { some: { id: contextId, threadId: root } }, status: 'AVAILABLE' },
        select: previewSelect,
      });
      if (!listing) throw new AppError(409, 'LISTING_UNAVAILABLE', 'Tin đăng không còn khả dụng.');
      preview = listingPreview(listing);
    }
    const conversationId = contextId ?? root;
    const message = await tx.message.create({
      data: { conversationId, senderId, clientId, text, listingPreview: preview, mediaName },
      select: messageSelect,
    });
    await touchThread(tx, root, conversationId);
    await tx.user.update({ where: { id: senderId }, data: { lastActiveAt: new Date() } });
    return message;
  });
}

export const findMessageByClientId = (senderId: string, clientId: string) =>
  prisma.message.findUnique({ where: { senderId_clientId: { senderId, clientId } }, select: messageSelect });

export async function markRead(root: string, userId: string, through?: number) {
  const latest = await prisma.message.aggregate({
    where: { conversation: inThread(root), sequence: { lte: through } },
    _max: { sequence: true },
  });
  const lastReadSequence = latest._max.sequence ?? 0;
  await prisma.conversationMember.updateMany({
    where: { conversation: inThread(root), userId, lastReadSequence: { lt: lastReadSequence } },
    data: { lastReadSequence },
  });
  return { lastReadSequence };
}

export const findMembers = (id: string) =>
  prisma.conversationMember.findMany({ where: { conversationId: id }, select: { userId: true } });
export const touchPresence = (id: string) =>
  prisma.user.update({ where: { id }, data: { lastActiveAt: new Date() }, select: { lastActiveAt: true } });
export const findPeers = (userId: string, connectedIds: string[]) =>
  prisma.conversationMember.findMany({
    where: {
      conversation: {
        threadId: null,
        members: { some: { userId } },
        NOT: { members: { some: { blocked: true } } },
      },
      userId: { not: userId, in: connectedIds },
    },
    select: { userId: true },
    distinct: ['userId'],
  });
