import { prisma } from '../../../lib/prisma.js';
import type { Prisma } from '@prisma/client';

type Db = Prisma.TransactionClient;
import type { ReportTarget } from '../content.type.js';

export const findUserMember = (tx: Db, id: string) => tx.user.findFirst({ where: { id, role: 'USER' } });

export const findAvailableListing = (tx: Db, id: string) => tx.listing.findFirst({ where: { id, status: 'AVAILABLE' } });

export const findOpenReport = (tx: Db, reporterId: string, targetType: ReportTarget, targetId: string) =>
  tx.violationReport.findFirst({ where: { reporterId, targetType, targetId, status: 'OPEN' } });

export const createReport = (tx: Db, data: { reporterId: string; targetType: ReportTarget; targetId: string; reason: string; evidence: string }) =>
  tx.violationReport.create({ data });

export const findMine = (reporterId: string, skip: number, take: number) =>
  prisma.violationReport.findMany({ where: { reporterId }, skip, take, orderBy: { createdAt: 'desc' } });

/* ---------- Quản trị ---------- */

type ReportStatus = 'OPEN' | 'RESOLVED' | 'DISMISSED';

/** Báo cáo, mới trước, lọc trạng thái */
export function findPage(status: ReportStatus | undefined, skip: number, take: number) {
  const where: Prisma.ViolationReportWhereInput = status ? { status } : {};
  return prisma.$transaction([
    prisma.violationReport.findMany({ where, skip, take, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }] }),
    prisma.violationReport.count({ where }),
  ]);
}

export const findByIdOrThrow = (id: string, db: Db = prisma) => db.violationReport.findUniqueOrThrow({ where: { id } });

/** Đóng báo cáo khi còn OPEN và updatedAt như lúc đọc; trả về số dòng đổi */
export async function closeWhereVersion(tx: Db, id: string, updatedAt: Date,
  data: { status: 'RESOLVED' | 'DISMISSED'; decision: string; resolution: string }) {
  return (await tx.violationReport.updateMany({ where: { id, status: 'OPEN', updatedAt }, data })).count;
}
