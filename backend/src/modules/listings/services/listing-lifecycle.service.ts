import { ListingStatus } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { prisma } from '../../../lib/prisma.js';
import { storePackageForUser, withQuotaTransaction } from '../../commerce/index.js';
import { captureListingHold, holdForListing } from '../../credits/index.js';
import { AUTO_EXTEND_DAYS, extraDaysCredits } from '../display-pricing.js';
import { addableDays, addDays, isExpired, normalizeTitle } from '../listing-lifecycle.js';
import type { Db } from '../repositories/listing.repository.js';
import { findDayPacks } from '../repositories/posting-quota.repository.js';

/** Ẩn các tin đang hiển thị đã quá hạn; trả về số tin vừa ẩn */
export async function expireDueListings(now = new Date()) {
  const changed = await prisma.listing.updateMany({
    where: { status: ListingStatus.AVAILABLE, expiresAt: { lte: now } },
    data: { status: ListingStatus.HIDDEN },
  });
  return changed.count;
}

/** Hiện các tin đã duyệt tới ngày hẹn bắt đầu (HIDDEN + startsAt đã qua, còn hạn); trả về số tin vừa hiện */
export async function publishScheduledListings(now = new Date()) {
  const changed = await prisma.listing.updateMany({
    where: { status: ListingStatus.HIDDEN, startsAt: { lte: now }, expiresAt: { gt: now } },
    data: { status: ListingStatus.AVAILABLE, startsAt: null, publishedAt: now },
  });
  return changed.count;
}

/**
 * Tự gia hạn AUTO_EXTEND_DAYS ngày cho tin bật autoExtend còn dưới 1 ngày: gói vẫn có tự gia hạn và đủ xu thì trừ xu,
 * thiếu xu thì để tin hết hạn như thường; gói không còn tự gia hạn thì tắt cờ. Trả về số tin đã gia hạn.
 */
export async function autoExtendDueListings(now = new Date()) {
  const due = await prisma.listing.findMany({
    where: { status: ListingStatus.AVAILABLE, autoExtend: true, expiresAt: { gt: now, lte: addDays(now, 1) } },
    select: { id: true },
  });
  let extended = 0;
  for (const { id } of due) {
    try {
      const done = await withQuotaTransaction(async (tx) => {
        const listing = await tx.listing.findUnique({ where: { id }, include: { category: true } });
        if (!listing?.autoExtend || listing.status !== ListingStatus.AVAILABLE || !listing.expiresAt || !listing.category) return false;
        if (listing.expiresAt.getTime() > addDays(now, 1).getTime()) return false;
        const [plan, packs] = await Promise.all([storePackageForUser(tx, listing.ownerId, now), findDayPacks(tx)]);
        if (!plan.package.autoExtend) {
          await tx.listing.update({ where: { id }, data: { autoExtend: false } });
          return false;
        }
        if (addableDays(listing.expiresAt, now, listing.category.maxDisplayDays) < AUTO_EXTEND_DAYS) return false;
        const credits = extraDaysCredits(AUTO_EXTEND_DAYS, listing.category, packs, plan.package);
        await spendForListing(tx, listing.ownerId, id, credits, `Tự gia hạn tin ${AUTO_EXTEND_DAYS} ngày · ${listing.title}`);
        await tx.listing.update({ where: { id }, data: { expiresAt: addDays(listing.expiresAt, AUTO_EXTEND_DAYS) } });
        return true;
      });
      if (done) extended++;
    } catch (error) {
      // Thiếu xu: bỏ qua, tin hết hạn như thường
      if ((error as { code?: string }).code !== 'NOT_ENOUGH_CREDITS') throw error;
    }
  }
  return extended;
}

/** Trừ hẳn [price] xu cho tin không cần duyệt lại (kích hoạt lại, gia hạn) */
export async function spendForListing(tx: Db, userId: string, listingId: string, price: number, note: string) {
  if (price <= 0) return;
  await holdForListing(tx, { userId, listingId, amount: price, note: note.slice(0, 200) });
  await captureListingHold(tx, listingId);
}

/** Trạng thái tin đang chiếm chỗ hiển thị: đăng trùng với các tin này bị chặn */
const ACTIVE = new Set<ListingStatus>([ListingStatus.PENDING, ListingStatus.AVAILABLE, ListingStatus.RESERVED]);

/**
 * Chặn đăng tin trùng tiêu đề (đã chuẩn hoá) trong cùng chuyên mục với tin của chính mình.
 * - Trùng tin đang chờ duyệt / hiển thị: 409 DUPLICATE_LISTING.
 * - Trùng tin đã ẩn / hết hạn: 409 DUPLICATE_INACTIVE để app gợi ý kích hoạt lại tin cũ, trừ khi [allowDuplicate].
 */
export async function assertNotDuplicate(tx: Db, ownerId: string, data: { title: string; categoryId: string },
  options: { excludeId?: string; allowDuplicate?: boolean; now: Date }) {
  const title = normalizeTitle(data.title);
  if (!title) return;
  const candidates = await tx.listing.findMany({
    where: {
      ownerId, categoryId: data.categoryId, ...(options.excludeId && { id: { not: options.excludeId } }),
      status: { in: [...ACTIVE, ListingStatus.HIDDEN] },
    },
    select: { id: true, title: true, status: true, expiresAt: true },
  });
  const same = candidates.filter((item) => normalizeTitle(item.title) === title);
  const active = same.find((item) => ACTIVE.has(item.status));
  if (active) {
    throw new AppError(409, 'DUPLICATE_LISTING', 'Bạn đã có tin giống vậy đang hiển thị hoặc chờ duyệt.', 'title',
      { listingId: active.id });
  }
  const inactive = same[0];
  if (inactive && !options.allowDuplicate) {
    throw new AppError(409, 'DUPLICATE_INACTIVE', 'Bạn có tin giống vậy đã ẩn hoặc hết hạn. Kích hoạt lại tin cũ để giữ lượt xem?', 'title',
      { listingId: inactive.id, expired: isExpired(inactive.expiresAt, options.now) });
  }
}
