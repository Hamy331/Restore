import { StoreTier } from '@prisma/client';
import { audit } from '../../admin/admin.service.js';
import { AppError } from '../../../common/errors/app-error.js';
import type { PromotionPackageInput, PurchaseInput } from '../commerce.dto.js';
import { DAY_MS } from '../commerce.type.js';
import * as promotionRepository from '../repositories/promotion.repository.js';
import { assertBuyerActive, assertPending, auditDecision, markConfirmed, rejectOrder } from './order-approval.service.js';
import { storePackageForUser, storeUsage, withQuotaTransaction } from './quota.service.js';

/* ---------- Gói đẩy tin ---------- */

export const listPackages = () => promotionRepository.findAllPackages();

export async function createPackage(actorId: string, input: PromotionPackageInput) {
  return withQuotaTransaction(async (tx) => {
    const item = await promotionRepository.createPackage(tx, input);
    await audit(tx, actorId, 'CREATE', 'PROMOTION_PACKAGE', item.id, item.name);
    return item;
  });
}

/** Gói đã có giao dịch chỉ được sửa tên, giá và trạng thái bán */
export async function updatePackage(actorId: string, id: string, input: PromotionPackageInput) {
  return withQuotaTransaction(async (tx) => {
    const existing = await promotionRepository.findPackageWithUsage(tx, id);
    if (!existing) throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Không tìm thấy gói quảng cáo.');
    if ((existing._count.promotions || existing._count.orders) &&
        (existing.kind !== input.kind || existing.durationDays !== input.durationDays || existing.priority !== input.priority)) {
      throw new AppError(409, 'PROMOTION_PACKAGE_IN_USE', 'Gói đã có giao dịch. Chỉ được sửa tên, giá và trạng thái bán.');
    }
    if (!await promotionRepository.updatePackage(tx, id, input)) {
      throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Không tìm thấy gói quảng cáo.');
    }
    const updated = await promotionRepository.findPackage(tx, id);
    await audit(tx, actorId, 'UPDATE', 'PROMOTION_PACKAGE', id, input.name, existing, updated);
    return updated;
  });
}

/* ---------- Đẩy tin ---------- */

export const listMine = (userId: string) => promotionRepository.findMyPromotions(userId);

/** Dùng lượt đẩy tin kèm gói cửa hàng (chỉ cho tin thuộc danh mục cửa hàng) */
export async function redeem(userId: string, { listingId, packageId }: PurchaseInput) {
  return withQuotaTransaction(async (tx) => {
    const now = new Date();
    const [listing, promotionPackage, current, usage] = await Promise.all([
      promotionRepository.findAvailableListingOf(tx, listingId, userId),
      promotionRepository.findActivePackage(tx, packageId),
      storePackageForUser(tx, userId, now),
      storeUsage(tx, userId, now),
    ]);
    if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đang hiển thị của bạn.');
    if (!promotionPackage) throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Gói quảng cáo không còn bán.');
    if (current.package.tier === StoreTier.PERSONAL || !listing.categoryId || listing.categoryId !== current.category?.id) {
      throw new AppError(403, 'STORE_CATEGORY_REQUIRED', 'Lượt quảng cáo kèm gói chỉ áp dụng trong danh mục cửa hàng.');
    }
    if (usage.promotionsThisMonth >= current.package.monthlyPromotionQuota) {
      throw new AppError(409, 'PROMOTION_QUOTA_EXHAUSTED', 'Bạn đã dùng hết lượt quảng cáo trong tháng.');
    }
    if (await promotionRepository.findRunningPromotion(tx, listingId, promotionPackage.kind, now)) {
      throw new AppError(409, 'PROMOTION_ALREADY_ACTIVE', 'Tin đang có quảng cáo cùng loại.');
    }
    return promotionRepository.createPromotion(tx, {
      userId, listingId, packageId, source: 'INCLUDED',
      startsAt: now, endsAt: new Date(now.getTime() + promotionPackage.durationDays * DAY_MS),
    });
  });
}

/* ---------- Đơn mua đẩy tin ---------- */

/** Đặt mua gói đẩy tin cho một tin đang hiển thị; mỗi tin chỉ có một đơn chờ */
export async function createOrder(userId: string, { listingId, packageId }: PurchaseInput) {
  return withQuotaTransaction(async (tx) => {
    const [listing, promotionPackage, pending] = await Promise.all([
      promotionRepository.findAvailableListingOf(tx, listingId, userId),
      promotionRepository.findActivePackage(tx, packageId),
      promotionRepository.findPendingOrderFor(tx, userId, listingId),
    ]);
    if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đang hiển thị của bạn.');
    if (!promotionPackage) throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Gói quảng cáo không còn bán.');
    if (pending) throw new AppError(409, 'PROMOTION_ORDER_PENDING', 'Tin này đã có đơn quảng cáo chờ xác nhận.');
    return promotionRepository.createOrder(tx, { userId, listingId, packageId, amount: promotionPackage.price });
  });
}

export const listPendingOrders = () => promotionRepository.findPendingOrders();

/** Xác nhận đơn đã thanh toán: tạo quảng cáo, nối tiếp sau quảng cáo cùng loại đang chạy (nếu có) */
export async function confirmOrder(actorId: string, id: string, reason: unknown) {
  return withQuotaTransaction(async (tx) => {
    const now = new Date();
    const order = await promotionRepository.findOrderForApproval(tx, id);
    assertPending('PROMOTION_ORDER', order);
    if (order.listing.ownerId !== order.userId || order.listing.status !== 'AVAILABLE') {
      throw new AppError(409, 'LISTING_UNAVAILABLE', 'Tin không còn đủ điều kiện quảng cáo.');
    }
    assertBuyerActive('PROMOTION_ORDER', order.user);
    await markConfirmed(tx, 'PROMOTION_ORDER', id, now);
    const latest = await promotionRepository.findRunningPromotion(tx, order.listingId, order.package.kind, now);
    const startsAt = latest ? latest.endsAt : now;
    await auditDecision(tx, 'PROMOTION_ORDER', actorId, id, 'CONFIRM', reason, { status: 'PENDING' }, { status: 'CONFIRMED', amount: order.amount });
    return promotionRepository.createPromotion(tx, {
      userId: order.userId, listingId: order.listingId, packageId: order.packageId,
      source: 'PURCHASED', orderId: id, startsAt,
      endsAt: new Date(startsAt.getTime() + order.package.durationDays * DAY_MS),
    });
  });
}

export const rejectPromotionOrder = (actorId: string, id: string, reason: unknown) => rejectOrder('PROMOTION_ORDER', actorId, id, reason);
