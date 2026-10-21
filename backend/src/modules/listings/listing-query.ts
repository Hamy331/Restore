import { Prisma } from '@prisma/client';
import type { listingFilters } from './listing.route.js';
// ponytail: distance uses the public ward center; add PostGIS/indexes when the catalog needs it.
export function listingQuery(filters: ReturnType<typeof listingFilters>, now: Date) {
 const distance = !filters.nearby ? Prisma.sql`NULL::double precision` : Prisma.sql`
 CASE WHEN l.location #>> '{ward,center,latitude}' IS NULL OR l.location #>> '{ward,center,longitude}' IS NULL THEN NULL
 ELSE 6371*acos(GREATEST(-1,LEAST(1,
  sin(radians(${filters.nearby.latitude}::double precision))*sin(radians((l.location #>> '{ward,center,latitude}')::double precision))+
  cos(radians(${filters.nearby.latitude}::double precision))*cos(radians((l.location #>> '{ward,center,latitude}')::double precision))*
  cos(radians((l.location #>> '{ward,center,longitude}')::double precision-${filters.nearby.longitude}::double precision))))) END`;
 return Prisma.sql`
        SELECT l.id, ${distance} AS "distanceKm"
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
