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

/** Một dòng cho mỗi ngày có doanh thu và mỗi gói, theo lịch Việt Nam. */
export async function getInsights() {
  const [daily, packages, categories, openTickets] = await Promise.all([
    prisma.$queryRaw<{ day: string; packageId: string; amount: string; orders: number }[]>`
      SELECT to_char("decidedAt" + interval '7 hours', 'YYYY-MM-DD') AS day, "packageId",
             sum(amount)::text AS amount, count(*)::int AS orders
      FROM "PromotionOrder"
      WHERE status = 'CONFIRMED' AND "decidedAt" >=
        date_trunc('month', (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')) - interval '11 months 7 hours'
      GROUP BY day, "packageId" ORDER BY day`,
    prisma.promotionPackage.findMany({ select: { id: true, name: true, price: true, active: true }, orderBy: { price: 'asc' } }),
    prisma.category.count({ where: { active: true } }),
    prisma.supportTicket.count({ where: { status: 'OPEN' } }),
  ]);
  return { daily, packages, categories, openTickets, asOf: new Date().toISOString() };
}
