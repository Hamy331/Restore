import { ListingCondition, Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { listingSelect } from '../listings/index.js';
import { wantedAlertSelect } from './wanted-alert.dto.js';
import { PREVIEW_IMAGES } from './wanted-alert.type.js';

type Db = Prisma.TransactionClient;

/** Tin đang hiển thị: AVAILABLE và chủ tin còn hoạt động */
const visibleListing = { status: 'AVAILABLE', owner: { status: 'ACTIVE' } } as const satisfies Prisma.ListingWhereInput;

/* ---------- Thông báo của người dùng ---------- */

export const countByUser = (userId: string) => prisma.wantedAlert.count({ where: { userId } });

export const findActiveCategory = (id: string) => prisma.category.findFirst({ where: { id, active: true }, select: { id: true } });

export const create = (data: Prisma.WantedAlertUncheckedCreateInput) =>
  prisma.wantedAlert.create({ data, select: wantedAlertSelect });

/** Thông báo của [userId], mới tạo trước; kèm ảnh bìa vài tin khớp gần nhất còn hiển thị */
export const findAllOwned = (userId: string) =>
  prisma.wantedAlert.findMany({
    where: { userId },
    select: { ...wantedAlertSelect, ...previewMatches },
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
  });

export const findOwned = (userId: string, id: string) =>
  prisma.wantedAlert.findFirst({ where: { id, userId }, select: { ...wantedAlertSelect, ...previewMatches } });

const previewMatches = {
  matches: {
    where: { listing: visibleListing },
    select: { listing: { select: { images: true } } },
    orderBy: [{ matchedAt: 'desc' }, { listingId: 'asc' }],
    take: PREVIEW_IMAGES,
  },
} as const satisfies Prisma.WantedAlertSelect;

/** Số tin khớp còn hiển thị và số tin khớp sau seenAt, theo từng thông báo */
export async function countMatches(alertIds: string[]) {
  if (!alertIds.length) return new Map<string, { matchCount: number; newMatchCount: number }>();
  const rows = await prisma.$queryRaw<{ alertId: string; matchCount: number; newMatchCount: number }[]>`
    SELECT m."alertId", COUNT(*)::int AS "matchCount", COUNT(*) FILTER (WHERE m."matchedAt" > a."seenAt")::int AS "newMatchCount"
    FROM "WantedAlertMatch" m
    JOIN "WantedAlert" a ON a.id = m."alertId"
    JOIN "Listing" l ON l.id = m."listingId"
    JOIN "User" u ON u.id = l."ownerId"
    WHERE m."alertId" IN (${Prisma.join(alertIds)}) AND l.status = 'AVAILABLE' AND u.status = 'ACTIVE'
    GROUP BY m."alertId"`;
  return new Map(rows.map(({ alertId, ...counts }) => [alertId, counts]));
}

export const deleteOwned = (userId: string, id: string) => prisma.wantedAlert.deleteMany({ where: { id, userId } });

export const markSeen = (userId: string, id: string, now: Date) =>
  prisma.wantedAlert.updateMany({ where: { id, userId }, data: { seenAt: now } });

/** Một trang tin đã khớp còn hiển thị, khớp gần nhất trước */
export const findMatchesPage = (alertId: string, take: number, skip: number) => {
  const where = { alertId, listing: visibleListing } satisfies Prisma.WantedAlertMatchWhereInput;
  return prisma.$transaction([
    prisma.wantedAlertMatch.findMany({
      where,
      select: { score: true, matchedAt: true, listing: { select: listingSelect } },
      orderBy: [{ matchedAt: 'desc' }, { listingId: 'asc' }],
      take,
      skip,
    }),
    prisma.wantedAlertMatch.count({ where }),
  ]);
};

/* ---------- Xem trước ---------- */

/**
 * Tin đang hiển thị qua được các bộ lọc làm được trong DB (danh mục, tình trạng, khu vực),
 * không gồm tin của chính người xem; mới đăng trước. Giá, kiểu giao dịch và từ khoá lọc ở service.
 */
export const findPreviewCandidates = (
  filters: { categoryId: string | null; conditions: ListingCondition[]; areaCode: string | null; areaLevel: string | null },
  viewerId: string,
  take: number,
) =>
  prisma.listing.findMany({
    where: {
      ...visibleListing,
      ownerId: { not: viewerId },
      ...(filters.categoryId ? { categoryId: filters.categoryId } : {}),
      ...(filters.conditions.length ? { condition: { in: filters.conditions } } : {}),
      ...(filters.areaCode
        ? { location: { path: [filters.areaLevel === 'ward' ? 'wardCode' : 'provinceCode'], equals: filters.areaCode } }
        : {}),
    },
    select: listingSelect,
    orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
    take,
  });

/** Các tin [userId] đã lưu trong [listingIds] */
export async function findFavoriteIds(userId: string, listingIds: string[]) {
  if (!listingIds.length) return new Set<string>();
  const rows = await prisma.listingFavorite.findMany({ where: { userId, listingId: { in: listingIds } }, select: { listingId: true } });
  return new Set(rows.map((row) => row.listingId));
}

/* ---------- Chấm điểm khi duyệt tin ---------- */

export const findListingForMatching = (tx: Db, id: string) =>
  tx.listing.findUnique({
    where: { id },
    select: {
      id: true, ownerId: true, title: true, description: true, price: true, condition: true,
      allowSale: true, allowExchange: true, categoryId: true, location: true,
    },
  });

/** Thông báo của người khác (tài khoản còn hoạt động) có thể khớp danh mục của tin */
export const findCandidateAlerts = (tx: Db, listing: { ownerId: string; categoryId: string | null }) =>
  tx.wantedAlert.findMany({
    where: {
      userId: { not: listing.ownerId },
      user: { status: 'ACTIVE' },
      OR: [{ categoryId: null }, ...(listing.categoryId ? [{ categoryId: listing.categoryId }] : [])],
    },
    select: {
      id: true, keywords: true, matchLevel: true, categoryId: true, minPrice: true, maxPrice: true,
      conditions: true, dealTypes: true, areaCode: true, areaLevel: true, createdAt: true,
    },
  });

/** Ghi các tin khớp (bỏ qua cặp đã có) và cập nhật lastMatchedAt */
export async function saveMatches(tx: Db, listingId: string, matches: { alertId: string; score: number }[], at: Date) {
  if (!matches.length) return;
  await tx.wantedAlertMatch.createMany({
    data: matches.map(({ alertId, score }) => ({ alertId, listingId, score, matchedAt: at })),
    skipDuplicates: true,
  });
  await tx.wantedAlert.updateMany({ where: { id: { in: matches.map((match) => match.alertId) } }, data: { lastMatchedAt: at } });
}
