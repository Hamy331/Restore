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
  activeListingLimit: number; monthlyPromotionQuota: number; priorityLevel: number }[] = [
  { id: 'personal', tier: 'PERSONAL', name: 'Cá nhân', monthlyPrice: 0, dailyListingLimit: 3, activeListingLimit: 10, draftLimit: 3, monthlyPromotionQuota: 0, priorityLevel: 0 },
  { id: 'basic', tier: 'BASIC', name: 'Cửa hàng Basic', monthlyPrice: 99000, dailyListingLimit: 10, activeListingLimit: 30, draftLimit: 10, monthlyPromotionQuota: 2, priorityLevel: 1 },
  { id: 'pro', tier: 'PRO', name: 'Cửa hàng Pro', monthlyPrice: 299000, dailyListingLimit: 30, activeListingLimit: 100, draftLimit: 30, monthlyPromotionQuota: 10, priorityLevel: 2 },
];

export const PROMOTION_PACKAGES: { id: string; name: string; kind: PromotionKind; durationDays: number; price: number; priority: number }[] = [
  { id: 'bump-1', name: 'Đẩy tin 1 ngày', kind: 'BUMP', durationDays: 1, price: 10000, priority: 0 },
  { id: 'bump-3', name: 'Đẩy tin 3 ngày', kind: 'BUMP', durationDays: 3, price: 28000, priority: 0 },
  { id: 'bump-7', name: 'Đẩy tin 7 ngày', kind: 'BUMP', durationDays: 7, price: 63000, priority: 0 },
  { id: 'featured-1', name: 'Tin ưu tiên 1 ngày', kind: 'FEATURED', durationDays: 1, price: 20000, priority: 3 },
  { id: 'featured-3', name: 'Tin ưu tiên 3 ngày', kind: 'FEATURED', durationDays: 3, price: 57000, priority: 3 },
  { id: 'featured-7', name: 'Tin ưu tiên 7 ngày', kind: 'FEATURED', durationDays: 7, price: 126000, priority: 3 },
];
