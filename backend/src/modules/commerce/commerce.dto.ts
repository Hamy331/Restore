import type { z } from 'zod';
import type { adminOrderQuery, promotionPackageBody, purchaseBody, storeOrderBody, storePackageBody } from './commerce.validator.js';

/* Vào (suy ra từ schema). Kết quả trả ra là bản ghi Prisma kèm quan hệ, giữ nguyên như API cũ. */

export type StoreOrderInput = z.output<typeof storeOrderBody>;
export type PromotionPackageInput = z.output<typeof promotionPackageBody>;
export type PurchaseInput = z.output<typeof purchaseBody>;
export type IdParams = { id: string };
export type AdminOrderQuery = z.output<typeof adminOrderQuery>;
export type StorePackageInput = z.output<typeof storePackageBody>;

/** Body tùy chọn khi admin xác nhận / từ chối đơn: { reason?: string (5-300) } */
export type DecisionReason = { reason?: unknown };
