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
