import type { ListingCondition, PromotionKind, StoreTier } from '@prisma/client';

/* Dữ liệu tham chiếu mặc định, giống phần INSERT trong các migration cũ. Admin sửa được sau khi seed. */

export const CONDITION_POLICIES: { condition: ListingCondition; name: string }[] = [
  { condition: 'NEW', name: 'Mới' },
  { condition: 'LIKE_NEW', name: 'Như mới' },
  { condition: 'USED_GOOD', name: 'Đã dùng – Tốt' },
  { condition: 'USED_FAIR', name: 'Đã dùng – Khá' },
  { condition: 'FOR_PARTS', name: 'Cần sửa chữa' },
];

export const STORE_PACKAGES: { id: string; tier: StoreTier; name: string; monthlyPrice: number; dailyListingLimit: number;
  activeListingLimit: number; draftLimit: number; monthlyPromotionQuota: number; boostDiscountPercent: number; priorityLevel: number;
  freeDaysPercent: number; extendDiscountPercent: number; autoExtend: boolean }[] = [
  { id: 'personal', tier: 'PERSONAL', name: 'Cá nhân', monthlyPrice: 0, dailyListingLimit: 3, activeListingLimit: 5, draftLimit: 3, monthlyPromotionQuota: 0, boostDiscountPercent: 0, priorityLevel: 0, freeDaysPercent: 100, extendDiscountPercent: 0, autoExtend: false },
  { id: 'basic', tier: 'BASIC', name: 'Cửa hàng Basic', monthlyPrice: 99000, dailyListingLimit: 10, activeListingLimit: 30, draftLimit: 10, monthlyPromotionQuota: 5, boostDiscountPercent: 20, priorityLevel: 1, freeDaysPercent: 150, extendDiscountPercent: 20, autoExtend: false },
  { id: 'pro', tier: 'PRO', name: 'Cửa hàng Pro', monthlyPrice: 299000, dailyListingLimit: 30, activeListingLimit: 100, draftLimit: 30, monthlyPromotionQuota: 20, boostDiscountPercent: 30, priorityLevel: 2, freeDaysPercent: 200, extendDiscountPercent: 30, autoExtend: true },
];

export const PROMOTION_PACKAGES: { id: string; name: string; kind: PromotionKind; durationDays: number; price: number; priority: number }[] = [
  { id: 'bump-1', name: 'Đẩy tin 1 ngày', kind: 'BUMP', durationDays: 1, price: 10000, priority: 0 },
  { id: 'bump-3', name: 'Đẩy tin 3 ngày', kind: 'BUMP', durationDays: 3, price: 28000, priority: 0 },
  { id: 'bump-7', name: 'Đẩy tin 7 ngày', kind: 'BUMP', durationDays: 7, price: 63000, priority: 0 },
  { id: 'featured-1', name: 'Tin ưu tiên 1 ngày', kind: 'FEATURED', durationDays: 1, price: 20000, priority: 3 },
  { id: 'featured-3', name: 'Tin ưu tiên 3 ngày', kind: 'FEATURED', durationDays: 3, price: 57000, priority: 3 },
  { id: 'featured-7', name: 'Tin ưu tiên 7 ngày', kind: 'FEATURED', durationDays: 7, price: 126000, priority: 3 },
];

/** Gói nạp Xu ReStore (1 xu = 1.000 đ); credits là xu nạp, bonusCredits là xu tặng */
export const CREDIT_PACKAGES: { id: string; priceVnd: number; credits: number; bonusCredits: number; popular: boolean; sortOrder: number }[] = [
  { id: 'p20', priceVnd: 20000, credits: 20, bonusCredits: 0, popular: false, sortOrder: 1 },
  { id: 'p50', priceVnd: 50000, credits: 50, bonusCredits: 2, popular: false, sortOrder: 2 },
  { id: 'p100', priceVnd: 100000, credits: 100, bonusCredits: 10, popular: true, sortOrder: 3 },
  { id: 'p200', priceVnd: 200000, credits: 200, bonusCredits: 30, popular: false, sortOrder: 4 },
  { id: 'p500', priceVnd: 500000, credits: 500, bonusCredits: 100, popular: false, sortOrder: 5 },
];

/**
 * Hạn mức tài khoản Cá nhân theo chuyên mục: số tin miễn phí đang hiển thị và giá (xu) mỗi tin vượt.
 * Tổng toàn tài khoản là activeListingLimit của gói PERSONAL (5).
 */
/** Hạn mức đăng tin, ngày hiển thị (miễn phí / tối đa / giá 30 ngày thêm) và giá đẩy tin theo chuyên mục */
export const POSTING_LIMITS: Record<string, { freeListingLimit: number; extraListingCredits: number; displayDays: number;
  maxDisplayDays: number; dayPackCredits: number; boostCredits: number }> = {
  phones: { freeListingLimit: 1, extraListingCredits: 15, displayDays: 30, maxDisplayDays: 120, dayPackCredits: 15, boostCredits: 10 },
  vehicles: { freeListingLimit: 1, extraListingCredits: 15, displayDays: 30, maxDisplayDays: 180, dayPackCredits: 15, boostCredits: 10 },
  electronics: { freeListingLimit: 1, extraListingCredits: 15, displayDays: 45, maxDisplayDays: 120, dayPackCredits: 12, boostCredits: 10 },
  appliances: { freeListingLimit: 1, extraListingCredits: 10, displayDays: 45, maxDisplayDays: 180, dayPackCredits: 8, boostCredits: 6 },
  pets: { freeListingLimit: 1, extraListingCredits: 10, displayDays: 21, maxDisplayDays: 60, dayPackCredits: 8, boostCredits: 6 },
  furniture: { freeListingLimit: 2, extraListingCredits: 10, displayDays: 60, maxDisplayDays: 180, dayPackCredits: 6, boostCredits: 6 },
  fashion: { freeListingLimit: 2, extraListingCredits: 5, displayDays: 30, maxDisplayDays: 90, dayPackCredits: 4, boostCredits: 4 },
  sports: { freeListingLimit: 2, extraListingCredits: 5, displayDays: 45, maxDisplayDays: 120, dayPackCredits: 4, boostCredits: 4 },
  other: { freeListingLimit: 2, extraListingCredits: 5, displayDays: 45, maxDisplayDays: 120, dayPackCredits: 4, boostCredits: 4 },
  books: { freeListingLimit: 3, extraListingCredits: 5, displayDays: 60, maxDisplayDays: 180, dayPackCredits: 3, boostCredits: 4 },
};

/** Mốc mua ngày hiển thị rẻ hơn */
export const DISPLAY_DAY_PACKS: { days: number; discountPercent: number }[] = [
  { days: 30, discountPercent: 10 },
  { days: 60, discountPercent: 20 },
  { days: 90, discountPercent: 30 },
];
