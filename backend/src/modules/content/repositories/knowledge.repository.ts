import { prisma } from '../../../lib/prisma.js';
import type { Prisma } from '@prisma/client';

type Db = Prisma.TransactionClient;

/** Tài liệu đang dùng, đã đánh chỉ mục, chứa đủ mọi từ khóa (tối đa 10 từ) */
export const searchIndexed = (tokens: string[]) =>
  prisma.knowledgeDocument.findMany({
    where: { active: true, indexedText: { not: null }, AND: tokens.map((token) => ({ indexedText: { contains: token } })) },
    take: 5,
    select: { id: true, title: true, content: true, syncedAt: true },
  });

export const createDocument = (tx: Db, data: { title: string; content: string; active: boolean }) =>
  tx.knowledgeDocument.create({ data });
