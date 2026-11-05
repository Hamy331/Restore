import { Prisma } from '@prisma/client';
import * as repository from '../repositories/chat.repository.js';
import { AppError } from '../../../common/errors/app-error.js';

import { parseId } from '../chat.validator.js';

const memberOrThrow = async (conversationId: string, userId: string) => {
  const member = await repository.findMember(conversationId, userId);
  if (!member) throw new AppError(404, 'CONVERSATION_NOT_FOUND', 'Không tìm thấy cuộc trò chuyện.');
  return member;
};

const online = (lastActiveAt: Date | null) =>
  !!lastActiveAt && Date.now() - lastActiveAt.getTime() < 2 * 60 * 1000;

export const startConversation = async (selfId: string, body: unknown) => {
  const input = (body && typeof body === 'object') ? body as Record<string, unknown> : {};
  const recipientId = parseId(input.recipientId, 'recipientId');
  if (recipientId === selfId) throw new AppError(422, 'SELF_CHAT', 'Không thể nhắn tin cho chính mình.');
  const recipient = await repository.findRecipient(recipientId);
  if (!recipient || recipient.status !== 'ACTIVE') {
    throw new AppError(404, 'USER_NOT_FOUND', 'Không tìm thấy người nhận.');
  }
  const pairKey = [selfId, recipientId].sort().join(':');
  const conversation = await repository.upsertConversation(pairKey, selfId, recipientId);
  return conversation;
};

export const getConversation = async (selfId: string, id: string) => {
  await memberOrThrow(id, selfId);
  const conversation = await repository.findConversation(id);
  if (!conversation) throw new AppError(404, 'CONVERSATION_NOT_FOUND', 'Không tìm thấy cuộc trò chuyện.');
  const self = conversation.members.find((member) => member.userId === selfId)!;
  const other = conversation.members.find((member) => member.userId !== selfId)?.user;
  const unreadCount = await repository.countUnread(id, selfId, self.lastReadSequence);
  return { id: conversation.id, createdAt: conversation.createdAt, updatedAt: conversation.updatedAt,
    otherUser: other ? { ...other, isOnline: online(other.lastActiveAt) } : null,
    lastMessage: conversation.messages[0] ?? null, unreadCount };
};

export const listConversations = async (selfId: string) => {
  const rows = await repository.findConversations(selfId);
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
  const rows = await repository.findMessages(id, limit, before);
  return { items: rows.slice(0, limit).reverse(), hasMore: rows.length > limit,
    nextBefore: rows.length > limit ? rows[limit - 1].sequence : null };
};

export const sendMessage = async (selfId: string, id: string, body: unknown) => {
  await memberOrThrow(id, selfId);
  const input = (body && typeof body === 'object') ? body as Record<string, unknown> : {};
  const clientId = parseId(input.clientId, 'clientId');
  const text = typeof input.text === 'string' ? input.text.trim() : '';
  if (!text || text.length > 2000) throw new AppError(422, 'INVALID_MESSAGE', 'Tin nhắn phải có 1–2000 ký tự.', 'text');
  const existing = await repository.findMessageByClientId(selfId, clientId);
  if (existing) {
    if (existing.conversationId !== id || existing.text !== text) {
      throw new AppError(409, 'CLIENT_ID_REUSED', 'Mã tin nhắn đã được sử dụng.');
    }
    return { message: existing, created: false };
  }
  try {
    const message = await repository.createMessage(id, selfId, clientId, text);
    return { message, created: true };
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      const duplicate = await repository.findMessageByClientId(selfId, clientId);
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
  const latest = await repository.findLastMessage(id);
  if (latest) await repository.advanceReadSequence(id, selfId, latest.sequence);
  return { lastReadSequence: latest?.sequence ?? 0 };
};

export const unreadCount = async (selfId: string) => {
  const memberships = await repository.findMemberships(selfId);
  const counts = await Promise.all(memberships.map((member) => repository.countUnread(member.conversationId, selfId, member.lastReadSequence)));
  return { count: counts.reduce((sum, count) => sum + count, 0) };
};

export const conversationMembers = async (id: string) =>
  repository.findMembers(id);

export const heartbeat = async (userId: string) => {
  const user = await repository.touchPresence(userId);
  const peers = await repository.findPeers(userId);
  return { peers: peers.map((peer) => peer.userId), lastActiveAt: user.lastActiveAt };
};
