import { prisma } from '../../../lib/prisma.js';
import { Prisma } from '@prisma/client';
import type { AdminReportQuery } from '../content.dto.js';
import { reportGroupOrder, reportSqlWhere, reportWhere } from './report-query.js';

type Db = Prisma.TransactionClient;
import type { ReportTarget } from '../content.type.js';

export const findUserMember = (tx: Db, id: string) => tx.user.findFirst({ where: { id, role: 'USER' } });

export const findAvailableListing = (tx: Db, id: string) => tx.listing.findFirst({ where: { id, status: 'AVAILABLE' } });

export const findOpenReport = (tx: Db, reporterId: string, targetType: ReportTarget, targetId: string) =>
  tx.violationReport.findFirst({ where: { reporterId, targetType, targetId, status: 'OPEN' } });

export const createReport = (tx: Db, data: { reporterId: string; targetType: ReportTarget; targetId: string; reason: string; evidence: string; reasonCode?: string; contactPhone?: string; contactEmail?: string }) =>
  tx.violationReport.create({ data });

export const findMine = (reporterId: string, skip: number, take: number) =>
  prisma.violationReport.findMany({ where: { reporterId }, skip, take, orderBy: { createdAt: 'desc' } });

/* ---------- Quản trị ---------- */

/** Báo cáo, mới trước, lọc trạng thái */
export function findPage(query: AdminReportQuery, now: Date) {
  const where = reportWhere(query, now);
  return Promise.all([
    prisma.violationReport.findMany({ where, skip: (query.page - 1) * query.limit, take: query.limit,
      orderBy: [{ createdAt: query.sort === 'newest' ? 'desc' : 'asc' }, { id: 'asc' }] }),
    prisma.violationReport.count({ where }),
  ]);
}

/** Tên và email người báo cáo (ViolationReport chỉ lưu reporterId) */
export const findReporters = (ids: string[]) =>
  prisma.user.findMany({ where: { id: { in: ids } }, select: { id: true, fullName: true, email: true } });

type ReportGroup = {
  targetType: string; targetId: string; reportCount: number; oldestAt: Date; latestAt: Date;
  reasons: { code: string | null; label: string; count: number }[];
};

/** Aggregate before LIMIT: reports for one target cannot be split into different group pages. */
export async function findGroups(query: AdminReportQuery, now: Date) {
  const where = reportSqlWhere(query, now);
  return prisma.$transaction(async tx => {
    const totals = await tx.$queryRaw<{ total: number; reportCount: number }[]>(Prisma.sql`
      SELECT COUNT(*)::int AS total, COALESCE(SUM(n), 0)::int AS "reportCount" FROM (
        SELECT COUNT(*) AS n FROM "ViolationReport" WHERE ${where} GROUP BY "targetType", "targetId"
      ) g`);
    const items = await tx.$queryRaw<ReportGroup[]>(Prisma.sql`
      WITH matching AS (
        SELECT "targetType", "targetId", "reasonCode", reason, "createdAt"
        FROM "ViolationReport" WHERE ${where}
      ), grouped AS (
        SELECT "targetType", "targetId", COUNT(*)::int AS "reportCount",
          MIN("createdAt") AS "oldestAt", MAX("createdAt") AS "latestAt"
        FROM matching GROUP BY "targetType", "targetId"
      ), paged AS (
        SELECT * FROM grouped ORDER BY ${reportGroupOrder(query.sort)}
        LIMIT ${query.limit} OFFSET ${(query.page - 1) * query.limit}
      ), reason_counts AS (
        SELECT m."targetType", m."targetId", m."reasonCode", m.reason, COUNT(*)::int AS n
        FROM matching m JOIN paged p USING ("targetType", "targetId")
        GROUP BY m."targetType", m."targetId", m."reasonCode", m.reason
      ), summaries AS (
        SELECT "targetType", "targetId", jsonb_agg(jsonb_build_object(
          'code', "reasonCode", 'label', reason, 'count', n) ORDER BY n DESC, reason, "reasonCode") AS reasons
        FROM reason_counts GROUP BY "targetType", "targetId"
      )
      SELECT p.*, s.reasons FROM paged p JOIN summaries s USING ("targetType", "targetId")
      ORDER BY ${reportGroupOrder(query.sort)}`);
    const listings = await tx.listing.findMany({
      where: { id: { in: items.filter(x => x.targetType === 'LISTING').map(x => x.targetId) } },
      select: { id: true, title: true, status: true },
    });
    const lookup = new Map(listings.map(item => [item.id, item]));
    return { ...totals[0], items: items.map(item => ({ ...item, listing: item.targetType === 'LISTING' ? lookup.get(item.targetId) ?? null : null })) };
  }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
}

export const listReasons = (all: boolean) => prisma.reportReason.findMany({
  where: all ? {} : { active: true }, orderBy: [{ sortOrder: 'asc' }, { code: 'asc' }],
});
export const findReason = (tx: Db, code: string) => tx.reportReason.findUnique({ where: { code } });

export const findByIdOrThrow = (id: string, db: Db = prisma) => db.violationReport.findUniqueOrThrow({ where: { id } });

/** Đóng báo cáo khi còn OPEN và updatedAt như lúc đọc; trả về số dòng đổi */
export async function closeWhereVersion(tx: Db, id: string, updatedAt: Date,
  data: { status: 'RESOLVED' | 'DISMISSED'; decision: string; resolution: string }) {
  return (await tx.violationReport.updateMany({ where: { id, status: 'OPEN', updatedAt }, data })).count;
}
