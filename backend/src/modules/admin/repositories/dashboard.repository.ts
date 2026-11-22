import { prisma } from '../../../lib/prisma.js';

type Overview = {
  pendingListings: number; pendingEdits: number; openReports: number; activeUsers: number; activeListings: number;
  pendingStores: number; pendingPromotions: number; promotionRevenue: string;
};
type LogWithActor = {
  id: string; actorId: string; action: string; targetType: string; targetId: string; reason: string;
  before: unknown; after: unknown; createdAt: Date; actor: { id: string; fullName: string; email: string } | null;
};

/**
 * Các con số và nhật ký mới nhất trên dashboard: hai câu chạy song song, mỗi câu một vòng tới DB
 * (trước đây 9 câu tranh nhau pool 5 kết nối, rồi thêm một câu tìm tên người xử lý)
 */
export async function countOverview(logCount: number) {
  const [[counts], logs] = await Promise.all([
    prisma.$queryRaw<[Overview]>`
      SELECT
        (SELECT count(*) FROM "Listing" WHERE status = 'PENDING')::int AS "pendingListings",
        (SELECT count(*) FROM "ListingRevision" WHERE status = 'PENDING')::int AS "pendingEdits",
        (SELECT count(*) FROM "ViolationReport" WHERE status = 'OPEN')::int AS "openReports",
        (SELECT count(*) FROM "User" WHERE role = 'USER' AND status = 'ACTIVE')::int AS "activeUsers",
        (SELECT count(*) FROM "Listing" WHERE status = 'AVAILABLE')::int AS "activeListings",
        (SELECT count(*) FROM "StoreOrder" WHERE status = 'PENDING')::int AS "pendingStores",
        (SELECT count(*) FROM "PromotionOrder" WHERE status = 'PENDING')::int AS "pendingPromotions",
        (SELECT coalesce(sum(amount), 0)::text FROM "PromotionOrder" WHERE status = 'CONFIRMED') AS "promotionRevenue"`,
    prisma.$queryRaw<LogWithActor[]>`
      SELECT a.*, CASE WHEN u.id IS NULL THEN NULL
        ELSE json_build_object('id', u.id, 'fullName', u."fullName", 'email', u.email) END AS actor
      FROM "AdminAudit" a LEFT JOIN "User" u ON u.id = a."actorId"
      ORDER BY a."createdAt" DESC, a.id DESC LIMIT ${logCount}`,
  ]);
  return { ...counts, logs };
}

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
