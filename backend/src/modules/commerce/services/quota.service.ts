import { AppError } from '../../../common/errors/app-error.js';
import * as quotaRepository from '../repositories/quota.repository.js';
import type { Db } from '../repositories/quota.repository.js';

export const utcDayStart = (date: Date) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));

export const utcMonthStart = (date: Date) =>
  new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));

/** Gói cửa hàng đang hiệu lực của người dùng; hết hạn hoặc chưa mua thì là gói PERSONAL */
export async function storePackageForUser(tx: Db, userId: string, now: Date) {
  const subscription = await quotaRepository.findSubscription(tx, userId);
  if (subscription && subscription.startsAt <= now && subscription.endsAt > now) {
    return { package: subscription.package, endsAt: subscription.endsAt, category: subscription.category };
  }
  const personal = await quotaRepository.findPersonalPackage(tx);
  if (!personal) throw new AppError(503, 'STORE_CATALOG_UNAVAILABLE', 'Gói tài khoản chưa được cấu hình.');
  return { package: personal, endsAt: null, category: null };
}

/** Lượt đã dùng: tin đăng hôm nay, tin đang hoạt động, tin nháp, lượt đẩy tin kèm gói trong tháng */
export async function storeUsage(tx: Db, userId: string, now: Date) {
  const [today, active, drafts, promotionsThisMonth] = await Promise.all([
    quotaRepository.countPublishedSince(tx, userId, utcDayStart(now)),
    quotaRepository.countActiveListings(tx, userId),
    quotaRepository.countDrafts(tx, userId),
    quotaRepository.countIncludedPromotionsSince(tx, userId, utcMonthStart(now)),
  ]);
  return { today, active, drafts, promotionsThisMonth };
}

/** Số tin nháp đang giữ và giới hạn theo gói (Cá nhân 3, Basic 10, Pro 30 theo seed) */
export async function draftQuota(tx: Db, userId: string, now: Date) {
  const [plan, used] = await Promise.all([
    storePackageForUser(tx, userId, now),
    quotaRepository.countDrafts(tx, userId),
  ]);
  const limit = plan.package.draftLimit;
  return { used, limit, remaining: Math.max(0, limit - used), tier: plan.package.tier };
}

/** Còn chỗ thêm một tin nháp, không thì 409 DRAFT_LIMIT_REACHED */
export async function assertDraftQuota(tx: Db, userId: string, now: Date) {
  const quota = await draftQuota(tx, userId, now);
  if (quota.used >= quota.limit) {
    throw new AppError(409, 'DRAFT_LIMIT_REACHED', `Bạn chỉ được giữ tối đa ${quota.limit} tin nháp. Hãy đăng hoặc xóa bớt tin nháp.`);
  }
}

/** Chạy [work] trong transaction SERIALIZABLE, thử lại khi xung đột; vẫn xung đột thì 503 QUOTA_BUSY */
export async function withQuotaTransaction<T>(work: (tx: Db) => Promise<T>): Promise<T> {
  const result = await quotaRepository.serializableTransaction(work);
  if (!result) throw new AppError(503, 'QUOTA_BUSY', 'Có thao tác đồng thời trên tài khoản. Vui lòng thử lại.');
  return result.value;
}
