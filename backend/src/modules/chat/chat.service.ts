import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../errors/app-error.js';

const userSelect = { id: true, fullName: true, username: true, avatarUrl: true, lastActiveAt: true } satisfies Prisma.UserSelect;
const messageSelect = { id: true, sequence: true, conversationId: true, senderId: true,
  clientId: true, text: true, createdAt: true } satisfies Prisma.MessageSelect;

const parseId = (value: unknown, field: string): string => {
  if (typeof value !== 'string' || !/^[a-zA-Z0-9_-]{1,80}$/.test(value)) {
    throw new AppError(422, 'INVALID_ID', `${field} không hợp lệ.`, field);
  }
  return value;
};

export const parseConversationId = (value: unknown) => parseId(value, 'conversationId');

const memberOrThrow = async (conversationId: string, userId: string) => {
  const member = await prisma.conversationMember.findUnique({
    where: { conversationId_userId: { conversationId, userId } },
  });
  if (!member) throw new AppError(404, 'CONVERSATION_NOT_FOUND', 'Không tìm thấy cuộc trò chuyện.');
  return member;
};

const online = (lastActiveAt: Date | null) =>
  !!lastActiveAt && Date.now() - lastActiveAt.getTime() < 2 * 60 * 1000;

export const startConversation = async (selfId: string, body: unknown) => {
  const input = (body && typeof body === 'object') ? body as Record<string, unknown> : {};
  const recipientId = parseId(input.recipientId, 'recipientId');
  if (recipientId === selfId) throw new AppError(422, 'SELF_CHAT', 'Không thể nhắn tin cho chính mình.');
  const recipient = await prisma.user.findUnique({ where: { id: recipientId }, select: { id: true, status: true } });
  if (!recipient || recipient.status !== 'ACTIVE') {
    throw new AppError(404, 'USER_NOT_FOUND', 'Không tìm thấy người nhận.');
  }
  const pairKey = [selfId, recipientId].sort().join(':');
  const conversation = await prisma.conversation.upsert({
    where: { pairKey },
    create: { pairKey, members: { create: [{ userId: selfId }, { userId: recipientId }] } },
    update: {},
    select: { id: true, createdAt: true, members: { select: { userId: true } } },
  });
  return conversation;
};

export const getConversation = async (selfId: string, id: string) => {
  await memberOrThrow(id, selfId);
  const conversation = await prisma.conversation.findUnique({
    where: { id },
    select: { id: true, createdAt: true, updatedAt: true,
      members: { select: { userId: true, lastReadSequence: true, user: { select: userSelect } } },
      messages: { orderBy: { sequence: 'desc' }, take: 1, select: messageSelect },
    },
  });
  if (!conversation) throw new AppError(404, 'CONVERSATION_NOT_FOUND', 'Không tìm thấy cuộc trò chuyện.');
  const self = conversation.members.find((member) => member.userId === selfId)!;
  const other = conversation.members.find((member) => member.userId !== selfId)?.user;
  const unreadCount = await prisma.message.count({ where: {
    conversationId: id, senderId: { not: selfId }, sequence: { gt: self.lastReadSequence },
  } });
  return { id: conversation.id, createdAt: conversation.createdAt, updatedAt: conversation.updatedAt,
    otherUser: other ? { ...other, isOnline: online(other.lastActiveAt) } : null,
    lastMessage: conversation.messages[0] ?? null, unreadCount };
};

export const listConversations = async (selfId: string) => {
  const rows = await prisma.conversation.findMany({
    where: { members: { some: { userId: selfId } } },
    orderBy: { updatedAt: 'desc' }, take: 100, select: { id: true },
  });
  return Promise.all(rows.map((row) => getConversation(selfId, row.id)));
};

export const listMessages = async (selfId: string, id: string, query: Record<string, unknown>) => {
  await memberOrThrow(id, selfId);
  const limit = query.limit === undefined ? 30 : Number(query.limit);
  const before = query.before === undefined ? undefined : Number(query.before);
  if (!Number.isInteger(limit) || limit < 1 || limit > 100 ||
      (before !== undefined && (!Number.isInteger(before) || before < 1))) {
    throw new AppError(422, 'INVALID_PAGINATION', 'Tham số phân trang không hợp lệ.');
  }
  const rows = await prisma.message.findMany({
    where: { conversationId: id, ...(before ? { sequence: { lt: before } } : {}) },
    orderBy: { sequence: 'desc' }, take: limit + 1, select: messageSelect,
  });
  return { items: rows.slice(0, limit).reverse(), hasMore: rows.length > limit,
    nextBefore: rows.length > limit ? rows[limit - 1].sequence : null };
};

export const sendMessage = async (selfId: string, id: string, body: unknown) => {
  await memberOrThrow(id, selfId);
  const input = (body && typeof body === 'object') ? body as Record<string, unknown> : {};
  const clientId = parseId(input.clientId, 'clientId');
  const text = typeof input.text === 'string' ? input.text.trim() : '';
  if (!text || text.length > 2000) throw new AppError(422, 'INVALID_MESSAGE', 'Tin nhắn phải có 1–2000 ký tự.', 'text');
  const existing = await prisma.message.findUnique({
    where: { senderId_clientId: { senderId: selfId, clientId } }, select: messageSelect,
  });
  if (existing) {
    if (existing.conversationId !== id || existing.text !== text) {
      throw new AppError(409, 'CLIENT_ID_REUSED', 'Mã tin nhắn đã được sử dụng.');
    }
    return { message: existing, created: false };
  }
  try {
    const message = await prisma.$transaction(async (tx) => {
      const created = await tx.message.create({
        data: { conversationId: id, senderId: selfId, clientId, text }, select: messageSelect,
      });
      await tx.conversation.update({ where: { id }, data: { updatedAt: new Date() } });
      await tx.user.update({ where: { id: selfId }, data: { lastActiveAt: new Date() } });
      return created;
    });
    return { message, created: true };
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      const duplicate = await prisma.message.findUnique({
        where: { senderId_clientId: { senderId: selfId, clientId } }, select: messageSelect,
      });
      if (duplicate && duplicate.conversationId === id && duplicate.text === text) {
        return { message: duplicate, created: false };
      }
      throw new AppError(409, 'CLIENT_ID_REUSED', 'Mã tin nhắn đã được sử dụng.');
    }
    throw error;
  }
};

export const markRead = async (selfId: string, id: string) => {
  await memberOrThrow(id, selfId);
  const latest = await prisma.message.findFirst({ where: { conversationId: id },
    orderBy: { sequence: 'desc' }, select: { sequence: true } });
  if (latest) await prisma.conversationMember.updateMany({
    where: { conversationId: id, userId: selfId, lastReadSequence: { lt: latest.sequence } },
    data: { lastReadSequence: latest.sequence },
  });
  return { lastReadSequence: latest?.sequence ?? 0 };
};

export const unreadCount = async (selfId: string) => {
  const memberships = await prisma.conversationMember.findMany({
    where: { userId: selfId }, select: { conversationId: true, lastReadSequence: true },
  });
  const counts = await Promise.all(memberships.map((member) => prisma.message.count({ where: {
    conversationId: member.conversationId, senderId: { not: selfId },
    sequence: { gt: member.lastReadSequence },
  } })));
  return { count: counts.reduce((sum, count) => sum + count, 0) };
};

export const conversationMembers = async (id: string) =>
  prisma.conversationMember.findMany({ where: { conversationId: id }, select: { userId: true } });

export const heartbeat = async (userId: string) => {
  const user = await prisma.user.update({
    where: { id: userId }, data: { lastActiveAt: new Date() },
    select: { lastActiveAt: true },
  });
  const peers = await prisma.conversationMember.findMany({
    where: { conversation: { members: { some: { userId } } }, userId: { not: userId } },
    select: { userId: true }, distinct: ['userId'],
  });
  return { peers: peers.map((peer) => peer.userId), lastActiveAt: user.lastActiveAt };
};
