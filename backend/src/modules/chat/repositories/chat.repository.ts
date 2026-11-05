import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';

const userSelect = { id: true, fullName: true, username: true, avatarUrl: true, lastActiveAt: true } satisfies Prisma.UserSelect;
const messageSelect = { id: true, sequence: true, conversationId: true, senderId: true,
  clientId: true, text: true, createdAt: true } satisfies Prisma.MessageSelect;


export const findMember = (conversationId: string, userId: string) =>
  prisma.conversationMember.findUnique({
    where: { conversationId_userId: { conversationId, userId } },
  });

export const findRecipient = (recipientId: string) =>
  prisma.user.findUnique({ where: { id: recipientId }, select: { id: true, status: true } });

export const upsertConversation = (pairKey: string, selfId: string, recipientId: string) =>
  prisma.conversation.upsert({
    where: { pairKey },
    create: { pairKey, members: { create: [{ userId: selfId }, { userId: recipientId }] } },
    update: {},
    select: { id: true, createdAt: true, members: { select: { userId: true } } },
  });

export const findConversation = (id: string) =>
  prisma.conversation.findUnique({
    where: { id },
    select: { id: true, createdAt: true, updatedAt: true,
      members: { select: { userId: true, lastReadSequence: true, user: { select: userSelect } } },
      messages: { orderBy: { sequence: 'desc' }, take: 1, select: messageSelect },
    },
  });

export const findConversations = (selfId: string) =>
  prisma.conversation.findMany({
    where: { members: { some: { userId: selfId } } },
    orderBy: { updatedAt: 'desc' }, take: 100, select: { id: true },
  });

export const findMessages = (id: string, limit: number, before?: number) =>
  prisma.message.findMany({
    where: { conversationId: id, ...(before ? { sequence: { lt: before } } : {}) },
    orderBy: { sequence: 'desc' }, take: limit + 1, select: messageSelect,
  });

export const createMessage = (id: string, selfId: string, clientId: string, text: string) =>
  prisma.$transaction(async (tx) => {
      const created = await tx.message.create({
        data: { conversationId: id, senderId: selfId, clientId, text }, select: messageSelect,
      });
      await tx.conversation.update({ where: { id }, data: { updatedAt: new Date() } });
      await tx.user.update({ where: { id: selfId }, data: { lastActiveAt: new Date() } });
      return created;
    });

export const findMessageByClientId = (selfId: string, clientId: string) =>
  prisma.message.findUnique({
    where: { senderId_clientId: { senderId: selfId, clientId } }, select: messageSelect,
  });

export const findLastMessage = (id: string) =>
  prisma.message.findFirst({ where: { conversationId: id },
    orderBy: { sequence: 'desc' }, select: { sequence: true } });

export const advanceReadSequence = (id: string, selfId: string, sequence: number) =>
  prisma.conversationMember.updateMany({
    where: { conversationId: id, userId: selfId, lastReadSequence: { lt: sequence } },
    data: { lastReadSequence: sequence },
  });

export const findMemberships = (selfId: string) =>
  prisma.conversationMember.findMany({
    where: { userId: selfId }, select: { conversationId: true, lastReadSequence: true },
  });

export const countUnread = (id: string, selfId: string, lastReadSequence: number) =>
  prisma.message.count({ where: {
    conversationId: id, senderId: { not: selfId }, sequence: { gt: lastReadSequence },
  } });

export const findMembers = (id: string) =>
  prisma.conversationMember.findMany({ where: { conversationId: id }, select: { userId: true } });

export const touchPresence = (userId: string) =>
  prisma.user.update({
    where: { id: userId }, data: { lastActiveAt: new Date() },
    select: { lastActiveAt: true },
  });

export const findPeers = (userId: string) =>
  prisma.conversationMember.findMany({
    where: { conversation: { members: { some: { userId } } }, userId: { not: userId } },
    select: { userId: true }, distinct: ['userId'],
  });
