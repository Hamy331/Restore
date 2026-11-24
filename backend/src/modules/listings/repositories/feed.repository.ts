import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { listingSelect } from '../listing.dto.js';
import type { ListingFilters } from '../listing.type.js';
import type { AttributeFilter, DealType, SearchSort, SellerKind } from '../listing.validator.js';
import { visible } from './listing.repository.js';
import { accented, allTermsIn, folded, searchTerms, type SearchTerm } from './keyword-match.js';

/** Bộ lọc thêm của trang Shop uy tín */
type ShopFilters = { verifiedShop?: boolean };
/** freeOnly: chỉ đồ cho tặng; followerId: chỉ tin của người bán mà người này theo dõi */
type FeedOptions = ListingFilters & ShopFilters & {
  ownerId?: string; chronological?: boolean; interestUserId?: string; freeOnly?: boolean; followerId?: string;
};

export type RankedRow = { id: string; distanceKm: number | null; isFeatured: boolean };

// ponytail: distance uses the public ward center; add PostGIS/indexes when the catalog needs it.
/**
 * SQL xếp hạng tin: gần nhất (nearby), đẩy FEATURED, gói cửa hàng cùng danh mục, BUMP, thời gian.
 */
function rankedQuery(filters: FeedOptions, now: Date, sort?: SearchSort) {
 const distance = !filters.nearby ? Prisma.sql`NULL::double precision` : Prisma.sql`
 CASE WHEN l.location #>> '{ward,center,latitude}' IS NULL OR l.location #>> '{ward,center,longitude}' IS NULL THEN NULL
 ELSE 6371*acos(GREATEST(-1,LEAST(1,
  sin(radians(${filters.nearby.latitude}::double precision))*sin(radians((l.location #>> '{ward,center,latitude}')::double precision))+
  cos(radians(${filters.nearby.latitude}::double precision))*cos(radians((l.location #>> '{ward,center,latitude}')::double precision))*
  cos(radians((l.location #>> '{ward,center,longitude}')::double precision-${filters.nearby.longitude}::double precision))))) END`;
 return Prisma.sql`
        SELECT l.id, ${distance} AS "distanceKm",
          COALESCE(boosted."featuredPriority", 0) > 0 AS "isFeatured",
          -- Tổng số tin khớp, đếm trước LIMIT nên không cần câu COUNT riêng
          COUNT(*) OVER()::int AS "totalItems"
        FROM "Listing" l
        JOIN "User" u ON u.id = l."ownerId" AND u.status = 'ACTIVE'
        LEFT JOIN "Category" c ON c.id = l."categoryId"
        ${filters.words.length ? Prisma.sql`CROSS JOIN LATERAL (SELECT
          ${folded(searchSource)} AS f, ${accented(searchSource)} AS a,
          ${folded(Prisma.sql`l.title`)} AS tf, ${accented(Prisma.sql`l.title`)} AS ta,
          ${folded(categoryNames)} AS cf, ${accented(categoryNames)} AS ca) search` : Prisma.empty}
        ${filters.interestUserId ? Prisma.sql`LEFT JOIN (
          SELECT saved."categoryId", COUNT(*) AS affinity
          FROM "ListingFavorite" f JOIN "Listing" saved ON saved.id = f."listingId"
          WHERE f."userId" = ${filters.interestUserId} GROUP BY saved."categoryId"
        ) interest ON interest."categoryId" = l."categoryId"` : Prisma.empty}
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
          ${filters.ownerId ? Prisma.sql`AND l."ownerId" = ${filters.ownerId}` : Prisma.empty}
          AND (${filters.allowExchange ?? false} = false OR l."allowExchange"=true)
          AND (${filters.verifiedShop ?? false} = false OR EXISTS (
            SELECT 1 FROM "Shop" s WHERE s."ownerId" = l."ownerId" AND s."verificationType" IS NOT NULL))
          AND (${filters.freeOnly ?? false} = false OR l."isFree" = true)
          ${filters.followerId !== undefined ? Prisma.sql`AND EXISTS (SELECT 1 FROM "UserFollow" uf
            WHERE uf."followerId" = ${filters.followerId} AND uf."followingId" = l."ownerId")` : Prisma.empty}
          AND (${filters.nearby?.radius ?? null}::double precision IS NULL OR ${distance} <= ${filters.nearby?.radius ?? null})
          AND ${wordsMatch(searchTerms(filters))}
          AND (${filters.categoryId} = '' OR l."categoryId" = ${filters.categoryId})
          AND (${filters.subcategoryId} = '' OR l."subcategoryId" = ${filters.subcategoryId})
          AND ${attributeMatch(filters.attributeFilters)}
          AND ${sellerMatch(filters.sellers)}
          AND (${filters.provinceCode} = '' OR l.location ->> 'provinceCode' = ${filters.provinceCode})
          AND (${filters.wardCode} = '' OR l.location ->> 'wardCode' = ${filters.wardCode})
          AND (cardinality(${filters.conditions}::text[]) = 0 OR l.condition::text = ANY(${filters.conditions}::text[]))
          AND ${dealMatch(filters.deals)}
          AND (${filters.minPrice}::numeric IS NULL OR l.price >= ${filters.minPrice}::numeric)
          AND (${filters.maxPrice}::numeric IS NULL OR l.price <= ${filters.maxPrice}::numeric)
        ORDER BY ${orderBy(filters, distance, sort)}`;
}

/** Tên chuyên mục + tên danh mục con của tin */
const categoryNames = Prisma.sql`concat_ws(' ', c.name, (
    SELECT sub -> 'name' ->> 'vi' FROM jsonb_array_elements(COALESCE(c.metadata -> 'subcategories', '[]'::jsonb)) sub
    WHERE sub ->> 'id' = l."subcategoryId" LIMIT 1))`;

/**
 * Nội dung dùng để tìm: tiêu đề + tên chuyên mục + tên danh mục con + hãng + dòng máy (thuộc tính brand, model).
 * Nhờ vậy "điện thoại" ra mọi tin danh mục con Điện thoại, "apple" ra các tin iPhone.
 * Không tìm trong mô tả vì mô tả hay nhắc chữ không liên quan ("liên hệ qua điện thoại").
 */
const searchSource = Prisma.sql`concat_ws(' ', l.title, ${categoryNames}, l.attributes ->> 'brand', l.attributes ->> 'model')`;

/** Nội dung tìm kiếm chứa đủ mọi từ đã gõ */
const wordsMatch = (terms: SearchTerm[]) =>
  !terms.length ? Prisma.sql`TRUE` : allTermsIn(terms, Prisma.sql`search.f`, Prisma.sql`search.a`);

/**
 * Khớp mọi bộ lọc thuộc tính: values = giá trị thuộc tính nằm trong danh sách; min/max = thuộc tính kiểu số
 * trong khoảng (giá trị không phải số thì không khớp).
 */
function attributeMatch(filters: AttributeFilter[]) {
  if (!filters.length) return Prisma.sql`TRUE`;
  return Prisma.join(filters.map(({ key, values, min, max }) => {
    if (values) return Prisma.sql`l.attributes ->> ${key}::text = ANY(${values}::text[])`;
    const value = Prisma.sql`(CASE WHEN jsonb_typeof(l.attributes -> ${key}::text) = 'number'
      THEN (l.attributes ->> ${key}::text)::numeric END)`;
    return Prisma.sql`(${value} IS NOT NULL AND (${min ?? null}::numeric IS NULL OR ${value} >= ${min ?? null}::numeric)
      AND (${max ?? null}::numeric IS NULL OR ${value} <= ${max ?? null}::numeric))`;
  }), ' AND ', '(', ')');
}

/** Nhóm người đăng tương ứng với từng lựa chọn "Đăng bởi" (PRO = Đối tác) */
const SELLER_TIER: Record<SellerKind, string> = { personal: 'PERSONAL', pro: 'BASIC', partner: 'PRO' };

/**
 * Người đăng thuộc một trong các nhóm đã chọn. Đối tác = có cửa hàng công khai như nhãn "Đối tác" trên tin (gói nào cũng được);
 * còn lại theo gói đang hiệu lực: gói trả phí = Bán chuyên, không có gói = Cá nhân.
 */
function sellerMatch(sellers: SellerKind[]) {
  if (!sellers.length) return Prisma.sql`TRUE`;
  const tiers = sellers.map((item) => SELLER_TIER[item]);
  return Prisma.sql`(CASE
    WHEN EXISTS (SELECT 1 FROM "Shop" s WHERE s."ownerId" = l."ownerId"
      AND (s.status = 'APPROVED' OR s."verificationType" IS NOT NULL)) THEN 'PRO'
    WHEN sp.tier::text IN ('BASIC', 'PRO') THEN 'BASIC'
    ELSE 'PERSONAL' END) = ANY(${tiers}::text[])`;
}

/** Khớp một trong các kiểu giao dịch đã chọn: buy = có bán, exchange = cho đổi */
function dealMatch(deals: DealType[]) {
  if (!deals.length) return Prisma.sql`TRUE`;
  return Prisma.sql`(${deals.includes('buy')} AND l."allowSale" OR ${deals.includes('exchange')} AND l."allowExchange")`;
}

/** Thứ tự mặc định của feed: gần nhất (nếu có), đẩy FEATURED, gói cửa hàng cùng danh mục, BUMP, thời gian */
const rankOrder = Prisma.sql`COALESCE(boosted."featuredPriority", 0) DESC,
          CASE WHEN ss."categoryId" = l."categoryId" THEN COALESCE(sp."priorityLevel", 0) ELSE 0 END DESC,
          GREATEST(COALESCE(l."publishedAt", l."createdAt"),
            COALESCE(boosted."bumpedAt", l."createdAt")) DESC,
          COALESCE(l."publishedAt", l."createdAt") DESC, l.id DESC`;

/**
 * Không có [sort]: thứ tự feed. Có [sort] (trang tìm kiếm):
 * - relevance: tiêu đề bắt đầu bằng cụm từ khoá, rồi chứa nguyên cụm, rồi tiêu đề chứa đủ các từ
 *   (trước các tin chỉ khớp nhờ chuyên mục / hãng), rồi thứ tự feed
 * - newest: mới đăng trước; nearest: gần nhất trước
 * - price_asc / price_desc: theo giá, tin chỉ trao đổi (không bán) xếp cuối
 */
function orderBy(filters: FeedOptions, distance: Prisma.Sql, sort?: SearchSort) {
  const newest = Prisma.sql`COALESCE(l."publishedAt", l."createdAt") DESC, l.id DESC`;
  switch (sort) {
    case undefined:
      // Feed: "Mới nhất" xếp theo thời gian trước, "Dành cho bạn" ưu tiên chuyên mục người xem hay lưu
      return Prisma.sql`${filters.chronological ? Prisma.sql`${newest},` : Prisma.empty}
        ${filters.interestUserId ? Prisma.sql`COALESCE(interest.affinity, 0) DESC,` : Prisma.empty}
        ${filters.nearby ? Prisma.sql`${distance} ASC,` : Prisma.empty} ${rankOrder}`;
    case 'relevance': {
      if (!filters.words.length) return rankOrder;
      const terms = searchTerms(filters);
      // Gõ có dấu thì so cụm từ trên nội dung giữ dấu
      const exact = terms.some((term) => term.exact);
      const phrase = ` ${terms.map((term) => term.text).join(' ')}`;
      const title = exact ? Prisma.sql`search.ta` : Prisma.sql`search.tf`;
      const category = exact ? Prisma.sql`search.ca` : Prisma.sql`search.cf`;
      return Prisma.sql`(POSITION(${phrase} IN ${title}) = 1) DESC, (POSITION(${phrase} IN ${title}) > 0) DESC,
        (POSITION(${phrase} IN ${category}) > 0) DESC,
        ${allTermsIn(terms, Prisma.sql`search.tf`, Prisma.sql`search.ta`)} DESC, ${rankOrder}`;
    }
    case 'newest':
      return newest;
    case 'nearest':
      return Prisma.sql`${distance} ASC NULLS LAST, ${newest}`;
    case 'price_asc':
      return Prisma.sql`l."allowSale" DESC, l.price ASC, ${newest}`;
    case 'price_desc':
      return Prisma.sql`l."allowSale" DESC, l.price DESC, ${newest}`;
  }
}

/**
 * Lấy một trang id tin đã xếp hạng (đẩy tin, gói cửa hàng, khoảng cách, thời gian)
 * cùng tổng số tin khớp bộ lọc. Một câu SQL (tổng đếm bằng window) để chỉ tốn một lượt
 * đi về DB; chỉ khi trang vượt quá cuối danh sách mới đếm riêng.
 */
export async function findRankedPage(filters: FeedOptions, now: Date, limit: number, skip: number,
  sort?: SearchSort) {
  const query = rankedQuery(filters, now, sort);
  const rows = await prisma.$queryRaw<(RankedRow & { totalItems: number })[]>`${query} LIMIT ${limit} OFFSET ${skip}`;
  const totalItems = rows[0]?.totalItems ?? (skip === 0 ? 0
    : (await prisma.$queryRaw<{ n: number }[]>`SELECT COUNT(*)::int AS n FROM (${query}) ranked`)[0]?.n ?? 0);
  return { rows: rows.map(({ totalItems: _, ...row }) => row), totalItems };
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
