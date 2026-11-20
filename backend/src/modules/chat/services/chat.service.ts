import { Prisma } from '@prisma/client';
import { connectedUserIds } from './chat.events.js';
import * as repository from '../repositories/chat.repository.js';
import { AppError } from '../../../common/errors/app-error.js';

import { prisma } from '../../../lib/prisma.js';
import { parseId } from '../chat.validator.js';

const online = (lastActiveAt: Date | null) =>
  !!lastActiveAt && Date.now() - lastActiveAt.getTime() < 2 * 60 * 1000;

export const startConversation = async (selfId: string, body: unknown) => {
  const input = body && typeof body === 'object' ? (body as Record<string, unknown>) : {};
  // Nhắn từ trang tin mà app chỉ gửi listingId: người nhận là người đăng tin; còn lại gửi recipientId
  let recipientId: string;
  if (input.recipientId === undefined && input.listingId !== undefined) {
    const owner = await prisma.listing.findUnique({
      where: { id: parseId(input.listingId, 'listingId') },
      select: { ownerId: true },
    });
    if (!owner) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng.');
    recipientId = owner.ownerId;
  } else {
    recipientId = parseId(input.recipientId, 'recipientId');
  }
  if (recipientId === selfId) throw new AppError(422, 'SELF_CHAT', 'Không thể nhắn tin cho chính mình.');
  const recipient = await repository.findRecipient(recipientId);
  if (!recipient || recipient.status !== 'ACTIVE') {
    throw new AppError(404, 'USER_NOT_FOUND', 'Không tìm thấy người nhận.');
  }
  const listingId = input.listingId === undefined ? undefined : parseId(input.listingId, 'listingId');
  if (listingId) {
    const listing = await prisma.listing.findFirst({
      where: { id: listingId, ownerId: recipientId, status: 'AVAILABLE' },
      select: { id: true },
    });
    if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Tin đăng không còn khả dụng.');
  }
  return repository.startThread(selfId, recipientId, listingId);
};

type Thread = Awaited<ReturnType<typeof repository.findThread>>;
function listingContext(context: Thread['contexts'][number] | undefined | null, selfId: string) {
  if (!context) return null;
  const { trade, listing } = context;
  if (!listing && !trade) return null;
  return {
    contextId: context.id,
    ...(listing && {
      product: repository.listingPreview(listing),
      canOffer:
        listing.ownerId !== selfId &&
        listing.status === 'AVAILABLE' &&
        listing.allowSale &&
        listing.isNegotiable &&
        !trade,
    }),
    title: trade?.title ?? listing!.title,
    seller: (trade?.sellerId ?? listing?.ownerId) === selfId,
    stage: trade
      ? trade.confirmedAt
        ? 'complete'
        : 'pending'
      : listing?.allowSale &&
          !listing._count.conversations &&
          ['AVAILABLE', 'HIDDEN', 'SOLD'].includes(listing.status)
        ? 'open'
        : 'closed',
    reviewed: trade?.reviews.some((r) => r.authorId === selfId) ?? false,
  };
}

async function summaries(selfId: string, threads: Thread[]) {
  const stats = await repository.threadStats(
    selfId,
    threads.map((t) => t.id),
  );
  const counts = new Map(stats.map((s) => [s.id, s]));
  const messages = await repository.latestMessages(
    stats.flatMap((s) => (s.latest === null ? [] : [s.latest])),
  );
  const latest = new Map(messages.map((m) => [m.sequence, m]));
  return threads.map((row) => {
    const peer = row.members.find((m) => m.userId !== selfId)!;
    const stat = counts.get(row.id);
    const context = listingContext(row.contexts[0], selfId);
    return {
      id: row.id,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      ...(context && { listingContext: context }),
      blockedByMe: row.members.some((m) => m.userId === selfId && m.blocked),
      blocked: row.members.some((m) => m.blocked),
      otherUser: { ...peer.user, isOnline: online(peer.user.lastActiveAt) },
      lastMessage: latest.get(stat?.latest ?? 0) ?? null,
      unreadCount: stat?.unread ?? 0,
    };
  });
}

export async function getConversation(selfId: string, id: string) {
  const root = await repository.threadFor(id, selfId);
  const row = await repository.findThread(root);
  if (root !== id) {
    const selected = await repository.findContext(id);
    row.contexts = selected ? [selected] : [];
  }
  return (await summaries(selfId, [row]))[0];
}
export const listConversations = async (selfId: string) =>
  summaries(selfId, await repository.findThreads(selfId));

export const listMessages = async (selfId: string, id: string, query: Record<string, unknown>) => {
  const root = await repository.threadFor(id, selfId);
  const limit = query.limit === undefined ? 30 : Number(query.limit);
  const before = query.before === undefined ? undefined : Number(query.before);
  if (
    !Number.isInteger(limit) ||
    limit < 1 ||
    limit > 100 ||
    (before !== undefined && (!Number.isInteger(before) || before < 1))
  ) {
    throw new AppError(422, 'INVALID_PAGINATION', 'Tham số phân trang không hợp lệ.');
  }
  const rows = await repository.findMessages(root, limit, before, query.media === '1');
  return {
    items: rows.slice(0, limit).reverse(),
    hasMore: rows.length > limit,
    nextBefore: rows.length > limit ? rows[limit - 1].sequence : null,
  };
};

export async function sendMessage(selfId: string, id: string, body: unknown) {
  const root = await repository.threadFor(id, selfId);
  const input = body && typeof body === 'object' ? (body as Record<string, unknown>) : {};
  const clientId = parseId(input.clientId, 'clientId');
  const text = typeof input.text === 'string' ? input.text.trim() : '';
  if (!text || text.length > 2000)
    throw new AppError(422, 'INVALID_MESSAGE', 'Tin nhắn phải có 1–2000 ký tự.');
  let contextId: string | undefined;
  if (input.listingId !== undefined || input.attachListing === true) {
    const listingId = input.listingId === undefined ? undefined : parseId(input.listingId, 'listingId');
    const context = await prisma.conversation.findFirst({
      where: {
        threadId: root,
        listingId: listingId ?? { not: null },
        ...(!listingId && root !== id && { id }),
      },
      orderBy: { updatedAt: 'desc' },
      select: { id: true },
    });
    if (!context) throw new AppError(409, 'LISTING_UNAVAILABLE', 'Không tìm thấy tin đang trao đổi.');
    contextId = context.id;
  }
  const duplicate = async () => {
    const message = await repository.findMessageByClientId(selfId, clientId);
    if (!message) return null;
    if (
      message.conversationId !== (contextId ?? root) ||
      message.text !== text ||
      message.mediaName ||
      !!message.listingPreview !== !!contextId
    )
      throw new AppError(409, 'CLIENT_ID_REUSED', 'Mã tin nhắn đã được sử dụng.');
    return { message, created: false };
  };
  const prior = await duplicate();
  if (prior) return prior;
  try {
    return {
      message: await repository.createMessage(root, selfId, clientId, text, contextId),
      created: true,
    };
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      const prior = await duplicate();
      if (prior) return prior;
    }
    throw error;
  }
}

export async function setPreference(userId: string, id: string, input: Record<string, unknown>) {
  const root = await repository.threadFor(id, userId);
  const data: { blocked?: boolean; hidden?: boolean } = {};
  if (typeof input.blocked === 'boolean') data.blocked = input.blocked;
  if (typeof input.hidden === 'boolean') data.hidden = input.hidden;
  if (!Object.keys(data).length) throw new AppError(422, 'INVALID_PREFERENCE', 'Thao tác không hợp lệ.');
  await prisma.$transaction(async (tx) => {
    await tx.$queryRaw`SELECT id FROM "Conversation" WHERE id=${root} FOR UPDATE`;
    await tx.conversationMember.update({
      where: { conversationId_userId: { conversationId: root, userId } },
      data,
    });
  });
  return data;
}
export async function discussed(userId: string, id: string) {
  const root = await repository.threadFor(id, userId);
  const rows = await prisma.conversation.findMany({
    where: { threadId: root },
    orderBy: { updatedAt: 'desc' },
    select: {
      id: true,
      listing: { select: { id: true, title: true, price: true, images: true, allowSale: true } },
      trade: true,
    },
  });
  return rows.flatMap<{
    contextId: string;
    id: string;
    title: string;
    price: string | null;
    image: string | null;
  }>(({ id, listing, trade }) =>
    listing
      ? [{ contextId: id, ...repository.listingPreview(listing) }]
      : trade
        ? [
            {
              contextId: id,
              id: trade.listingId,
              title: trade.title,
              price: trade.price.toString(),
              image: trade.image,
            },
          ]
        : [],
  );
}
export const markRead = async (selfId: string, id: string, through?: number) =>
  repository.markRead(await repository.threadFor(id, selfId), selfId, through);
export const unreadCount = async (selfId: string) => ({
  count: (await repository.threadStats(selfId)).reduce((n, s) => n + s.unread, 0),
});

export const conversationMembers = async (id: string) => repository.findMembers(id);

export const heartbeat = async (userId: string) => {
  const connectedIds = connectedUserIds().filter((id) => id !== userId);
  const [user, peers] = await Promise.all([
    repository.touchPresence(userId),
    connectedIds.length ? repository.findPeers(userId, connectedIds) : Promise.resolve([]),
  ]);
  return { peers: peers.map((peer) => peer.userId), lastActiveAt: user.lastActiveAt };
};
