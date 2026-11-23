import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import type { AuditQuery } from '../admin.dto.js';

export type LogWithActor = {
  id: string; actorId: string; action: string; targetType: string; targetId: string; reason: string;
  before: unknown; after: unknown; createdAt: Date; actor: { id: string; fullName: string; email: string } | null;
};

/** Dòng nhật ký kèm tên, email người xử lý (AdminAudit chỉ lưu actorId); dùng với `FROM "AdminAudit" a LEFT JOIN "User" u` */
export const LOG_WITH_ACTOR = Prisma.sql`a.*, CASE WHEN u.id IS NULL THEN NULL
  ELSE json_build_object('id', u.id, 'fullName', u."fullName", 'email', u.email) END AS actor`;

/** Một trang nhật ký và tổng số dòng: hai câu chạy song song, người xử lý nối ngay trong câu (tìm được cả theo tên, email của họ) */
export async function findPage(skip: number, take: number, { q, targetType, targetId, action, before }: Omit<AuditQuery, 'page'>) {
  const like = q && `%${q.replace(/[\\%_]/g, '\\$&')}%`;
  const conditions = [
    targetType && Prisma.sql`a."targetType" = ${targetType}`,
    targetId && Prisma.sql`a."targetId" = ${targetId}`,
    action && Prisma.sql`a.action = ${action}`,
    // createdAt lưu giờ UTC không kèm múi giờ
    before && Prisma.sql`a."createdAt" < (${before}::timestamptz AT TIME ZONE 'UTC')`,
    like && Prisma.sql`(a."targetId" ILIKE ${like} OR a.reason ILIKE ${like} OR a."actorId" ILIKE ${like}
      OR u."fullName" ILIKE ${like} OR u.email ILIKE ${like})`,
  ].filter((condition): condition is Prisma.Sql => !!condition);
  const from = Prisma.sql`FROM "AdminAudit" a LEFT JOIN "User" u ON u.id = a."actorId"
    ${conditions.length ? Prisma.sql`WHERE ${Prisma.join(conditions, ' AND ')}` : Prisma.empty}`;
  const [logs, [{ total }]] = await Promise.all([
    prisma.$queryRaw<LogWithActor[]>`SELECT ${LOG_WITH_ACTOR} ${from} ORDER BY a."createdAt" DESC, a.id DESC LIMIT ${take} OFFSET ${skip}`,
    prisma.$queryRaw<[{ total: number }]>`SELECT count(*)::int AS total ${from}`,
  ]);
  return [logs, total] as const;
}
