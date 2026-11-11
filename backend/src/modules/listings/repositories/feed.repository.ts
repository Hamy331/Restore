import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { listingSelect } from '../listing.dto.js';
import type { ListingFilters } from '../listing.type.js';
import { visible } from './listing.repository.js';

export type RankedRow = { id: string; distanceKm: number | null; isFeatured: boolean };

// ponytail: distance uses the public ward center; add PostGIS/indexes when the catalog needs it.
/**
 * SQL xếp hạng tin: gần nhất (nearby), đẩy FEATURED, gói cửa hàng cùng danh mục, BUMP, thời gian.
 */
function rankedQuery(filters: ListingFilters, now: Date) {
 const distance = !filters.nearby ? Prisma.sql`NULL::double precision` : Prisma.sql`
 CASE WHEN l.location #>> '{ward,center,latitude}' IS NULL OR l.location #>> '{ward,center,longitude}' IS NULL THEN NULL
 ELSE 6371*acos(GREATEST(-1,LEAST(1,
  sin(radians(${filters.nearby.latitude}::double precision))*sin(radians((l.location #>> '{ward,center,latitude}')::double precision))+
  cos(radians(${filters.nearby.latitude}::double precision))*cos(radians((l.location #>> '{ward,center,latitude}')::double precision))*
  cos(radians((l.location #>> '{ward,center,longitude}')::double precision-${filters.nearby.longitude}::double precision))))) END`;
 return Prisma.sql`
        SELECT l.id, ${distance} AS "distanceKm",
          COALESCE(boosted."featuredPriority", 0) > 0 AS "isFeatured"
        FROM "Listing" l
        JOIN "User" u ON u.id = l."ownerId" AND u.status = 'ACTIVE'
        LEFT JOIN "StoreSubscription" ss ON ss."userId" = l."ownerId"
          AND ss."startsAt" <= ${now} AND ss."endsAt" > ${now}
        LEFT JOIN "StorePackage" sp ON sp.id = ss."packageId"
        LEFT JOIN LATERAL (
          SELECT
            MAX(CASE WHEN pp.kind = 'FEATURED' AND p."endsAt" > ${now}
              THEN pp.priority END) AS "featuredPriority",
            MAX(CASE WHEN pp.kind = 'BUMP' AND p."startsAt" <= ${now}
              THEN p."startsAt" + LEAST(pp."durationDays" - 1,
                FLOOR(EXTRACT(EPOCH FROM (${now} - p."startsAt")) / 86400)::integer)
                * INTERVAL '1 day' END) AS "bumpedAt"
          FROM "Promotion" p
          JOIN "PromotionPackage" pp ON pp.id = p."packageId"
          WHERE p."listingId" = l.id AND p."startsAt" <= ${now}
        ) boosted ON TRUE
        WHERE l.status = 'AVAILABLE'
          AND (${filters.allowExchange ?? false} = false OR l."allowExchange"=true)
          AND (${filters.nearby?.radius ?? null}::double precision IS NULL OR ${distance} <= ${filters.nearby?.radius ?? null})
          AND (${filters.q} = '' OR POSITION(LOWER(${filters.q}) IN LOWER(l.title)) > 0)
          AND (${filters.categoryId} = '' OR l."categoryId" = ${filters.categoryId})
          AND (${filters.condition}::text IS NULL OR l.condition = ${filters.condition}::"ListingCondition")
          AND (${filters.minPrice}::numeric IS NULL OR l.price >= ${filters.minPrice}::numeric)
          AND (${filters.maxPrice}::numeric IS NULL OR l.price <= ${filters.maxPrice}::numeric)
        ORDER BY ${filters.nearby ? Prisma.sql`${distance} ASC,` : Prisma.empty} COALESCE(boosted."featuredPriority", 0) DESC,
          CASE WHEN ss."categoryId" = l."categoryId" THEN COALESCE(sp."priorityLevel", 0) ELSE 0 END DESC,
          GREATEST(COALESCE(l."publishedAt", l."createdAt"),
            COALESCE(boosted."bumpedAt", l."createdAt")) DESC,
          COALESCE(l."publishedAt", l."createdAt") DESC, l.id DESC`;
}

/**
 * Lấy một trang id tin đã xếp hạng (đẩy tin, gói cửa hàng, khoảng cách, thời gian)
 * cùng tổng số tin khớp bộ lọc.
 */
export async function findRankedPage(filters: ListingFilters, now: Date, limit: number, skip: number) {
  const query = rankedQuery(filters, now);
  const [rows, totals] = await prisma.$transaction([
    prisma.$queryRaw<RankedRow[]>`${query} LIMIT ${limit} OFFSET ${skip}`,
    prisma.$queryRaw<{ n: number }[]>`SELECT COUNT(*)::int AS n FROM (${query}) ranked`,
  ]);
  return { rows, totalItems: totals[0]?.n ?? 0 };
}

export const findVisibleByIds = (ids: string[]) =>
  ids.length ? prisma.listing.findMany({ where: { ...visible, id: { in: ids } }, select: listingSelect }) : Promise.resolve([]);

/** Tin đang có gói đẩy FEATURED còn hiệu lực (trong [categoryId] nếu có), mới nhất trước */
export const findFeatured = (now: Date, limit: number, categoryId?: string, skip = 0) =>
  prisma.listing.findMany({
    where: {
      ...visible,
      ...(categoryId ? { categoryId } : {}),
      promotions: { some: { startsAt: { lte: now }, endsAt: { gt: now }, package: { kind: 'FEATURED' } } },
    },
    select: listingSelect,
    take: limit,
    skip,
    orderBy: [{ publishedAt: 'desc' }, { id: 'desc' }],
  });

/** Trong [listingIds], những tin mà [userId] đã lưu */
export async function findFavoriteIds(userId: string | undefined, listingIds: string[]) {
  if (!userId || !listingIds.length) return new Set<string>();
  const rows = await prisma.listingFavorite.findMany({
    where: { userId, listingId: { in: listingIds } },
    select: { listingId: true },
  });
  return new Set(rows.map((row) => row.listingId));
}
