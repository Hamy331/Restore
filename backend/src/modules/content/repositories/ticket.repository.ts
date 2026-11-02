import { prisma } from '../../../lib/prisma.js';
import type { Prisma } from '@prisma/client';

type Db = Prisma.TransactionClient;

export const findMine = (userId: string, skip: number, take: number) =>
  prisma.supportTicket.findMany({
    where: { userId },
    skip,
    take,
    orderBy: { updatedAt: 'desc' },
    include: { messages: { orderBy: { createdAt: 'asc' } } },
  });

/** Tạo ticket kèm tin nhắn đầu tiên của người dùng */
export const createWithMessage = (userId: string, subject: string, content: string) =>
  prisma.supportTicket.create({
    data: { userId, subject, messages: { create: { authorId: userId, isAdmin: false, content } } },
  });

export const findOpenOf = (tx: Db, id: string, userId: string) =>
  tx.supportTicket.findFirst({ where: { id, userId, status: 'OPEN' } });

export const touch = (tx: Db, id: string) => tx.supportTicket.update({ where: { id }, data: { updatedAt: new Date() } });

export const createUserMessage = (tx: Db, ticketId: string, authorId: string, content: string) =>
  tx.supportMessage.create({ data: { ticketId, authorId, isAdmin: false, content } });
