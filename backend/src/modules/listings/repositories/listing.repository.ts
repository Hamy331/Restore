import { ListingCondition, ListingStatus, Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { adminListingSelect, listingSelect } from '../listing.dto.js';

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
  db.listing.create({ data, select: listingSelect });

export const findOwned = (id: string, ownerId: string, db: Db = prisma) => db.listing.findFirst({ where: { id, ownerId } });

export const findOwnedDetail = (id: string, ownerId: string) =>
  prisma.listing.findFirst({ where: { id, ownerId }, select: listingSelect });

export const findSelected = (db: Db, id: string) => db.listing.findUniqueOrThrow({ where: { id }, select: listingSelect });

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

export const countByOwner = (ownerId: string) =>
  prisma.$transaction([
    prisma.listing.count({ where: { ownerId, status: 'AVAILABLE' } }),
    prisma.listing.count({ where: { ownerId, status: 'SOLD' } }),
  ]);

export const findMine = (ownerId: string, status: ListingStatus | undefined, skip: number, take: number) => {
  const where = { ownerId, ...(status ? { status } : {}) };
  // Tin nháp: cái vừa sửa lên đầu để soạn tiếp
  const orderBy = status === ListingStatus.DRAFT
    ? [{ updatedAt: 'desc' as const }, { id: 'desc' as const }]
    : [{ createdAt: 'desc' as const }, { id: 'desc' as const }];
  return prisma.$transaction([
    prisma.listing.findMany({ where, select: listingSelect, orderBy, skip, take }),
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
export const findByImage = (url: string) =>
  prisma.listing.findFirst({ where: { images: { has: url } }, select: { ownerId: true, status: true, owner: { select: { status: true } } } });

/* ---------- Công khai ---------- */

/** Thông tin thêm cho trang chi tiết tin: người bán công khai, danh mục đầy đủ, số tin đang bán, đã lưu chưa */
export const findDetailExtras = (ownerId: string, categoryId: string | null, listingId: string, viewerId?: string) =>
  Promise.all([
    prisma.user.findUnique({
      where: { id: ownerId },
      select: {
        id: true, fullName: true, username: true, avatarUrl: true, status: true,
        ratingAverage: true, ratingCount: true, createdAt: true,
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
export const incrementViewCount = (id: string, skipCount: boolean, viewerId: string) =>
  prisma.$queryRaw<{ viewCount: number }[]>`UPDATE "Listing" SET "viewCount"="viewCount"+
      CASE WHEN ${skipCount} OR "ownerId"=${viewerId} THEN 0 ELSE 1 END
      WHERE id=${id} AND status='AVAILABLE' AND EXISTS(SELECT 1 FROM "User" WHERE id="Listing"."ownerId" AND status='ACTIVE') RETURNING "viewCount"`;

/* ---------- Duyệt tin ---------- */

export const findPending = () =>
  prisma.listing.findMany({ where: { status: 'PENDING' }, select: listingSelect, orderBy: { publishedAt: 'asc' }, take: 100 });

/** Tin cần đọc khi admin ra quyết định */
export const findForModeration = (tx: Db, id: string) =>
  tx.listing.findUnique({ where: { id }, select: { id: true, status: true, images: true, updatedAt: true, categoryId: true, condition: true, title: true, expiresAt: true } });

/** Đổi trạng thái khi tin vẫn đúng trạng thái và updatedAt lúc admin mở; trả về số dòng đổi */
export async function updateWhereVersion(tx: Db, id: string, status: ListingStatus, updatedAt: Date,
  data: { status: ListingStatus; reviewReason: string | null; paidCredits?: number; expiresAt?: Date }) {
  const changed = await tx.listing.updateMany({ where: { id, status, updatedAt }, data });
  return changed.count;
}

/** Danh sách quản trị: lọc trạng thái, tìm trong tiêu đề; cập nhật gần nhất trước */
export function findAdminPage({ status, q }: { status?: ListingStatus; q?: string }, skip: number, take: number) {
  const where: Prisma.ListingWhereInput = { ...(status ? { status } : {}), ...(q ? { title: { contains: q, mode: 'insensitive' } } : {}) };
  return prisma.$transaction([
    prisma.listing.findMany({ where, select: adminListingSelect, orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }], skip, take }),
    prisma.listing.count({ where }),
  ]);
}

export const findAdminListing = (id: string) => prisma.listing.findUnique({ where: { id }, select: adminListingSelect });
