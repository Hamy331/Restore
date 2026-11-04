import { prisma } from '../../../lib/prisma.js';

/** Các con số trên dashboard, đọc song song */
export const countOverview = (logCount: number) => Promise.all([
  prisma.listing.count({ where: { status: 'PENDING' } }),
  prisma.violationReport.count({ where: { status: 'OPEN' } }),
  prisma.user.count({ where: { role: 'USER', status: 'ACTIVE' } }),
  prisma.listing.count({ where: { status: 'AVAILABLE' } }),
  prisma.storeOrder.count({ where: { status: 'PENDING' } }),
  prisma.promotionOrder.count({ where: { status: 'PENDING' } }),
  prisma.promotionOrder.aggregate({ where: { status: 'CONFIRMED' }, _sum: { amount: true } }),
  prisma.adminAudit.findMany({ take: logCount, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }] }),
]);
