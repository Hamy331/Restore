import { StoreTier } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { audit } from '../../../common/audit/admin-audit.js';
import { emit } from '../../../common/events/domain-events.js';
import { ADMIN_PAGE_SIZE } from '../../../common/validation/admin-input.js';
import type { AdminOrderQuery, StoreOrderInput, StorePackageInput } from '../commerce.dto.js';
import { availableCredits, spendCredits } from '../../credits/credit.hold.js';
import { DAY_MS, MONTH_MS, PURCHASABLE_STORE_TIERS } from '../commerce.type.js';
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
  const { result, planName } = await withQuotaTransaction(async (tx) => {
    const now = new Date();
    const { target, current, quote } = await planQuote(tx, userId, packageId, now);
    const chosen = categoryId ?? current.category?.id;
    const category = chosen ? await storeRepository.findActiveCategory(tx, chosen) : null;
    if (!category) throw new AppError(400, 'STORE_CATEGORY_REQUIRED', 'Chọn chuyên mục chính của bạn.', 'categoryId');
    await spendCredits(tx, { userId, amount: quote.amount, note: `${quote.mode === 'UPGRADE' ? 'Nâng cấp' : quote.mode === 'RENEW' ? 'Gia hạn' : 'Mua'} gói ${target.name} 30 ngày` });
    const subscription = await storeRepository.upsertSubscription(tx, userId, {
      packageId: target.id, categoryId: category.id, startsAt: now, endsAt: quote.endsAt,
    });
    return { result: { ...quote, packageId: target.id, categoryId: category.id, subscription }, planName: target.name };
  });
  // Sau khi commit: báo gói đã kích hoạt (2.8)
  await emit('plan.activated', { userId, packageId: result.packageId, planName, endsAt: result.subscription.endsAt, mode: result.mode });
  return result;
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
  const { result, planName, userId } = await withQuotaTransaction(async (tx) => {
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
    const storePackage = await storeRepository.findPackage(tx, order.packageId);
    return { result: { orderId: id, subscription }, planName: storePackage?.name ?? order.packageId, userId: order.userId };
  });
  // Sau khi commit: báo người mua gói đã kích hoạt (2.8)
  await emit('plan.activated', { userId, packageId: result.subscription.packageId, planName, endsAt: result.subscription.endsAt, mode: 'ORDER' });
  return result;
}

/** Nhắc gói cửa hàng sắp hết hạn trước chừng này ngày */
export const PLAN_REMINDER_DAYS = 3;
/** Gói hết hạn quá chừng này thì không báo nữa (backend tắt lâu) */
const PLAN_EXPIRED_LOOKBACK_MS = 2 * DAY_MS;

/**
 * Job nhắc gói cửa hàng (2.9): còn dưới 3 ngày thì nhắc gia hạn, đã hết hạn thì báo về gói Cá nhân.
 * Mỗi mốc hết hạn báo một lần (dedupeKey theo endsAt, gia hạn xong là mốc mới).
 */
export async function remindStorePlans(now = new Date()) {
  const [expiring, expired] = await Promise.all([
    storeRepository.findSubscriptionsEnding(now, new Date(now.getTime() + PLAN_REMINDER_DAYS * DAY_MS)),
    storeRepository.findSubscriptionsEnding(new Date(now.getTime() - PLAN_EXPIRED_LOOKBACK_MS), now),
  ]);
  const ref = (row: (typeof expiring)[number]) =>
    ({ userId: row.userId, packageId: row.packageId, planName: row.package.name, endsAt: row.endsAt });
  for (const row of expiring) {
    await emit('plan.expiring', { ...ref(row), daysLeft: Math.max(1, Math.ceil((row.endsAt.getTime() - now.getTime()) / DAY_MS)) });
  }
  for (const row of expired) await emit('plan.expired', ref(row));
  return expiring.length + expired.length;
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
