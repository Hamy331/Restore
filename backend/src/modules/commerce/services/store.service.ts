import { StoreTier } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import type { StoreOrderInput } from '../commerce.dto.js';
import { MONTH_MS, PURCHASABLE_STORE_TIERS } from '../commerce.type.js';
import * as storeRepository from '../repositories/store.repository.js';
import { transaction } from '../repositories/quota.repository.js';
import { assertBuyerActive, assertPending, auditDecision, markConfirmed, rejectOrder } from './order-approval.service.js';
import { storePackageForUser, storeUsage, withQuotaTransaction } from './quota.service.js';

export const listCategories = () => storeRepository.findAllCategories();

export const listPackages = () => storeRepository.findPackagesByTier([...PURCHASABLE_STORE_TIERS]);

/** Gói đang dùng, lượt đã dùng, lượt còn lại và đơn đang chờ của người dùng */
export async function getMyStore(userId: string) {
  const now = new Date();
  return transaction(async (tx) => {
    const current = await storePackageForUser(tx, userId, now);
    const usage = await storeUsage(tx, userId, now);
    const pendingOrder = await storeRepository.findLatestPendingOrderSummary(tx, userId);
    return {
      package: current.package,
      category: current.category,
      endsAt: current.endsAt,
      pendingOrder,
      usage,
      remaining: {
        listingsToday: Math.max(0, current.package.dailyListingLimit - usage.today),
        activeListings: Math.max(0, current.package.activeListingLimit - usage.active),
        promotionsThisMonth: Math.max(0, current.package.monthlyPromotionQuota - usage.promotionsThisMonth),
      },
    };
  });
}

/** Đặt mua gói cửa hàng cho một danh mục; mỗi người chỉ có một đơn chờ */
export async function createOrder(userId: string, { packageId, categoryId }: StoreOrderInput) {
  return withQuotaTransaction(async (tx) => {
    const [storePackage, category, pending] = await Promise.all([
      storeRepository.findPackage(tx, packageId),
      storeRepository.findActiveCategory(tx, categoryId),
      storeRepository.findPendingOrder(tx, userId),
    ]);
    if (!storePackage || storePackage.tier === StoreTier.PERSONAL || !category) {
      throw new AppError(404, 'STORE_PACKAGE_NOT_FOUND', 'Gói cửa hàng hoặc danh mục không tồn tại.');
    }
    if (pending) throw new AppError(409, 'STORE_ORDER_PENDING', 'Bạn đã có đơn gói cửa hàng đang chờ xác nhận.');
    return storeRepository.createOrder(tx, { userId, packageId, categoryId, amount: storePackage.monthlyPrice });
  });
}

export const listPendingOrders = () => storeRepository.findPendingOrders();

/**
 * Xác nhận đơn đã thanh toán: kích hoạt gói 30 ngày.
 * Mua lại đúng gói và danh mục đang chạy thì cộng dồn từ ngày hết hạn cũ.
 */
export async function confirmOrder(actorId: string, id: string, reason: unknown) {
  return withQuotaTransaction(async (tx) => {
    const now = new Date();
    const order = await storeRepository.findOrderForApproval(tx, id);
    assertPending('STORE_ORDER', order);
    assertBuyerActive('STORE_ORDER', order.user);
    if (!order.category.active) {
      throw new AppError(409, 'STORE_CATEGORY_UNAVAILABLE', 'Danh mục đã ngừng sử dụng. Chưa thể xác nhận đơn này.');
    }
    await markConfirmed(tx, 'STORE_ORDER', id, now);
    const old = await storeRepository.findSubscription(tx, order.userId);
    const base = old && old.endsAt > now && old.packageId === order.packageId && old.categoryId === order.categoryId ? old.endsAt : now;
    const subscription = await storeRepository.upsertSubscription(tx, order.userId, {
      packageId: order.packageId, categoryId: order.categoryId, startsAt: now, endsAt: new Date(base.getTime() + MONTH_MS),
    });
    await auditDecision(tx, 'STORE_ORDER', actorId, id, 'CONFIRM', reason, { status: 'PENDING' }, { status: 'CONFIRMED', amount: order.amount });
    return { orderId: id, subscription };
  });
}

export const rejectStoreOrder = (actorId: string, id: string, reason: unknown) => rejectOrder('STORE_ORDER', actorId, id, reason);
