import { ListingStatus, Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { findRunningPromotionsOf } from '../../commerce/index.js';

/** Số ngày được chọn trên trang Thống kê */
export const INSIGHT_RANGES = [7, 30] as const;
export type InsightRange = (typeof INSIGHT_RANGES)[number];

/** Tin hết hạn trong số ngày này được nhắc gia hạn */
const EXPIRING_DAYS = 7;
const TOP_LIMIT = 5;
const VN_OFFSET_MS = 7 * 3_600_000;
const DAY_MS = 86_400_000;

/** Ngày theo giờ Việt Nam dạng YYYY-MM-DD, lùi [back] ngày */
const vnDay = (now: Date, back = 0) => new Date(now.getTime() + VN_OFFSET_MS - back * DAY_MS).toISOString().slice(0, 10);

type DayRow = { day: string; count: number };

const viewsByDay = (ownerId: string, from: string) => prisma.$queryRaw<DayRow[]>`
  SELECT to_char(d."day", 'YYYY-MM-DD') AS day, SUM(d."views")::int AS count
  FROM "ListingViewDaily" d JOIN "Listing" l ON l.id = d."listingId"
  WHERE l."ownerId" = ${ownerId} AND d."day" >= ${from}::date
  GROUP BY d."day"`;

const savesByDay = (ownerId: string, from: string) => prisma.$queryRaw<DayRow[]>`
  SELECT to_char((f."createdAt" AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh')::date, 'YYYY-MM-DD') AS day,
    COUNT(*)::int AS count
  FROM "ListingFavorite" f JOIN "Listing" l ON l.id = f."listingId"
  WHERE l."ownerId" = ${ownerId} AND f."userId" <> ${ownerId}
    AND (f."createdAt" AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh')::date >= ${from}::date
  GROUP BY 1`;

const perListing = (ownerId: string, from: string) => prisma.$queryRaw<{ id: string; views: number; saves: number }[]>`
  SELECT l.id,
    COALESCE((SELECT SUM(d."views") FROM "ListingViewDaily" d WHERE d."listingId" = l.id AND d."day" >= ${from}::date), 0)::int AS views,
    (SELECT COUNT(*) FROM "ListingFavorite" f WHERE f."listingId" = l.id AND f."userId" <> ${ownerId}
      AND (f."createdAt" AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Ho_Chi_Minh')::date >= ${from}::date)::int AS saves
  FROM "Listing" l
  WHERE l."ownerId" = ${ownerId} AND l.status = 'AVAILABLE'`;

/** Số cuộc trò chuyện có người khác nhắn cho mình, theo kỳ hiện tại và kỳ trước */
const chatsSince = (userId: string, from: Date, to?: Date) => prisma.message.findMany({
  where: { senderId: { not: userId }, createdAt: { gte: from, ...(to && { lt: to }) },
    conversation: { members: { some: { userId } } } },
  distinct: ['conversationId'], select: { conversationId: true },
}).then((rows) => rows.length);

const sumBetween = (rows: DayRow[], from: string, to?: string) =>
  rows.filter((r) => r.day >= from && (!to || r.day < to)).reduce((sum, r) => sum + r.count, 0);

/**
 * Trang Thống kê của người bán trong [days] ngày gần nhất (giờ Việt Nam, gồm hôm nay):
 * lượt xem, lượt lưu tin, người nhắn tin (kèm kỳ trước để so sánh), lượt xem / lưu theo ngày,
 * số tin theo trạng thái, top tin nhiều lượt xem, số tin sắp hết hạn, lượt quảng bá trong kỳ.
 */
export async function getInsights(ownerId: string, days: InsightRange) {
  const now = new Date();
  const from = vnDay(now, days - 1);
  const prevFrom = vnDay(now, days * 2 - 1);
  // 0h giờ Việt Nam của ngày bắt đầu, dùng cho các bảng lưu thời điểm
  const fromAt = new Date(`${from}T00:00:00+07:00`);
  const prevFromAt = new Date(`${prevFrom}T00:00:00+07:00`);
  const [views, saves, byListing, statuses, chats, chatsPrev, promotions, expiring] = await Promise.all([
    viewsByDay(ownerId, prevFrom), savesByDay(ownerId, prevFrom), perListing(ownerId, from),
    prisma.listing.groupBy({ by: ['status'], where: { ownerId }, _count: { _all: true } }),
    chatsSince(ownerId, fromAt), chatsSince(ownerId, prevFromAt, fromAt),
    prisma.promotion.findMany({ where: { userId: ownerId, startsAt: { gte: fromAt } }, select: { package: { select: { kind: true } } } }),
    prisma.listing.count({ where: { ownerId, status: ListingStatus.AVAILABLE, autoExtend: false,
      expiresAt: { gt: now, lte: new Date(now.getTime() + EXPIRING_DAYS * DAY_MS) } } }),
  ]);
  const count = (status: ListingStatus) => statuses.find((s) => s.status === status)?._count._all ?? 0;
  const viewMap = new Map(views.map((r) => [r.day, r.count]));
  const saveMap = new Map(saves.map((r) => [r.day, r.count]));
  const daily = Array.from({ length: days }, (_, i) => {
    const day = vnDay(now, days - 1 - i);
    return { date: day, views: viewMap.get(day) ?? 0, saves: saveMap.get(day) ?? 0 };
  });

  const ranked = [...byListing].sort((a, b) => b.views - a.views || b.saves - a.saves).slice(0, TOP_LIMIT);
  const ids = ranked.map((r) => r.id);
  const [details, running] = ids.length
    ? await Promise.all([
      prisma.listing.findMany({ where: { id: { in: ids } },
        select: { id: true, title: true, price: true, images: true, viewCount: true, expiresAt: true } }),
      findRunningPromotionsOf(prisma as unknown as Prisma.TransactionClient, ids, now),
    ])
    : [[], []];
  const until = (id: string, kind: 'BUMP' | 'FEATURED') => running
    .filter((p) => p.listingId === id && p.package.kind === kind)
    .reduce<Date | null>((max, p) => (!max || p.endsAt > max ? p.endsAt : max), null);
  const top = ranked.flatMap((r) => {
    const l = details.find((d) => d.id === r.id);
    return l ? [{ id: l.id, title: l.title, price: l.price.toString(), image: l.images[0] ?? null,
      views: r.views, saves: r.saves, totalViews: l.viewCount, expiresAt: l.expiresAt,
      bumpUntil: until(l.id, 'BUMP'), featuredUntil: until(l.id, 'FEATURED') }] : [];
  });

  return {
    days, from, to: vnDay(now),
    totals: {
      views: sumBetween(views, from), viewsPrev: sumBetween(views, prevFrom, from),
      saves: sumBetween(saves, from), savesPrev: sumBetween(saves, prevFrom, from),
      chats, chatsPrev,
    },
    listings: { active: count(ListingStatus.AVAILABLE), pending: count(ListingStatus.PENDING),
      hidden: count(ListingStatus.HIDDEN), sold: count(ListingStatus.SOLD) + count(ListingStatus.EXCHANGED),
      expiringSoon: expiring },
    promotions: { boosts: promotions.filter((p) => p.package.kind === 'BUMP').length,
      features: promotions.filter((p) => p.package.kind === 'FEATURED').length },
    daily, top,
  };
}
