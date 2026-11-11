import type { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import type { AuditQuery } from '../admin.dto.js';

export function findPage(skip: number, take: number, { q, targetType, action, before }: Omit<AuditQuery, 'page'>) {
  const contains = { contains: q, mode: 'insensitive' as const };
  const where: Prisma.AdminAuditWhereInput = {
    targetType, action,
    ...(before ? { createdAt: { lt: new Date(before) } } : {}),
    ...(q ? { OR: [{ targetId: contains }, { reason: contains }, { actorId: contains }] } : {}),
  };
  return prisma.$transaction([
    prisma.adminAudit.findMany({ where, skip, take, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }] }),
    prisma.adminAudit.count({ where }),
  ]);
}
