import { ListingStatus, Prisma } from '@prisma/client';
import { hasPermission, PERMISSION } from '../../../common/auth/permissions.js';
import { AppError } from '../../../common/errors/app-error.js';
import { storePackageForUser, storeUsage, withQuotaTransaction } from '../../commerce/index.js';
import type { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { toCategoryDto } from '../../catalog/catalog.dto.js';
import { ListingInput, MineQuery, toListingDto, toOwnerListingDto } from '../listing.dto.js';
import { LISTING_EDITABLE } from '../listing.type.js';
import { validateAttributes } from '../listing.validator.js';
import * as listingRepository from '../repositories/listing.repository.js';
import type { Db } from '../repositories/listing.repository.js';

type Viewer = AuthRequest['user'];

/* ---------- Dùng chung cho tin, nháp ---------- */

/** Tin của chủ tin, không có thì 404 */
export async function requireOwnedListing(tx: Db, id: string, ownerId: string) {
  const listing = await listingRepository.findOwned(id, ownerId, tx);
  if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
  return listing;
}

/** Cập nhật tin khi trạng thái vẫn như lúc đọc, nếu không thì 409 LISTING_CHANGED */
export async function updateOwnedListing(tx: Db, id: string, ownerId: string,
  expectedStatus: ListingStatus, data: Prisma.ListingUncheckedUpdateManyInput) {
  if (!await listingRepository.updateOwnedWhereStatus(tx, id, ownerId, expectedStatus, data)) {
    throw new AppError(409, 'LISTING_CHANGED', 'Tin đã thay đổi. Vui lòng tải lại.');
  }
}

/** Chủ tin được đổi trạng thái theo các bước này */
export function canChangeListingStatus(current: ListingStatus, target: ListingStatus) {
  return (current === ListingStatus.AVAILABLE && (target === ListingStatus.HIDDEN || target === ListingStatus.SOLD || target === ListingStatus.EXCHANGED)) ||
    (current === ListingStatus.HIDDEN && (target === ListingStatus.AVAILABLE || target === ListingStatus.SOLD || target === ListingStatus.EXCHANGED));
}

/** Danh mục còn dùng, tình trạng chưa ngừng, thuộc tính đúng metadata danh mục */
export async function assertPublishable(tx: Db, data: Pick<ListingInput, 'categoryId' | 'condition' | 'attributes'>) {
  const category = await listingRepository.findActiveCategory(tx, data.categoryId);
  if (!category) throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
  if (data.condition && (await listingRepository.findConditionPolicy(tx, data.condition))?.active === false) {
    throw new AppError(400, 'INVALID_CONDITION', 'Tình trạng đã ngừng sử dụng.');
  }
  validateAttributes(data.attributes, category.metadata, true);
}

/** Còn lượt đăng tin theo gói cửa hàng: lượt trong ngày (nếu [daily]) và số tin đang hoạt động */
export async function assertQuota(tx: Db, ownerId: string, now: Date, { daily }: { daily: boolean }) {
  const plan = await storePackageForUser(tx, ownerId, now);
  const usage = await storeUsage(tx, ownerId, now);
  if (daily && usage.today >= plan.package.dailyListingLimit) {
    throw new AppError(409, 'DAILY_LISTING_LIMIT', 'Bạn đã dùng hết lượt đăng tin trong ngày.');
  }
  if (usage.active >= plan.package.activeListingLimit) {
    throw new AppError(409, 'ACTIVE_LISTING_LIMIT', 'Bạn đã đạt giới hạn tin đang hoạt động.');
  }
}

/* ---------- Tin đăng ---------- */

/** Đăng tin mới, chờ duyệt (PENDING) */
export async function createListing(ownerId: string, data: ListingInput) {
  const listing = await withQuotaTransaction(async (tx) => {
    const now = new Date();
    await assertPublishable(tx, data);
    await assertQuota(tx, ownerId, now, { daily: true });
    return listingRepository.createListing({ ...data, ownerId, images: [], publishedAt: now, status: ListingStatus.PENDING }, tx);
  });
  return toOwnerListingDto(listing);
}

/** Sửa tin đã đăng; tin quay lại chờ duyệt */
export async function updateListing(ownerId: string, id: string, data: ListingInput) {
  const listing = await listingRepository.transaction(async (tx) => {
    const current = await requireOwnedListing(tx, id, ownerId);
    if (!LISTING_EDITABLE.includes(current.status)) {
      throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Chỉ sửa được tin đang hiển thị hoặc đã ẩn.');
    }
    await assertPublishable(tx, data);
    await updateOwnedListing(tx, id, ownerId, current.status, { ...data, status: ListingStatus.PENDING, reviewReason: null });
    return listingRepository.findSelected(tx, id);
  });
  return toOwnerListingDto(listing);
}

/** Ẩn, hiện lại, đánh dấu đã bán / đã trao đổi */
export async function changeStatus(ownerId: string, id: string, target: ListingStatus) {
  const listing = await withQuotaTransaction(async (tx) => {
    const current = await requireOwnedListing(tx, id, ownerId);
    if ((target === ListingStatus.SOLD && !current.allowSale) || (target === ListingStatus.EXCHANGED && !current.allowExchange)) {
      throw new AppError(400, 'INVALID_STATUS', 'Tin không hỗ trợ loại giao dịch này.');
    }
    if (!canChangeListingStatus(current.status, target)) {
      throw new AppError(409, 'INVALID_STATUS_CHANGE', 'Không thể đổi trạng thái tin theo cách này.');
    }
    if (target === ListingStatus.AVAILABLE) await assertQuota(tx, ownerId, new Date(), { daily: false });
    await updateOwnedListing(tx, id, ownerId, current.status, { status: target });
    return listingRepository.findSelected(tx, id);
  });
  return toOwnerListingDto(listing);
}

/** Số tin đang bán và đã bán */
export async function getSummary(ownerId: string) {
  const [active, sold] = await listingRepository.countByOwner(ownerId);
  return { active, sold };
}

/** Tin của tôi, mới tạo trước */
export async function listMine(ownerId: string, { page, pageSize, status }: MineQuery) {
  const [items, totalItems] = await listingRepository.findMine(ownerId, status, (page - 1) * pageSize, pageSize);
  return {
    items: items.map(toOwnerListingDto),
    pagination: { page, pageSize, totalItems, totalPages: Math.ceil(totalItems / pageSize) },
  };
}

export async function getMine(ownerId: string, id: string) {
  const listing = await listingRepository.findOwnedDetail(id, ownerId);
  if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
  return toOwnerListingDto(listing);
}

/** Chi tiết tin công khai, tăng lượt xem (trừ chủ tin và người kiểm duyệt) */
export async function viewListing(viewer: Viewer, id: string) {
  const listing = await listingRepository.findVisible(id);
  if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng.');
  const views = await listingRepository.incrementViewCount(id, hasPermission(viewer?.role, PERMISSION.LISTING_MODERATE), viewer?.userId ?? '');
  if (!views.length) throw new AppError(404, 'LISTING_NOT_FOUND', 'Tin không còn hiển thị.');
  listing.viewCount = views[0]!.viewCount;
  const [seller, category, sellerActiveListings, favorite] = await listingRepository.findDetailExtras(
    listing.ownerId, listing.categoryId, id, viewer?.userId);
  // Trang chi tiết (docs: listing-api-contract.md mục 5): người bán công khai, danh mục kèm thuộc tính
  return {
    ...toListingDto(listing),
    seller,
    category: category ? toCategoryDto(category) : listing.category,
    sellerActiveListings,
    isFavorite: !!favorite,
    isOwner: viewer?.userId === listing.ownerId,
  };
}
