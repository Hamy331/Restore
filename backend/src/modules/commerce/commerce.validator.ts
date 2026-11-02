import { PromotionKind } from '@prisma/client';
import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';

/* ---------- Gói cửa hàng ---------- */

/** Body POST /stores/orders: { packageId, categoryId } */
export const storeOrderBody = z.unknown().transform((body) => {
  const { packageId, categoryId } = (body ?? {}) as Record<string, unknown>;
  if (typeof packageId !== 'string' || typeof categoryId !== 'string' || packageId.length > 100 || categoryId.length > 100) {
    throw new AppError(400, 'INVALID_STORE_ORDER', 'Gói hoặc danh mục không hợp lệ.');
  }
  return { packageId, categoryId };
});

/* ---------- Gói đẩy tin ---------- */

/** Gói đẩy tin: BUMP có priority 0, FEATURED có priority 1-10; thời lượng 1-30 ngày; giá chuỗi số VND */
export function promotionPackageInput(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new AppError(400, 'INVALID_PROMOTION_PACKAGE', 'Dữ liệu gói quảng cáo không hợp lệ.');
  }
  const body = value as Record<string, unknown>;
  const name = typeof body.name === 'string' ? body.name.trim() : '';
  const { kind, durationDays, priority, price, active } = body;
  if (name.length < 3 || name.length > 80 ||
      !Object.values(PromotionKind).includes(kind as PromotionKind) ||
      !Number.isInteger(durationDays) || (durationDays as number) < 1 || (durationDays as number) > 30 ||
      !Number.isInteger(priority) || (priority as number) < 0 || (priority as number) > 10 ||
      (kind === PromotionKind.BUMP && priority !== 0) ||
      (kind === PromotionKind.FEATURED && (priority as number) < 1) ||
      typeof price !== 'string' || !/^[1-9]\d{0,11}$/.test(price) || typeof active !== 'boolean') {
    throw new AppError(400, 'INVALID_PROMOTION_PACKAGE', 'Tên, loại, thời lượng, giá hoặc độ ưu tiên không hợp lệ.');
  }
  return { name, kind: kind as PromotionKind, durationDays: durationDays as number,
    priority: priority as number, price: price as string, active: active as boolean };
}

export const promotionPackageBody = z.unknown().transform(promotionPackageInput);

/** Body redeem / mua đẩy tin: { listingId, packageId } */
export const purchaseBody = z.unknown().transform((body) => {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new AppError(400, 'INVALID_PROMOTION', 'Tin đăng hoặc gói quảng cáo không hợp lệ.');
  }
  const { listingId, packageId } = body as Record<string, unknown>;
  if (typeof listingId !== 'string' || typeof packageId !== 'string' ||
      !listingId || !packageId || listingId.length > 100 || packageId.length > 100) {
    throw new AppError(400, 'INVALID_PROMOTION', 'Tin đăng hoặc gói quảng cáo không hợp lệ.');
  }
  return { listingId, packageId };
});

/* ---------- Chung ---------- */

/** Params `:id` (gói hoặc đơn) */
export const idParams = z.object({ id: z.string() });
