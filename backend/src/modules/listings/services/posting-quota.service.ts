import { StoreTier } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { storePackageForUser, storeUsage } from '../../commerce/index.js';
import { availableCredits, holdForListing } from '../../credits/index.js';
import { boostPrice } from '../listing-lifecycle.js';
import { DISPLAY_DAYS, personalQuota, RECENT_WINDOW_DAYS } from '../posting-quota.js';
import type { Db } from '../repositories/listing.repository.js';
import * as quotaRepository from '../repositories/posting-quota.repository.js';

const DAY_MS = 24 * 60 * 60 * 1000;

/** Giới hạn của gói cửa hàng cao nhất, để app giới thiệu khi nâng cấp */
const BUSINESS_LIMIT = 30;

/**
 * Hạn mức đăng tin của người dùng cho GET /me/posting-quota.
 * Cá nhân: theo từng chuyên mục + tổng 5 tin + chống đăng lại; hết suất thì trả xu.
 * Gói cửa hàng: giữ giới hạn cũ của gói (tin trong ngày, tin đang hoạt động), không trả xu.
 */
export async function postingQuota(tx: Db, ownerId: string, now: Date, excludeId?: string) {
  const [plan, usage, rules, wallet] = await Promise.all([
    storePackageForUser(tx, ownerId, now),
    storeUsage(tx, ownerId, now),
    quotaRepository.findCategoryRules(tx),
    availableCredits(tx, ownerId),
  ]);
  const daily = { used: usage.today, limit: plan.package.dailyListingLimit };
  const discount = plan.package.boostDiscountPercent;
  const boost = {
    freePerMonth: plan.package.monthlyPromotionQuota,
    freeLeft: Math.max(0, plan.package.monthlyPromotionQuota - usage.promotionsThisMonth),
    discountPercent: discount,
  };
  const boostCredits = new Map(rules.map((rule) => [rule.id, boostPrice(rule.boostCredits, discount)]));
  const common = { tier: plan.package.tier, displayDays: DISPLAY_DAYS, recentWindowDays: RECENT_WINDOW_DAYS,
    businessLimit: BUSINESS_LIMIT, daily, wallet: { available: wallet }, boost };

  if (plan.package.tier !== StoreTier.PERSONAL) {
    const active = await quotaRepository.countActiveByCategory(tx, ownerId);
    const limit = plan.package.activeListingLimit;
    const free = usage.active < limit;
    return {
      ...common, accountType: 'business' as const, defaultLimit: limit,
      total: { used: usage.active, limit },
      categories: rules.map((rule) => ({
        categoryId: rule.id, used: active.get(rule.id) ?? 0, limit, recentUsed: 0, recentLimit: 0,
        extraCredits: null, extendCredits: rule.extraListingCredits, displayDays: rule.displayDays, boostCredits: boostCredits.get(rule.id)!,
        freeAvailable: free, blockedBy: free ? null : 'TOTAL' as const,
      })),
    };
  }

  const counts = await quotaRepository.countFreeByCategory(tx, ownerId, new Date(now.getTime() - RECENT_WINDOW_DAYS * DAY_MS), excludeId);
  const quota = personalQuota(rules, counts, plan.package.activeListingLimit);
  const categories = quota.categories.map((item) => ({ ...item, boostCredits: boostCredits.get(item.categoryId)! }));
  return { ...common, accountType: 'personal' as const, defaultLimit: 2, ...quota, categories };
}

export type PostingSlotOptions = {
  categoryId: string;
  /** Kiểm tra lượt đăng trong ngày (đăng mới), không kiểm khi sửa / hiện lại tin */
  daily: boolean;
  /** Người dùng đồng ý trả xu khi hết suất miễn phí */
  payWithCredits: boolean;
  /** Tin đang sửa / đăng lại, không tính vào số đã dùng */
  excludeId?: string;
};

/**
 * Kiểm tra còn suất đăng tin. Trả về số xu phải trả (0 = miễn phí).
 * Hết suất mà chưa đồng ý trả xu thì 409 POSTING_LIMIT_REACHED kèm giá; gói cửa hàng hết suất thì 409 ACTIVE_LISTING_LIMIT.
 */
export async function assertPostingSlot(tx: Db, ownerId: string, now: Date, options: PostingSlotOptions) {
  const quota = await postingQuota(tx, ownerId, now, options.excludeId);
  if (options.daily && quota.daily.used >= quota.daily.limit) {
    throw new AppError(409, 'DAILY_LISTING_LIMIT', 'Bạn đã dùng hết lượt đăng tin trong ngày.');
  }
  const category = quota.categories.find((item) => item.categoryId === options.categoryId);
  if (!category) throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
  if (category.freeAvailable) return 0;
  if (category.extraCredits === null) {
    throw new AppError(409, 'ACTIVE_LISTING_LIMIT', 'Bạn đã đạt giới hạn tin đang hoạt động.');
  }
  if (!options.payWithCredits) {
    throw new AppError(409, 'POSTING_LIMIT_REACHED', postingLimitMessage(category.blockedBy, category.limit, quota.total.limit),
      undefined, {
        categoryId: category.categoryId, blockedBy: category.blockedBy, used: category.used, limit: category.limit,
        totalUsed: quota.total.used, totalLimit: quota.total.limit,
        extraCredits: category.extraCredits, available: quota.wallet.available,
      });
  }
  return category.extraCredits;
}

function postingLimitMessage(blockedBy: string | null, limit: number, totalLimit: number) {
  if (blockedBy === 'TOTAL') return `Tài khoản Cá nhân được đăng tối đa ${totalLimit} tin miễn phí cùng lúc.`;
  if (blockedBy === 'RECENT') return 'Bạn đã đăng nhiều tin miễn phí ở chuyên mục này trong 30 ngày qua.';
  return `Chuyên mục này chỉ được ${limit} tin miễn phí đang hiển thị.`;
}

/** Giữ xu cho tin [listingId] khi [price] > 0 */
export async function chargeListing(tx: Db, ownerId: string, listingId: string, price: number, title: string) {
  if (price <= 0) return;
  await holdForListing(tx, { userId: ownerId, listingId, amount: price, note: `Đăng tin vượt hạn mức · ${title}`.slice(0, 200) });
}
