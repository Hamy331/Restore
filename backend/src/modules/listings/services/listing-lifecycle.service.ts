import { ListingStatus } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { prisma } from '../../../lib/prisma.js';
import { captureListingHold, holdForListing } from '../../credits/index.js';
import { isExpired, normalizeTitle } from '../listing-lifecycle.js';
import type { Db } from '../repositories/listing.repository.js';

/** Ẩn các tin đang hiển thị đã quá hạn; trả về số tin vừa ẩn */
export async function expireDueListings(now = new Date()) {
  const changed = await prisma.listing.updateMany({
    where: { status: ListingStatus.AVAILABLE, expiresAt: { lte: now } },
    data: { status: ListingStatus.HIDDEN },
  });
  return changed.count;
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
