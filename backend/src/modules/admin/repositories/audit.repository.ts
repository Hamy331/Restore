import { prisma } from '../../../lib/prisma.js';

/** Nhật ký quản trị, mới trước */
export const findPage = (skip: number, take: number) =>
  prisma.$transaction([
    prisma.adminAudit.findMany({ skip, take, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }] }),
    prisma.adminAudit.count(),
  ]);
