import { ListingCondition, ListingStatus, Prisma, type StoreTier } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { adminListingSelect, listingSelect, ownerListingSelect, revisionSelect } from '../listing.dto.js';

/** Prisma client hoặc transaction đang chạy */
export type Db = Prisma.TransactionClient;

/** Điều kiện tin được hiển thị công khai: đang bán và chủ tin còn hoạt động */
export const visible = { status: 'AVAILABLE' as const, owner: { status: 'ACTIVE' as const } };

/** Chạy [work] trong một transaction thường (không cần khóa quota) */
export const transaction = <T>(work: (tx: Db) => Promise<T>) => prisma.$transaction(work);

/* ---------- Danh mục, tình trạng ---------- */

export const findActiveCategory = (db: Db, id: string) => db.category.findFirst({ where: { id, active: true } });

export const findCategory = (id: string, db: Db = prisma) => db.category.findUnique({ where: { id } });

export const findConditionPolicy = (db: Db, condition: ListingCondition) =>
  db.conditionPolicy.findUnique({ where: { condition } });

/* ---------- Tin của chủ tin ---------- */

export const createListing = (data: Prisma.ListingUncheckedCreateInput, db: Db = prisma) =>
  db.listing.create({ data, select: ownerListingSelect });

export const findOwned = (id: string, ownerId: string, db: Db = prisma) =>
  db.listing.findFirst({ where: { id, ownerId }, include: { revision: true } });

export const findOwnedDetail = (id: string, ownerId: string) =>
  prisma.listing.findFirst({ where: { id, ownerId }, select: ownerListingSelect });

export const findSelected = (db: Db, id: string) => db.listing.findUniqueOrThrow({ where: { id }, select: ownerListingSelect });

/* ---------- Bản sửa của tin đã duyệt ---------- */

/** Tạo hoặc thay bản sửa của tin, đưa về chờ duyệt */
export const upsertRevision = (db: Db, listingId: string, data: Omit<Prisma.ListingRevisionUncheckedCreateInput, 'listingId'>) =>
  db.listingRevision.upsert({ where: { listingId }, create: { ...data, listingId }, update: data });

/** Đổi ảnh bản sửa khi ảnh vẫn như lúc đọc; trả về số dòng đổi (0 = đã bị đổi) */
export async function updateRevisionImagesIfUnchanged(listingId: string, current: string[], images: string[]) {
  const changed = await prisma.listingRevision.updateMany({
    where: { listingId, images: { equals: current } },
    data: { images, status: 'PENDING', reviewReason: null },
  });
  return changed.count;
}

/** Xóa bản sửa của tin, trả về bản đã xóa (null nếu không có) */
export async function deleteRevision(db: Db, listingId: string) {
  const revision = await db.listingRevision.findUnique({ where: { listingId }, select: { images: true } });
  if (revision) await db.listingRevision.delete({ where: { listingId } });
  return revision;
}

/** Cập nhật khi tin vẫn đúng chủ và đúng trạng thái đã đọc; trả về số dòng đổi (0 = đã bị đổi) */
export async function updateOwnedWhereStatus(db: Db, id: string, ownerId: string,
  status: ListingStatus, data: Prisma.ListingUncheckedUpdateManyInput) {
  const changed = await db.listing.updateMany({ where: { id, ownerId, status }, data });
  return changed.count;
}

export const findOwnedDraft = (id: string, ownerId: string) =>
  prisma.listing.findFirst({ where: { id, ownerId, status: ListingStatus.DRAFT } });

export async function deleteOwnedDraft(id: string, ownerId: string) {
  const deleted = await prisma.listing.deleteMany({ where: { id, ownerId, status: ListingStatus.DRAFT } });
  return deleted.count;
}

export const findMine = (ownerId: string, status: ListingStatus | undefined, skip: number, take: number) => {
  const where = { ownerId, ...(status ? { status } : {}) };
  // Tin nháp: cái vừa sửa lên đầu để soạn tiếp
  const orderBy = status === ListingStatus.DRAFT
    ? [{ updatedAt: 'desc' as const }, { id: 'desc' as const }]
    : [{ createdAt: 'desc' as const }, { id: 'desc' as const }];
  return prisma.$transaction([
    prisma.listing.findMany({ where, select: ownerListingSelect, orderBy, skip, take }),
    prisma.listing.count({ where }),
  ]);
};

/* ---------- Ảnh ---------- */

/** Đổi danh sách ảnh khi tin chưa bị ai sửa từ lúc đọc; trả về số dòng đổi */
export async function updateImagesIfUnchanged(id: string, ownerId: string, current: { status: ListingStatus; images: string[] },
  data: { images: string[]; status: ListingStatus }) {
  const changed = await prisma.listing.updateMany({
    where: { id, ownerId, status: current.status, images: { equals: current.images } },
    data,
  });
  return changed.count;
}

/** Tin chứa ảnh [url], để kiểm tra ai được xem ảnh */
export const isReviewedThumbnail = async (ownerId: string, image: string) =>
  !!await prisma.listingTrade.findFirst({ where: { sellerId: ownerId, image, confirmedAt: { not: null }, reviews: { some: {} } },
    select: { conversationId: true } });

export const findByImage = (url: string) =>
  prisma.listing.findFirst({ where: { images: { has: url } }, select: { ownerId: true, status: true, owner: { select: { status: true } } } });

/** Tin có bản sửa chứa ảnh [url] (ảnh mới chưa duyệt: chỉ chủ tin và người duyệt xem được) */
export const findByRevisionImage = (url: string) =>
  prisma.listing.findFirst({ where: { revision: { images: { has: url } } }, select: { ownerId: true } });

/* ---------- Công khai ---------- */

/** Thông tin thêm cho trang chi tiết tin: người bán công khai, danh mục đầy đủ, số tin đang bán, đã lưu chưa */
export const findDetailExtras = (ownerId: string, categoryId: string | null, listingId: string, viewerId?: string) =>
  Promise.all([
    prisma.user.findUnique({
      where: { id: ownerId },
      select: {
        id: true, fullName: true, username: true, avatarUrl: true, status: true, phone: true,
        ratingAverage: true, ratingCount: true, createdAt: true, lastActiveAt: true,
        _count: { select: { listings: { where: { status: 'SOLD' } } } },
      },
    }),
    categoryId ? prisma.category.findUnique({ where: { id: categoryId } }) : Promise.resolve(null),
    prisma.listing.count({ where: { ownerId, status: 'AVAILABLE' } }),
    viewerId
      ? prisma.listingFavorite.findUnique({ where: { userId_listingId: { userId: viewerId, listingId } }, select: { listingId: true } })
      : Promise.resolve(null),
  ]);

export const findVisible = (id: string) => prisma.listing.findFirst({ where: { ...visible, id }, select: listingSelect });

/** Tăng lượt xem (trừ khi [skipCount]) và trả về lượt xem mới; rỗng nếu tin không còn hiển thị */
/** Cộng 1 lượt xem (trừ chủ tin, người kiểm duyệt) vào tổng và vào ngày hôm nay (giờ Việt Nam) */
export const incrementViewCount = (id: string, skipCount: boolean, viewerId: string) =>
  prisma.$queryRaw<{ viewCount: number }[]>`WITH up AS (
      UPDATE "Listing" SET "viewCount"="viewCount"+
        CASE WHEN ${skipCount} OR "ownerId"=${viewerId} THEN 0 ELSE 1 END
      WHERE id=${id} AND status='AVAILABLE' AND EXISTS(SELECT 1 FROM "User" WHERE id="Listing"."ownerId" AND status='ACTIVE')
      RETURNING id, "viewCount", NOT (${skipCount} OR "ownerId"=${viewerId}) AS counted
    ), daily AS (
      INSERT INTO "ListingViewDaily" ("listingId", "day", "views")
      SELECT id, (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date, 1 FROM up WHERE counted
      ON CONFLICT ("listingId", "day") DO UPDATE SET "views" = "ListingViewDaily"."views" + 1
    )
    SELECT "viewCount" FROM up`;

/* ---------- Duyệt tin ---------- */

export const findPending = () =>
  prisma.listing.findMany({ where: { status: 'PENDING' }, select: listingSelect, orderBy: { publishedAt: 'asc' }, take: 100 });

/** Tin đã duyệt có bản sửa chờ duyệt, gửi sớm trước */
export const findPendingRevisions = () =>
  prisma.listing.findMany({ where: { revision: { status: 'PENDING' } }, select: ownerListingSelect,
    orderBy: { revision: { submittedAt: 'asc' } }, take: 100 });

/** Tin cần đọc khi admin ra quyết định */
export const findForModeration = (tx: Db, id: string) =>
  tx.listing.findUnique({ where: { id }, select: { id: true, ownerId: true, status: true, images: true, updatedAt: true, categoryId: true, subcategoryId: true, condition: true, title: true,
    price: true, expiresAt: true, startsAt: true, displayDays: true, revision: { select: revisionSelect } } });

/** Áp bản sửa vào tin khi tin vẫn đúng trạng thái và bản sửa vẫn đúng updatedAt lúc admin mở; trả về số dòng đổi */
export async function applyRevision(tx: Db, id: string, status: ListingStatus, revisionUpdatedAt: Date,
  data: Prisma.ListingUncheckedUpdateManyInput) {
  const removed = await tx.listingRevision.deleteMany({ where: { listingId: id, status: 'PENDING', updatedAt: revisionUpdatedAt } });
  if (!removed.count) return 0;
  return (await tx.listing.updateMany({ where: { id, status }, data })).count;
}

/** Từ chối bản sửa khi bản sửa vẫn đúng updatedAt lúc admin mở; trả về số dòng đổi */
export async function rejectRevision(tx: Db, id: string, revisionUpdatedAt: Date, reason: string) {
  return (await tx.listingRevision.updateMany({ where: { listingId: id, status: 'PENDING', updatedAt: revisionUpdatedAt },
    data: { status: 'REJECTED', reviewReason: reason } })).count;
}

/** Đổi trạng thái khi tin vẫn đúng trạng thái và updatedAt lúc admin mở; trả về số dòng đổi */
export async function updateWhereVersion(tx: Db, id: string, status: ListingStatus, updatedAt: Date,
  data: { status: ListingStatus; reviewReason: string | null; paidCredits?: number; expiresAt?: Date; startsAt?: Date | null; publishedAt?: Date }) {
  const changed = await tx.listing.updateMany({ where: { id, status, updatedAt }, data });
  return changed.count;
}

/** Cột đang hiển thị để so với bản sửa (ngoài adminListingSelect) */
export const adminCompareSelect = {
  originalPrice: true, isNegotiable: true, allowSale: true, allowExchange: true, exchangeWish: true, attributes: true, location: true,
} as const satisfies Prisma.ListingSelect;

/** Người đăng đang dùng gói [tier] (gói hết hạn hoặc chưa bắt đầu tính là PERSONAL) */
function sellerTierWhere(tier: StoreTier, now: Date): Prisma.ListingWhereInput {
  const active = { startsAt: { lte: now }, endsAt: { gt: now } };
  if (tier !== 'PERSONAL') return { owner: { storeSubscription: { is: { ...active, package: { tier } } } } };
  return { owner: { NOT: { storeSubscription: { is: { ...active, package: { tier: { in: ['BASIC', 'PRO'] } } } } } } };
}

export type AdminListingFilters = { status?: ListingStatus; q?: string; tier?: StoreTier; edit?: 'PENDING'; flagged?: boolean; ownerIds?: string[] };

/** Điều kiện lọc của trang quản trị; flagged: tin hoặc bản sửa chờ duyệt bị gắn cờ lúc gửi duyệt */
function adminWhere({ status, q, tier, edit, flagged, ownerIds }: AdminListingFilters, now: Date): Prisma.ListingWhereInput {
  const contains = { contains: q, mode: 'insensitive' as const };
  return {
    ...(status ? { status } : {}), ...(edit ? { revision: { status: edit } } : {}), 
    ...(ownerIds ? { ownerId: { in: ownerIds } } : {}),
    ...(flagged ? { AND: [{ OR: [{ flagged: true }, { revision: { status: 'PENDING', flagged: true } }] }] } : {}),
    ...(q ? { OR: [{ title: contains }, { owner: { fullName: contains } }, { owner: { email: contains } }] } : {}),
    ...(tier ? sellerTierWhere(tier, now) : {}),
  };
}

/**
 * Trang tin cho admin. Hàng chờ (tin chờ duyệt, bản sửa chờ duyệt) xếp gửi sớm trước để tin cũ không bị chìm;
 * các trạng thái khác mới cập nhật trước. q tìm trong tiêu đề, họ tên hoặc email người đăng.
 */
export function findAdminPage(filters: AdminListingFilters, skip: number, take: number, now = new Date()) {
  const { status, edit } = filters;
  const where = adminWhere(filters, now);
  const orderBy: Prisma.ListingOrderByWithRelationInput[] = edit ? [{ revision: { submittedAt: 'asc' } }, { id: 'asc' }]
    : status === ListingStatus.PENDING ? [{ updatedAt: 'asc' }, { id: 'asc' }] : [{ updatedAt: 'desc' }, { id: 'desc' }];
  return Promise.all([
    prisma.listing.findMany({ where, select: { ...adminListingSelect, ...adminCompareSelect, revision: { select: { ...revisionSelect, flagged: true } } },
      orderBy, skip, take }),
    prisma.listing.count({ where }),
  ]);
}

export const findAdminListing = (id: string) => prisma.listing.findUnique({ where: { id }, select: adminListingSelect });
export const findOwnerId = (id: string) => prisma.listing.findUnique({ where: { id }, select: { ownerId: true } });

/** Quyết định không duyệt (từ nhật ký quản trị, gồm cả trên bản sửa): từ chối, yêu cầu sửa, gỡ tin */
const STRIKES = { rejected: ['REJECT', 'REJECT_EDIT'], changesRequested: ['REQUEST_CHANGES', 'REQUEST_CHANGES_EDIT'], removed: ['REMOVE'] } as const;
/**
 * Người đăng tái phạm: từ REPEAT_STRIKES lần bị từ chối / gỡ (không tính yêu cầu sửa) trong REPEAT_DAYS ngày gần nhất.
 * ponytail: ngưỡng cố định trong code; cần chỉnh theo vận hành thì chuyển vào cấu hình admin.
 */
export const REPEAT_STRIKES = 3, REPEAT_DAYS = 30;
const SERIOUS = [...STRIKES.rejected, ...STRIKES.removed];
const repeatSince = (now: Date) => new Date(now.getTime() - REPEAT_DAYS * 86_400_000);

/** Số lần theo loại, và recentStrikes: số lần bị từ chối / gỡ trong REPEAT_DAYS ngày gần nhất */
export type SellerHistory = Record<keyof typeof STRIKES, number> & { recentStrikes: number };
export const NO_HISTORY: SellerHistory = { rejected: 0, changesRequested: 0, removed: 0, recentStrikes: 0 };

/**
 * Số lần tin của từng người đăng bị từ chối / yêu cầu sửa / gỡ. Người chưa từng bị thì không có trong Map.
 * ponytail: tin đã xoá hẳn thì mất khỏi phép đếm (nhật ký chỉ lưu mã tin); cần đếm cả thì lưu ownerId vào nhật ký.
 */
export async function findSellerHistory(ownerIds: string[], now = new Date()) {
  if (!ownerIds.length) return new Map<string, SellerHistory>();
  const count = (actions: readonly string[]) => Prisma.sql`count(*) FILTER (WHERE a.action IN (${Prisma.join(actions)}))::int`;
  const rows = await prisma.$queryRaw<({ ownerId: string } & SellerHistory)[]>`
    SELECT l."ownerId", ${count(STRIKES.rejected)} AS rejected, ${count(STRIKES.changesRequested)} AS "changesRequested",
      ${count(STRIKES.removed)} AS removed,
      count(*) FILTER (WHERE a.action IN (${Prisma.join(SERIOUS)}) AND a."createdAt" >= ${repeatSince(now)})::int AS "recentStrikes"
    FROM "AdminAudit" a JOIN "Listing" l ON l.id = a."targetId"
    WHERE a."targetType" = 'LISTING' AND l."ownerId" IN (${Prisma.join([...new Set(ownerIds)])})
      AND a.action IN (${Prisma.join(Object.values(STRIKES).flat())})
    GROUP BY l."ownerId"`;
  return new Map(rows.map(({ ownerId, ...history }) => [ownerId, history]));
}

/** Người đăng tái phạm (xem REPEAT_STRIKES), cho bộ lọc offender của trang quản trị */
export async function findRepeatOffenders(now = new Date()) {
  const rows = await prisma.$queryRaw<{ ownerId: string }[]>`
    SELECT l."ownerId" FROM "AdminAudit" a JOIN "Listing" l ON l.id = a."targetId"
    WHERE a."targetType" = 'LISTING' AND a.action IN (${Prisma.join(SERIOUS)}) AND a."createdAt" >= ${repeatSince(now)}
    GROUP BY l."ownerId" HAVING count(*) >= ${REPEAT_STRIKES}`;
  return rows.map((row) => row.ownerId);
}

/** 5 quyết định không duyệt gần nhất trên tin của một người đăng, kèm tiêu đề tin và lý do */
export const findRecentStrikes = (ownerId: string) => prisma.$queryRaw<
  { listingId: string; title: string; action: string; reason: string; createdAt: Date }[]>`
  SELECT l.id AS "listingId", l.title, a.action, a.reason, a."createdAt"
  FROM "AdminAudit" a JOIN "Listing" l ON l.id = a."targetId"
  WHERE a."targetType" = 'LISTING' AND l."ownerId" = ${ownerId} AND a.action IN (${Prisma.join(Object.values(STRIKES).flat())})
  ORDER BY a."createdAt" DESC LIMIT 5`;

/**
 * Giá thường gặp (median) của từng chuyên mục, tính trên tin đã duyệt có giá (đang hiện, đã ẩn, đặt trước, đã bán).
 * Chuyên mục chưa đủ MIN_SAMPLES tin thì không có trong Map.
 * ponytail: tính lại mỗi lần mở trang (một truy vấn cho các chuyên mục trên trang); chậm thì lưu sẵn theo ngày.
 */
export async function findTypicalPrices(categoryIds: (string | null)[], minSamples: number) {
  const ids = [...new Set(categoryIds.filter((id): id is string => !!id))];
  if (!ids.length) return new Map<string, number>();
  const rows = await prisma.$queryRaw<{ categoryId: string; typical: number }[]>`
    SELECT "categoryId", percentile_cont(0.5) WITHIN GROUP (ORDER BY price)::float8 AS typical
    FROM "Listing"
    WHERE "categoryId" IN (${Prisma.join(ids)}) AND price > 0 AND status IN ('AVAILABLE', 'HIDDEN', 'RESERVED', 'SOLD')
    GROUP BY "categoryId" HAVING count(*) >= ${minSamples}`;
  return new Map(rows.map((row) => [row.categoryId, row.typical]));
}
