import type { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import type { AuditQuery } from '../admin.dto.js';

export async function findPage(skip: number, take: number, { q, targetType, targetId, action, before }: Omit<AuditQuery, 'page'>) {
  const contains = { contains: q, mode: 'insensitive' as const };
  // ponytail: tối đa 50 người xử lý khớp tên/email; đủ cho số admin hiện có
  const actorIds = q
    ? (await prisma.user.findMany({ where: { OR: [{ fullName: contains }, { email: contains }] }, select: { id: true }, take: 50 })).map((u) => u.id)
    : [];
  const where: Prisma.AdminAuditWhereInput = {
    targetType, targetId, action,
    ...(before ? { createdAt: { lt: new Date(before) } } : {}),
    ...(q ? { OR: [{ targetId: contains }, { reason: contains }, { actorId: contains }, { actorId: { in: actorIds } }] } : {}),
  };
  return Promise.all([
    prisma.adminAudit.findMany({ where, skip, take, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }] }),
    prisma.adminAudit.count({ where }),
  ]);
}

/** Tên và email người xử lý (AdminAudit chỉ lưu actorId) */
export const findActors = (ids: string[]) =>
  prisma.user.findMany({ where: { id: { in: ids } }, select: { id: true, fullName: true, email: true } });
