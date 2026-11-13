import { ListingStatus, Prisma } from '@prisma/client';
import { hasPermission, PERMISSION } from '../../../common/auth/permissions.js';
import { AppError } from '../../../common/errors/app-error.js';
import { createPromotion, findActivePackage, findActivePackagesOfKind, findListingPromotions, findPromotionKindsSince, findRunningPromotion,
  findRunningPromotionsOf, utcMonthStart, storePackageForUser, storeUsage,
  withQuotaTransaction } from '../../commerce/index.js';
import { availableCredits } from '../../credits/index.js';
import type { AuthRequest } from '../../../middlewares/auth.middleware.js';
import { toCategoryDto } from '../../catalog/catalog.dto.js';
import { ListingInput, MineQuery, toListingDto, toOwnerListingDto } from '../listing.dto.js';
import { LISTING_EDITABLE } from '../listing.type.js';
import { validateAttributes } from '../listing.validator.js';
import * as listingRepository from '../repositories/listing.repository.js';
import type { Db } from '../repositories/listing.repository.js';
import { addableDays, addDays, boostPrice, categoryHasCondition, featurePrice, isExpired } from '../listing-lifecycle.js';
import { extraDaysCredits, freeDaysFor, MAX_START_DELAY_DAYS, postingDisplayQuote } from '../display-pricing.js';
import { COUNTED_STATUSES, findDayPacks } from '../repositories/posting-quota.repository.js';
import { assertNotDuplicate, spendForListing } from './listing-lifecycle.service.js';
import { removeStoredImages, revisionOnlyImages } from './image.service.js';
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

export { categoryHasCondition };

/**
 * Danh mục còn dùng, tình trạng chưa ngừng, thuộc tính đúng metadata danh mục.
 * Danh mục không hỏi tình trạng thì bỏ tình trạng ([data.condition] thành null), còn lại bắt buộc.
 */
export async function assertPublishable(tx: Db, data: Pick<ListingInput, 'categoryId' | 'condition' | 'attributes'>) {
  const category = await listingRepository.findActiveCategory(tx, data.categoryId);
  if (!category) throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
  if (!categoryHasCondition(category.metadata)) data.condition = null;
  else if (!data.condition) throw new AppError(400, 'INVALID_LISTING', 'Tình trạng không hợp lệ.', 'condition');
  if (data.condition && (await listingRepository.findConditionPolicy(tx, data.condition))?.active === false) {
    throw new AppError(400, 'INVALID_CONDITION', 'Tình trạng đã ngừng sử dụng.');
  }
  validateAttributes(data.attributes, category.metadata, true);
  return category;
}

/**
 * Giá gốc (bán giảm giá): chỉ gói Cửa hàng (PRO), phải cao hơn giá bán. Sửa tin đã đăng thì giá gốc không được
 * cao hơn giá gốc cũ (hoặc giá bán cũ nếu trước đó chưa giảm), để không khai khống mức giảm.
 */
export async function assertOriginalPrice(tx: Db, ownerId: string, now: Date,
  data: { price: string; originalPrice: string | null }, current?: { price: Prisma.Decimal; originalPrice: Prisma.Decimal | null }) {
  if (data.originalPrice === null) return;
  const plan = await storePackageForUser(tx, ownerId, now);
  if (plan.package.tier !== 'PRO') {
    throw new AppError(403, 'ORIGINAL_PRICE_NOT_ALLOWED', 'Chỉ gói Cửa hàng được đăng giá gốc để bán giảm giá.', 'originalPrice');
  }
  if (BigInt(data.originalPrice) <= BigInt(data.price)) {
    throw new AppError(400, 'INVALID_LISTING', 'Giá gốc phải cao hơn giá bán.', 'originalPrice');
  }
  if (!current) return;
  const cap = BigInt((current.originalPrice ?? current.price).toFixed(0));
  const max = cap > BigInt(current.price.toFixed(0)) ? cap : BigInt(current.price.toFixed(0));
  if (BigInt(data.originalPrice) > max) {
    throw new AppError(400, 'ORIGINAL_PRICE_RAISED', `Giá gốc không được cao hơn ${max.toString()} đ (giá trước khi sửa).`,
      'originalPrice', { maxOriginalPrice: max.toString() });
  }
}

type DisplayCategory = { displayDays: number; maxDisplayDays: number; dayPackCredits: number };

/** Gói tài khoản và mốc ngày dùng để tính giá ngày hiển thị */
async function displayPricing(tx: Db, ownerId: string, now: Date) {
  const [plan, packs] = await Promise.all([storePackageForUser(tx, ownerId, now), findDayPacks(tx)]);
  return { plan: plan.package, packs };
}

/**
 * Thời gian hiển thị lúc đăng: số ngày chọn (null = miễn phí) không quá tối đa của chuyên mục,
 * ngày hẹn bắt đầu trong MAX_START_DELAY_DAYS ngày tới (đã qua thì hiện ngay khi duyệt). Trả về ngày phải trả và giá.
 */
export async function resolveDisplay(tx: Db, ownerId: string, now: Date, category: DisplayCategory,
  data: { displayDays: number | null; startsAt: Date | null }) {
  if (data.displayDays !== null && data.displayDays > category.maxDisplayDays) {
    throw new AppError(400, 'INVALID_LISTING', `Chuyên mục này hiển thị tối đa ${category.maxDisplayDays} ngày.`, 'displayDays',
      { maxDisplayDays: category.maxDisplayDays });
  }
  const startsAt = data.startsAt && data.startsAt.getTime() > now.getTime() ? data.startsAt : null;
  if (startsAt && startsAt.getTime() > addDays(now, MAX_START_DELAY_DAYS).getTime()) {
    throw new AppError(400, 'INVALID_LISTING', `Chỉ hẹn ngày bắt đầu trong ${MAX_START_DELAY_DAYS} ngày tới.`, 'startsAt');
  }
  const { plan, packs } = await displayPricing(tx, ownerId, now);
  return { ...postingDisplayQuote(data.displayDays, category, packs, plan), startsAt };
}

/* ---------- Tin đăng ---------- */

/**
 * Đăng tin mới, chờ duyệt (PENDING). Hết suất miễn phí thì cần [payWithCredits]:
 * xu được giữ ngay, duyệt thì trừ hẳn, từ chối thì hoàn.
 */
export async function createListing(ownerId: string, data: ListingInput, payWithCredits = false, allowDuplicate = false) {
  const listing = await withQuotaTransaction(async (tx) => {
    const now = new Date();
    const category = await assertPublishable(tx, data);
    await assertNotDuplicate(tx, ownerId, data, { allowDuplicate, now });
    const price = await assertPostingSlot(tx, ownerId, now, { categoryId: data.categoryId, daily: true, payWithCredits });
    await assertOriginalPrice(tx, ownerId, now, data);
    const display = await resolveDisplay(tx, ownerId, now, category, data);
    const created = await listingRepository.createListing(
      { ...data, ownerId, images: [], publishedAt: now, status: ListingStatus.PENDING, paidCredits: price,
        displayDays: display.displayDays, startsAt: display.startsAt, paidDays: display.paidDays }, tx);
    await chargeListing(tx, ownerId, created.id, price, data.title, display);
    return created;
  });
  return toOwnerListingDto(listing);
}

/** Tin đã duyệt (đang hiển thị / đã ẩn): sửa thì tạo bản sửa chờ duyệt, tin vẫn hiện bản cũ */
export const REVISABLE: readonly ListingStatus[] = [ListingStatus.AVAILABLE, ListingStatus.HIDDEN];

/**
 * Sửa tin đã đăng.
 * - Tin đã duyệt (đang hiển thị / đã ẩn): lưu thành bản sửa chờ duyệt (ListingRevision), tin vẫn hiện bản cũ
 *   tới khi duyệt; từ chối thì giữ bản cũ. Không đổi được chuyên mục; thời gian hiển thị, xu đã trả,
 *   đẩy tin, Hot sale, giảm giá theo gói giữ nguyên. Ảnh sửa qua /:id/images sau đó cũng vào bản sửa.
 * - Tin chưa duyệt (chờ duyệt / bị từ chối): sửa thẳng, tin quay lại chờ duyệt.
 *   Tin miễn phí cần suất lại khi đang không chiếm suất (bị từ chối) hoặc đổi chuyên mục.
 *   Tin đã trả xu giữ nguyên suất nhưng không được đổi chuyên mục (giá mỗi chuyên mục khác nhau).
 */
export async function updateListing(ownerId: string, id: string, data: ListingInput, payWithCredits = false) {
  const listing = await withQuotaTransaction(async (tx) => {
    const current = await requireOwnedListing(tx, id, ownerId);
    if (!LISTING_EDITABLE.includes(current.status)) {
      throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Chỉ sửa được tin đang hiển thị, đã ẩn, chờ duyệt hoặc bị từ chối.');
    }
    const categoryChanged = current.categoryId !== data.categoryId;
    if (REVISABLE.includes(current.status)) {
      if (categoryChanged) {
        throw new AppError(409, 'CATEGORY_LOCKED', 'Tin đã duyệt không đổi được chuyên mục.', 'categoryId');
      }
      await assertPublishable(tx, data);
      await assertOriginalPrice(tx, ownerId, new Date(), data, current);
      await listingRepository.upsertRevision(tx, id, {
        status: 'PENDING', reviewReason: null, submittedAt: new Date(),
        title: data.title, description: data.description, price: data.price, originalPrice: data.originalPrice,
        isNegotiable: data.isNegotiable, condition: data.condition, allowSale: data.allowSale,
        allowExchange: data.allowExchange, exchangeWish: data.exchangeWish,
        attributes: data.attributes as Prisma.InputJsonValue, location: (data.location ?? Prisma.JsonNull) as Prisma.InputJsonValue,
        // Sửa lần đầu: lấy ảnh của tin; đang có bản sửa thì giữ ảnh của bản sửa
        images: current.revision?.images ?? current.images,
      });
      return listingRepository.findSelected(tx, id);
    }
    await assertPublishable(tx, data);
    await assertOriginalPrice(tx, ownerId, new Date(), data, current);
    // Sửa tin không đổi thời gian hiển thị đã chọn / đã trả; muốn thêm ngày thì gia hạn
    data.displayDays = current.displayDays;
    data.startsAt = current.startsAt;
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

/** Bỏ bản sửa của tin (chờ duyệt hoặc bị từ chối): tin giữ nguyên bản đang hiển thị */
export async function discardRevision(ownerId: string, id: string) {
  const { listing, removed } = await listingRepository.transaction(async (tx) => {
    const current = await requireOwnedListing(tx, id, ownerId);
    if (!current.revision) throw new AppError(404, 'EDIT_NOT_FOUND', 'Tin không có bản sửa nào.');
    const revision = await listingRepository.deleteRevision(tx, id);
    return { listing: await listingRepository.findSelected(tx, id),
      removed: revisionOnlyImages(revision?.images ?? [], current.images) };
  });
  await removeStoredImages(removed);
  return toOwnerListingDto(listing);
}

/** Ẩn, hiện lại, đánh dấu đã bán / đã trao đổi */
export async function changeStatus(ownerId: string, id: string, target: ListingStatus, payWithCredits = false) {
  let dropped: string[] = [];
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
        const { plan } = await displayPricing(tx, ownerId, now);
        await updateOwnedListing(tx, id, ownerId, current.status, {
          status: target, publishedAt: now, paidCredits: price, startsAt: null, expiresAt: addDays(now, freeDaysFor(category, plan)),
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
        // Tin đang chờ ngày hẹn mà người bán cho hiện sớm: bắt đầu hiển thị luôn, giữ ngày hết hạn
        ...(current.startsAt && { startsAt: null, publishedAt: now }),
        ...(current.expiresAt === null && { expiresAt: addDays(now, category.displayDays) }),
      });
      await spendForListing(tx, ownerId, id, price, `Hiện lại tin vượt hạn mức · ${current.title}`);
      return listingRepository.findSelected(tx, id);
    }
    await updateOwnedListing(tx, id, ownerId, current.status, { status: target });
    // Đã bán / đã trao đổi: bản sửa chưa duyệt không còn dùng
    if (target === ListingStatus.SOLD || target === ListingStatus.EXCHANGED) {
      const revision = await listingRepository.deleteRevision(tx, id);
      dropped = revisionOnlyImages(revision?.images ?? [], current.images);
    }
    return listingRepository.findSelected(tx, id);
  });
  await removeStoredImages(dropped);
  return toOwnerListingDto(listing);
}

/**
 * Gia hạn tin đang hiển thị (hoặc đang chờ ngày hẹn) thêm [days] ngày, trả xu theo giá ngày của chuyên mục
 * (mua đúng mốc 30 / 60 / 90 ngày rẻ hơn, gói cao được giảm). Hạn mới không quá Category.maxDisplayDays ngày tính từ hôm nay:
 * vượt thì 409 EXTEND_TOO_LONG (details.addableDays); thiếu xu thì 409 NOT_ENOUGH_CREDITS.
 */
export async function extendListing(ownerId: string, id: string, days: number) {
  const listing = await withQuotaTransaction(async (tx) => {
    const now = new Date();
    const current = await requireOwnedListing(tx, id, ownerId);
    const waiting = current.status === ListingStatus.HIDDEN && current.startsAt !== null;
    if (current.status !== ListingStatus.AVAILABLE && !waiting) {
      throw new AppError(409, 'LISTING_NOT_EXTENDABLE', 'Chỉ gia hạn được tin đang hiển thị.');
    }
    const category = current.categoryId ? await listingRepository.findActiveCategory(tx, current.categoryId) : null;
    if (!category) throw new AppError(409, 'INVALID_LISTING', 'Danh mục không còn được sử dụng.');
    const base = current.expiresAt && !isExpired(current.expiresAt, now) ? current.expiresAt : null;
    const addable = addableDays(base, now, category.maxDisplayDays);
    if (days > addable) {
      throw new AppError(409, 'EXTEND_TOO_LONG', addable > 0
        ? `Tin chỉ gia hạn thêm được tối đa ${addable} ngày (hiển thị tối đa ${category.maxDisplayDays} ngày).`
        : `Tin đã hiển thị tối đa ${category.maxDisplayDays} ngày, chưa gia hạn thêm được.`,
      'days', { addableDays: addable, maxDisplayDays: category.maxDisplayDays });
    }
    const { plan, packs } = await displayPricing(tx, ownerId, now);
    const credits = extraDaysCredits(days, category, packs, plan);
    await updateOwnedListing(tx, id, ownerId, current.status, { expiresAt: addDays(base ?? now, days) });
    await spendForListing(tx, ownerId, id, credits, `Gia hạn tin ${days} ngày · ${current.title}`);
    return listingRepository.findSelected(tx, id);
  });
  return toOwnerListingDto(listing);
}

/** Bật / tắt tự gia hạn 30 ngày khi tin sắp hết hạn; chỉ gói có StorePackage.autoExtend (Cửa hàng) mới bật được */
export async function setAutoExtend(ownerId: string, id: string, enabled: boolean) {
  const listing = await withQuotaTransaction(async (tx) => {
    const current = await requireOwnedListing(tx, id, ownerId);
    if (enabled && !(await storePackageForUser(tx, ownerId, new Date())).package.autoExtend) {
      throw new AppError(403, 'AUTO_EXTEND_NOT_AVAILABLE', 'Tự gia hạn chỉ có ở gói Cửa hàng.');
    }
    await updateOwnedListing(tx, id, ownerId, current.status, { autoExtend: enabled });
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

/** Số tin tối đa trang Boost trả về (tin đang hiển thị, sắp hết hạn trước) */
const PROMOTION_HUB_LIMIT = 100;

/**
 * Trang Boost của tôi: tất cả tin đang hiển thị (sắp hết hạn trước) kèm hạn đẩy tin / Hot sale
 * đang chạy và giá đẩy tin theo chuyên mục; lượt đẩy tặng còn lại, số xu, số lượt đã dùng tháng này.
 */
export async function getPromotionHub(ownerId: string) {
  return listingRepository.transaction(async (tx) => {
    const now = new Date();
    const listings = await tx.listing.findMany({
      where: { ownerId, status: ListingStatus.AVAILABLE },
      select: { id: true, title: true, price: true, images: true, categoryId: true, viewCount: true,
        expiresAt: true, autoExtend: true, createdAt: true },
      orderBy: [{ expiresAt: { sort: 'asc', nulls: 'last' } }, { createdAt: 'desc' }],
      take: PROMOTION_HUB_LIMIT,
    });
    const categoryIds = [...new Set(listings.map((l) => l.categoryId).filter((id): id is string => !!id))];
    const [plan, usage, available, running, categories, usedKinds] = await Promise.all([
      storePackageForUser(tx, ownerId, now), storeUsage(tx, ownerId, now), availableCredits(tx, ownerId),
      findRunningPromotionsOf(tx, listings.map((l) => l.id), now),
      tx.category.findMany({ where: { id: { in: categoryIds } }, select: { id: true, boostCredits: true } }),
      findPromotionKindsSince(tx, ownerId, utcMonthStart(now))]);
    const discountPercent = plan.package.boostDiscountPercent;
    const freePerMonth = plan.package.monthlyPromotionQuota;
    const price = new Map(categories.map((c) => [c.id, boostPrice(c.boostCredits, discountPercent)]));
    const until = (listingId: string, kind: 'BUMP' | 'FEATURED') => running
      .filter((p) => p.listingId === listingId && p.package.kind === kind)
      .reduce<Date | null>((max, p) => (!max || p.endsAt > max ? p.endsAt : max), null);
    return {
      available, discountPercent,
      boost: { freeLeft: Math.max(0, freePerMonth - usage.promotionsThisMonth), freePerMonth },
      thisMonth: { boosts: usedKinds.filter((p) => p.package.kind === 'BUMP').length,
        features: usedKinds.filter((p) => p.package.kind === 'FEATURED').length },
      items: listings.map((l) => ({
        id: l.id, title: l.title, price: l.price.toString(), image: l.images[0] ?? null, categoryId: l.categoryId,
        viewCount: l.viewCount, expiresAt: l.expiresAt, autoExtend: l.autoExtend,
        boostCredits: l.categoryId ? price.get(l.categoryId) ?? null : null,
        bumpUntil: until(l.id, 'BUMP'), featuredUntil: until(l.id, 'FEATURED'),
      })),
    };
  });
}

/**
 * Trang quảng bá một tin: giá đẩy tin / Hot sale theo chuyên mục và gói tài khoản, lượt đẩy tặng
 * còn lại, số xu đang có, hạn quảng bá đang chạy và 10 lượt gần nhất. Tin không hiển thị vẫn
 * trả về (promotable = false) để trang báo lý do thay vì lỗi.
 */
export async function getPromotionOverview(ownerId: string, id: string) {
  return listingRepository.transaction(async (tx) => {
    const now = new Date();
    const current = await requireOwnedListing(tx, id, ownerId);
    const category = current.categoryId ? await listingRepository.findActiveCategory(tx, current.categoryId) : null;
    const [plan, usage, packages, bump, featured, available, history] = await Promise.all([
      storePackageForUser(tx, ownerId, now), storeUsage(tx, ownerId, now), findActivePackagesOfKind(tx, 'FEATURED'),
      findRunningPromotion(tx, id, 'BUMP', now), findRunningPromotion(tx, id, 'FEATURED', now),
      availableCredits(tx, ownerId), findListingPromotions(tx, id)]);
    const discountPercent = plan.package.boostDiscountPercent;
    const freePerMonth = plan.package.monthlyPromotionQuota;
    const freeLeft = Math.max(0, freePerMonth - usage.promotionsThisMonth);
    const base = category?.boostCredits ?? 0;
    return {
      listingId: id, title: current.title, price: current.price.toString(), image: current.images[0] ?? null,
      status: current.status, promotable: current.status === ListingStatus.AVAILABLE && !!category,
      available, discountPercent,
      boost: { credits: boostPrice(base, discountPercent), free: freeLeft > 0, freeLeft, freePerMonth,
        runningUntil: bump?.endsAt ?? null },
      feature: { runningUntil: featured?.endsAt ?? null,
        options: packages.map((p) => ({ packageId: p.id, durationDays: p.durationDays,
          credits: featurePrice(Number(p.price), base, discountPercent) })) },
      history: history.map((p) => ({ id: p.id, kind: p.package.kind, packageId: p.packageId,
        durationDays: p.package.durationDays, source: p.source, startsAt: p.startsAt, endsAt: p.endsAt })),
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
