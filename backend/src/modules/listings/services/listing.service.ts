import { ListingStatus, Prisma } from '@prisma/client';
import { hasPermission, PERMISSION } from '../../../common/auth/permissions.js';
import { AppError } from '../../../common/errors/app-error.js';
import { createPromotion, findActivePackage, findActivePackagesOfKind, findRunningPromotion, storePackageForUser, storeUsage,
  withQuotaTransaction } from '../../commerce/index.js';
import { availableCredits } from '../../credits/index.js';
import type { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { toCategoryDto } from '../../catalog/catalog.dto.js';
import { ListingInput, MineQuery, toListingDto, toOwnerListingDto } from '../listing.dto.js';
import { LISTING_EDITABLE } from '../listing.type.js';
import { validateAttributes } from '../listing.validator.js';
import * as listingRepository from '../repositories/listing.repository.js';
import type { Db } from '../repositories/listing.repository.js';
import { COUNTED_STATUSES } from '../repositories/posting-quota.repository.js';
import { addDays, boostPrice, canExtend, featurePrice, daysLeft, extendedExpiry, isExpired } from '../listing-lifecycle.js';
import { assertNotDuplicate, spendForListing } from './listing-lifecycle.service.js';
import { assertPostingSlot, chargeListing, postingQuota } from './posting-quota.service.js';

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

/* ---------- Tin đăng ---------- */

/**
 * Đăng tin mới, chờ duyệt (PENDING). Hết suất miễn phí thì cần [payWithCredits]:
 * xu được giữ ngay, duyệt thì trừ hẳn, từ chối thì hoàn.
 */
export async function createListing(ownerId: string, data: ListingInput, payWithCredits = false, allowDuplicate = false) {
  const listing = await withQuotaTransaction(async (tx) => {
    const now = new Date();
    await assertPublishable(tx, data);
    await assertNotDuplicate(tx, ownerId, data, { allowDuplicate, now });
    const price = await assertPostingSlot(tx, ownerId, now, { categoryId: data.categoryId, daily: true, payWithCredits });
    const created = await listingRepository.createListing(
      { ...data, ownerId, images: [], publishedAt: now, status: ListingStatus.PENDING, paidCredits: price }, tx);
    await chargeListing(tx, ownerId, created.id, price, data.title);
    return created;
  });
  return toOwnerListingDto(listing);
}

/**
 * Sửa tin đã đăng; tin quay lại chờ duyệt.
 * Tin miễn phí cần suất lại khi đang không chiếm suất (bị từ chối, đã ẩn) hoặc đổi chuyên mục.
 * Tin đã trả xu giữ nguyên suất nhưng không được đổi chuyên mục (giá mỗi chuyên mục khác nhau).
 */
export async function updateListing(ownerId: string, id: string, data: ListingInput, payWithCredits = false) {
  const listing = await withQuotaTransaction(async (tx) => {
    const current = await requireOwnedListing(tx, id, ownerId);
    if (!LISTING_EDITABLE.includes(current.status)) {
      throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Chỉ sửa được tin đang hiển thị hoặc đã ẩn.');
    }
    await assertPublishable(tx, data);
    const categoryChanged = current.categoryId !== data.categoryId;
    if (current.paidCredits > 0 && categoryChanged) {
      throw new AppError(409, 'CATEGORY_LOCKED', 'Tin đã trả xu không đổi được chuyên mục.', 'categoryId');
    }
    let price = 0;
    if (current.paidCredits === 0 && (categoryChanged || !COUNTED_STATUSES.includes(current.status))) {
      price = await assertPostingSlot(tx, ownerId, new Date(), { categoryId: data.categoryId, daily: false, payWithCredits, excludeId: id });
    }
    await updateOwnedListing(tx, id, ownerId, current.status, {
      ...data, status: ListingStatus.PENDING, reviewReason: null, ...(price > 0 && { paidCredits: price }),
    });
    await chargeListing(tx, ownerId, id, price, data.title);
    return listingRepository.findSelected(tx, id);
  });
  return toOwnerListingDto(listing);
}

/** Ẩn, hiện lại, đánh dấu đã bán / đã trao đổi */
export async function changeStatus(ownerId: string, id: string, target: ListingStatus, payWithCredits = false) {
  const listing = await withQuotaTransaction(async (tx) => {
    const now = new Date();
    const current = await requireOwnedListing(tx, id, ownerId);
    if ((target === ListingStatus.SOLD && !current.allowSale) || (target === ListingStatus.EXCHANGED && !current.allowExchange)) {
      throw new AppError(400, 'INVALID_STATUS', 'Tin không hỗ trợ loại giao dịch này.');
    }
    if (!canChangeListingStatus(current.status, target)) {
      throw new AppError(409, 'INVALID_STATUS_CHANGE', 'Không thể đổi trạng thái tin theo cách này.');
    }
    if (target === ListingStatus.AVAILABLE && current.categoryId) {
      const category = await listingRepository.findActiveCategory(tx, current.categoryId);
      if (!category) throw new AppError(409, 'INVALID_LISTING', 'Danh mục không còn được sử dụng.');
      if (isExpired(current.expiresAt, now)) {
        // Kích hoạt lại tin hết hạn: tính như đăng mới (còn suất thì miễn phí, hết suất thì trả xu), hiển thị thêm một kỳ
        const price = await assertPostingSlot(tx, ownerId, now,
          { categoryId: current.categoryId, daily: false, payWithCredits, excludeId: id });
        await updateOwnedListing(tx, id, ownerId, current.status, {
          status: target, publishedAt: now, paidCredits: price, expiresAt: addDays(now, category.displayDays),
        });
        await spendForListing(tx, ownerId, id, price, `Kích hoạt lại tin · ${current.title}`);
        return listingRepository.findSelected(tx, id);
      }
      // Hiện lại tin còn hạn: tin miễn phí cần còn suất, hết suất thì trả xu (tin đã trả xu giữ suất của nó)
      const price = current.paidCredits === 0
        ? await assertPostingSlot(tx, ownerId, now, { categoryId: current.categoryId, daily: false, payWithCredits, excludeId: id })
        : 0;
      await updateOwnedListing(tx, id, ownerId, current.status, {
        status: target, ...(price > 0 && { paidCredits: price }),
        ...(current.expiresAt === null && { expiresAt: addDays(now, category.displayDays) }),
      });
      await spendForListing(tx, ownerId, id, price, `Hiện lại tin vượt hạn mức · ${current.title}`);
      return listingRepository.findSelected(tx, id);
    }
    await updateOwnedListing(tx, id, ownerId, current.status, { status: target });
    return listingRepository.findSelected(tx, id);
  });
  return toOwnerListingDto(listing);
}

/**
 * Gia hạn tin đang hiển thị thêm Category.displayDays ngày, trả Category.extraListingCredits xu.
 * Còn hơn một kỳ hiển thị thì 409 EXTEND_TOO_EARLY; thiếu xu thì 409 NOT_ENOUGH_CREDITS.
 */
export async function extendListing(ownerId: string, id: string) {
  const listing = await withQuotaTransaction(async (tx) => {
    const now = new Date();
    const current = await requireOwnedListing(tx, id, ownerId);
    if (current.status !== ListingStatus.AVAILABLE) {
      throw new AppError(409, 'LISTING_NOT_EXTENDABLE', 'Chỉ gia hạn được tin đang hiển thị.');
    }
    const category = current.categoryId ? await listingRepository.findActiveCategory(tx, current.categoryId) : null;
    if (!category) throw new AppError(409, 'INVALID_LISTING', 'Danh mục không còn được sử dụng.');
    if (!canExtend(current.expiresAt, now, category.displayDays)) {
      throw new AppError(409, 'EXTEND_TOO_EARLY', `Tin còn ${daysLeft(current.expiresAt!, now)} ngày, gia hạn được khi còn tối đa ${category.displayDays} ngày.`);
    }
    await updateOwnedListing(tx, id, ownerId, current.status, { expiresAt: extendedExpiry(current.expiresAt, now, category.displayDays) });
    await spendForListing(tx, ownerId, id, category.extraListingCredits, `Gia hạn tin ${category.displayDays} ngày · ${current.title}`);
    return listingRepository.findSelected(tx, id);
  });
  return toOwnerListingDto(listing);
}

/** Gói đẩy tin 1 ngày dùng cho đẩy tin bằng xu (có sẵn từ migration store_promotions) */
const BOOST_PACKAGE_ID = 'bump-1';

/**
 * Đẩy tin đang hiển thị lên đầu. Còn lượt tặng của gói trong tháng thì miễn phí,
 * hết lượt thì trả Category.boostCredits xu (giảm theo gói). Mỗi tin đẩy tối đa 1 lần / ngày:
 * đang trong lượt đẩy thì 409 BOOST_TOO_SOON (details.availableAt); thiếu xu thì 409 NOT_ENOUGH_CREDITS.
 */
export async function boostListing(ownerId: string, id: string) {
  return withQuotaTransaction(async (tx) => {
    const now = new Date();
    const current = await requireOwnedListing(tx, id, ownerId);
    if (current.status !== ListingStatus.AVAILABLE) {
      throw new AppError(409, 'LISTING_NOT_BOOSTABLE', 'Chỉ đẩy được tin đang hiển thị.');
    }
    const category = current.categoryId ? await listingRepository.findActiveCategory(tx, current.categoryId) : null;
    if (!category) throw new AppError(409, 'INVALID_LISTING', 'Danh mục không còn được sử dụng.');
    const running = await findRunningPromotion(tx, id, 'BUMP', now);
    if (running) {
      throw new AppError(409, 'BOOST_TOO_SOON', 'Tin vừa được đẩy, mỗi tin đẩy tối đa 1 lần mỗi ngày.', undefined,
        { availableAt: running.endsAt.toISOString() });
    }
    const [plan, usage] = await Promise.all([storePackageForUser(tx, ownerId, now), storeUsage(tx, ownerId, now)]);
    const free = usage.promotionsThisMonth < plan.package.monthlyPromotionQuota;
    const credits = free ? 0 : boostPrice(category.boostCredits, plan.package.boostDiscountPercent);
    await spendForListing(tx, ownerId, id, credits, `Đẩy tin · ${current.title}`);
    const promotion = await createPromotion(tx, {
      userId: ownerId, listingId: id, packageId: BOOST_PACKAGE_ID, source: free ? 'INCLUDED' : 'PURCHASED',
      startsAt: now, endsAt: addDays(now, 1),
    });
    return { listingId: id, free, credits, startsAt: promotion.startsAt, endsAt: promotion.endsAt,
      freeLeft: Math.max(0, plan.package.monthlyPromotionQuota - usage.promotionsThisMonth - (free ? 1 : 0)) };
  });
}

/** Tin của chủ đang hiển thị, kèm chuyên mục còn dùng; dùng cho tin ưu tiên */
async function requireFeaturable(tx: Db, id: string, ownerId: string) {
  const current = await requireOwnedListing(tx, id, ownerId);
  if (current.status !== ListingStatus.AVAILABLE) {
    throw new AppError(409, 'LISTING_NOT_FEATURABLE', 'Chỉ đưa tin đang hiển thị lên Hot sale.');
  }
  const category = current.categoryId ? await listingRepository.findActiveCategory(tx, current.categoryId) : null;
  if (!category) throw new AppError(409, 'INVALID_LISTING', 'Danh mục không còn được sử dụng.');
  return { current, category };
}

/**
 * Báo giá tin ưu tiên (Hot sale): các gói FEATURED đang bán với giá xu theo nhóm chuyên mục
 * và giảm giá của gói tài khoản, số xu đang có, và hạn tin ưu tiên đang chạy (nếu có).
 */
export async function getFeatureQuote(ownerId: string, id: string) {
  return listingRepository.transaction(async (tx) => {
    const now = new Date();
    const { category } = await requireFeaturable(tx, id, ownerId);
    const [plan, packages, running, available] = await Promise.all([
      storePackageForUser(tx, ownerId, now), findActivePackagesOfKind(tx, 'FEATURED'),
      findRunningPromotion(tx, id, 'FEATURED', now), availableCredits(tx, ownerId)]);
    const discountPercent = plan.package.boostDiscountPercent;
    return {
      listingId: id, discountPercent, available, runningUntil: running?.endsAt ?? null,
      options: packages.map((p) => ({ packageId: p.id, durationDays: p.durationDays,
        credits: featurePrice(Number(p.price), category.boostCredits, discountPercent) })),
    };
  });
}

/**
 * Mua tin ưu tiên bằng xu: tin đứng đầu danh sách và hiện ở mục Hot sale trong [durationDays] ngày.
 * Đang có tin ưu tiên chạy thì 409 FEATURE_ALREADY_ACTIVE (details.availableAt), thiếu xu thì 409 NOT_ENOUGH_CREDITS.
 */
export async function featureListing(ownerId: string, id: string, packageId: string) {
  return withQuotaTransaction(async (tx) => {
    const now = new Date();
    const { current, category } = await requireFeaturable(tx, id, ownerId);
    const promotionPackage = await findActivePackage(tx, packageId);
    if (!promotionPackage || promotionPackage.kind !== 'FEATURED') {
      throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Gói tin ưu tiên không còn bán.');
    }
    const running = await findRunningPromotion(tx, id, 'FEATURED', now);
    if (running) {
      throw new AppError(409, 'FEATURE_ALREADY_ACTIVE', 'Tin đang ở mục Hot sale.', undefined,
        { availableAt: running.endsAt.toISOString() });
    }
    const plan = await storePackageForUser(tx, ownerId, now);
    const credits = featurePrice(Number(promotionPackage.price), category.boostCredits, plan.package.boostDiscountPercent);
    await spendForListing(tx, ownerId, id, credits, `Tin ưu tiên ${promotionPackage.durationDays} ngày · ${current.title}`);
    const promotion = await createPromotion(tx, {
      userId: ownerId, listingId: id, packageId, source: 'PURCHASED',
      startsAt: now, endsAt: addDays(now, promotionPackage.durationDays),
    });
    return { listingId: id, packageId, credits, startsAt: promotion.startsAt, endsAt: promotion.endsAt };
  });
}

/** Hạn mức đăng tin cho màn đăng tin */
export const getPostingQuota = (ownerId: string) =>
  listingRepository.transaction((tx) => postingQuota(tx, ownerId, new Date()));

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
