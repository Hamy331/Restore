import { StoreTier } from '@prisma/client';

export const DAY_MS = 86_400_000;

/** Một kỳ gói cửa hàng: 30 ngày */
export const MONTH_MS = 30 * DAY_MS;

/** Gói cửa hàng bán cho người dùng (PERSONAL là gói mặc định, không bán) */
export const PURCHASABLE_STORE_TIERS = [StoreTier.BASIC, StoreTier.PRO] as const;
