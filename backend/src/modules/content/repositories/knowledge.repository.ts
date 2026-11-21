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

/* ---------- Quản trị ---------- */

type KnowledgeData = { title: string; content: string; active: boolean; indexedText: string | null; syncedAt: Date | null };

/** Mọi tài liệu, cập nhật gần nhất trước; không kèm nội dung (tối đa 100 KB mỗi tài liệu) */
export const findPage = (skip: number, take: number) =>
  prisma.$transaction([
    prisma.knowledgeDocument.findMany({
      skip, take, orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
      select: {
        id: true, title: true, active: true, syncedAt: true, updatedAt: true,
        aiIndex: { select: { status: true, model: true, indexedAt: true, documentVersion: true, errorCode: true } },
      },
    }),
    prisma.knowledgeDocument.count(),
  ]);

/** Một tài liệu kèm nội dung để admin sửa; không có thì 404 */
export const findForAdmin = (id: string) => prisma.knowledgeDocument.findUniqueOrThrow({
  where: { id }, select: { id: true, title: true, content: true, active: true, syncedAt: true, updatedAt: true },
});

export const findByIdOrThrow = (tx: Db, id: string) => tx.knowledgeDocument.findUniqueOrThrow({ where: { id } });

export const create = (tx: Db, data: KnowledgeData) => tx.knowledgeDocument.create({ data });

/** Sửa khi updatedAt vẫn như lúc đọc; trả về số dòng đổi */
export async function updateWhereVersion(tx: Db, id: string, updatedAt: Date, data: Partial<KnowledgeData>) {
  return (await tx.knowledgeDocument.updateMany({ where: { id, updatedAt }, data })).count;
}

export async function deleteWhereVersion(tx: Db, id: string, updatedAt: Date) {
  return (await tx.knowledgeDocument.deleteMany({ where: { id, updatedAt } })).count;
}

/** Danh mục đang dùng (để đồng bộ vào tài liệu hệ thống) */
export const findActiveCategories = (tx: Db) =>
  tx.category.findMany({ where: { active: true }, orderBy: { id: 'asc' }, select: { id: true, name: true, metadata: true } });

export const upsertById = (tx: Db, id: string, data: KnowledgeData & { indexedText: string; syncedAt: Date }) =>
  tx.knowledgeDocument.upsert({ where: { id }, create: { id, ...data }, update: data });
