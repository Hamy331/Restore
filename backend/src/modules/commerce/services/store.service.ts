import { StoreTier } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { audit } from '../../../common/audit/admin-audit.js';
import { ADMIN_PAGE_SIZE } from '../../../common/validation/admin-input.js';
import type { AdminOrderQuery, StoreOrderInput, StorePackageInput } from '../commerce.dto.js';
import { availableCredits, spendCredits } from '../../credits/credit.hold.js';
import { MONTH_MS, PURCHASABLE_STORE_TIERS } from '../commerce.type.js';
import { planPriceCredits, quotePlan } from '../plan-pricing.js';
import * as storeRepository from '../repositories/store.repository.js';
import { transaction } from '../repositories/quota.repository.js';
import { assertBuyerActive, assertPending, auditDecision, markConfirmed, rejectOrder } from './order-approval.service.js';
import { storePackageForUser, storeUsage, withQuotaTransaction } from './quota.service.js';

export const listCategories = () => storeRepository.findAllCategories();

type PackageRow = Awaited<ReturnType<typeof storeRepository.findPackageOrThrow>>;

/** Gói kèm giá theo xu (1 xu = 1.000 đ) */
const withCredits = <T extends PackageRow>(item: T) => ({ ...item, priceCredits: planPriceCredits(item.monthlyPrice) });

export const listPackages = async () =>
  (await storeRepository.findPackagesByTier([...PURCHASABLE_STORE_TIERS])).map(withCredits);

/** Gói đang dùng, lượt đã dùng, lượt còn lại và đơn đang chờ của người dùng */
export async function getMyStore(userId: string) {
  const now = new Date();
  return transaction(async (tx) => {
    const current = await storePackageForUser(tx, userId, now);
    const usage = await storeUsage(tx, userId, now);
    const pendingOrder = await storeRepository.findLatestPendingOrderSummary(tx, userId);
    return {
      package: withCredits(current.package),
      category: current.category,
      endsAt: current.endsAt,
      pendingOrder,
      usage,
      remaining: {
        listingsToday: Math.max(0, current.package.dailyListingLimit - usage.today),
        activeListings: Math.max(0, current.package.activeListingLimit - usage.active),
        drafts: Math.max(0, current.package.draftLimit - usage.drafts),
        promotionsThisMonth: Math.max(0, current.package.monthlyPromotionQuota - usage.promotionsThisMonth),
      },
    };
  });
}

/** Báo giá mua / gia hạn / nâng cấp sang [packageId]; hạ gói lúc gói cao hơn còn hạn thì 409 */
async function planQuote(tx: Parameters<Parameters<typeof withQuotaTransaction>[0]>[0], userId: string, packageId: string, now: Date) {
  const target = await storeRepository.findPackage(tx, packageId);
  if (!target || target.tier === StoreTier.PERSONAL || !(PURCHASABLE_STORE_TIERS as readonly StoreTier[]).includes(target.tier)) {
    throw new AppError(404, 'STORE_PACKAGE_NOT_FOUND', 'Gói không tồn tại.');
  }
  const current = await storePackageForUser(tx, userId, now);
  const active = current.endsAt && current.package.tier !== StoreTier.PERSONAL
    ? { packageId: current.package.id, priorityLevel: current.package.priorityLevel,
      priceCredits: planPriceCredits(current.package.monthlyPrice), endsAt: current.endsAt }
    : null;
  const quote = quotePlan({ packageId: target.id, priorityLevel: target.priorityLevel, priceCredits: planPriceCredits(target.monthlyPrice) },
    active, now);
  if (!quote) {
    throw new AppError(409, 'STORE_DOWNGRADE_NOT_ALLOWED', 'Gói hiện tại còn hạn. Bạn chuyển sang gói thấp hơn được khi gói này hết hạn.',
      undefined, { endsAt: current.endsAt?.toISOString() });
  }
  return { target, current, quote };
}

/** Báo giá cho màn nâng cấp: { packageId, mode, price, credit, amount, endsAt, available } */
export async function getPlanQuote(userId: string, packageId: string) {
  return transaction(async (tx) => {
    const now = new Date();
    const { quote } = await planQuote(tx, userId, packageId, now);
    const wallet = await availableCredits(tx, userId);
    return { packageId, ...quote, available: wallet };
  });
}

/**
 * Mua / gia hạn / nâng cấp gói bằng xu, có hiệu lực ngay, không cần admin duyệt.
 * Danh mục cửa hàng: lấy [categoryId], không gửi thì giữ danh mục đang dùng (mua mới thì bắt buộc).
 * Thiếu xu thì 409 NOT_ENOUGH_CREDITS (details: required, available, missing).
 */
export async function subscribeWithCredits(userId: string, { packageId, categoryId }: { packageId: string; categoryId?: string }) {
  return withQuotaTransaction(async (tx) => {
    const now = new Date();
    const { target, current, quote } = await planQuote(tx, userId, packageId, now);
    const chosen = categoryId ?? current.category?.id;
    const category = chosen ? await storeRepository.findActiveCategory(tx, chosen) : null;
    if (!category) throw new AppError(400, 'STORE_CATEGORY_REQUIRED', 'Chọn chuyên mục chính của bạn.', 'categoryId');
    await spendCredits(tx, { userId, amount: quote.amount, note: `${quote.mode === 'UPGRADE' ? 'Nâng cấp' : quote.mode === 'RENEW' ? 'Gia hạn' : 'Mua'} gói ${target.name} 30 ngày` });
    const subscription = await storeRepository.upsertSubscription(tx, userId, {
      packageId: target.id, categoryId: category.id, startsAt: now, endsAt: quote.endsAt,
    });
    return { ...quote, packageId: target.id, categoryId: category.id, subscription };
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

/* ---------- Quản trị (/admin/store-packages, /admin/store-orders) ---------- */

export const listAllPackages = () => storeRepository.findAllPackages();

/** Đơn mua gói, 25 đơn mỗi trang */
export async function listOrders({ page, status }: AdminOrderQuery) {
  const [items, total] = await storeRepository.findOrderPage(status, (page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  return { items, total, page };
}

/** Sửa gói cửa hàng; gói PERSONAL phải miễn phí, không ưu tiên, không kèm lượt đẩy tin. Ghi AdminAudit. */
export function updatePackage(actorId: string, id: string, data: StorePackageInput) {
  return withQuotaTransaction(async (tx) => {
    const old = await storeRepository.findPackageOrThrow(tx, id);
    if (old.tier === StoreTier.PERSONAL && (data.monthlyPrice !== '0' || data.priorityLevel !== 0 || data.monthlyPromotionQuota !== 0)) {
      throw new AppError(400, 'INVALID_PERSONAL_PACKAGE', 'Gói cá nhân phải miễn phí, không có ưu tiên hoặc quảng cáo kèm gói.');
    }
    const item = await storeRepository.updatePackage(tx, id, data);
    await audit(tx, actorId, 'UPDATE', 'STORE_PACKAGE', id, data.name, old, item);
    return item;
  });
}
