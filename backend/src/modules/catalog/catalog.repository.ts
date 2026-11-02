import { ListingCondition, Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';

type Db = Prisma.TransactionClient;

/** Mọi danh mục và tình trạng (kể cả đã tắt) */
export const findAll = () => Promise.all([
  prisma.category.findMany({ orderBy: { name: 'asc' } }),
  prisma.conditionPolicy.findMany({ orderBy: { condition: 'asc' } }),
]);

/** Danh mục trùng tên (không phân biệt hoa thường), bỏ qua [exceptId] */
export const findByName = (tx: Db, name: string, exceptId?: string) =>
  tx.category.findFirst({ where: { ...(exceptId ? { id: { not: exceptId } } : {}), name: { equals: name, mode: 'insensitive' } } });

export const createCategory = (tx: Db, data: Prisma.CategoryCreateInput) => tx.category.create({ data });

export const findCategoryOrThrow = (tx: Db, id: string) => tx.category.findUniqueOrThrow({ where: { id } });

export const updateCategory = (tx: Db, id: string, data: Prisma.CategoryUpdateInput) => tx.category.update({ where: { id }, data });

export const upsertCondition = (tx: Db, condition: ListingCondition, data: { name: string; active: boolean }) =>
  tx.conditionPolicy.upsert({ where: { condition }, create: { condition, ...data }, update: data });
