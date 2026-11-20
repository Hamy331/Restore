import { Prisma } from '@prisma/client';
import type { AdminReportQuery } from '../content.dto.js';

export function reportWhere(query: AdminReportQuery, now: Date): Prisma.ViolationReportWhereInput {
  return {
    ...(query.status && { status: query.status }),
    ...(query.targetType && { targetType: query.targetType }),
    ...(query.targetId && { targetId: query.targetId }),
    ...(query.reasonCode && { reasonCode: query.reasonCode }),
    ...(query.uncategorized && { reasonCode: null }),
    createdAt: {
      lte: new Date(now.getTime() - (query.minWaitHours ?? 0) * 3_600_000),
      ...(query.maxWaitHours !== undefined && { gte: new Date(now.getTime() - query.maxWaitHours * 3_600_000) }),
    },
  };
}

/** All values are bound parameters. This is shared by group totals, page rows and reason counts. */
export function reportSqlWhere(query: AdminReportQuery, now: Date) {
  const where = reportWhere(query, now);
  const parts: Prisma.Sql[] = [Prisma.sql`TRUE`];
  if (query.status) parts.push(Prisma.sql`"status" = ${query.status}::"ReportStatus"`);
  if (query.targetType) parts.push(Prisma.sql`"targetType" = ${query.targetType}`);
  if (query.targetId) parts.push(Prisma.sql`"targetId" = ${query.targetId}`);
  if (query.uncategorized) parts.push(Prisma.sql`"reasonCode" IS NULL`);
  else if (query.reasonCode) parts.push(Prisma.sql`"reasonCode" = ${query.reasonCode}`);
  const dates = where.createdAt as Prisma.DateTimeFilter | undefined;
  if (dates?.lte) parts.push(Prisma.sql`"createdAt" <= ${dates.lte}`);
  if (dates?.gte) parts.push(Prisma.sql`"createdAt" >= ${dates.gte}`);
  return Prisma.join(parts, ' AND ');
}

export function reportGroupOrder(sort: AdminReportQuery['sort']) {
  const primary = sort === 'most_reports' ? Prisma.sql`"reportCount" DESC, "oldestAt" ASC`
    : sort === 'newest' ? Prisma.sql`"latestAt" DESC` : Prisma.sql`"oldestAt" ASC`;
  return Prisma.sql`${primary}, "targetType" ASC, "targetId" ASC`;
}
