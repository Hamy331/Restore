import { z } from 'zod';
import { choice, object, page, text } from '../../common/validation/admin-input.js';

/** Query GET /admin/shops: status? = PENDING (mặc định) | VERIFIED | ALL, q? (1-100 ký tự), page */
export const shopVerificationQuery = z.record(z.string(), z.unknown()).transform((query) => ({
  status: query.status ? choice(query.status, ['PENDING', 'VERIFIED', 'ALL'] as const) : 'PENDING' as const,
  q: query.q ? text(query.q, 'q', 1, 100) : undefined,
  page: page(query.page),
}));

/** Body xác minh: type (OFFICIAL_BRAND | CERTIFIED), reason? (ghi chú, mặc định "Đã kiểm tra hồ sơ shop") */
export const shopVerifyBody = z.unknown().transform((value) => {
  const body = object(value, ['type', 'reason']);
  return {
    type: choice(body.type, ['OFFICIAL_BRAND', 'CERTIFIED'] as const),
    reason: body.reason == null || body.reason === '' ? 'Đã kiểm tra hồ sơ shop' : text(body.reason, 'reason', 5, 300),
  };
});

/** Body thu hồi xác minh: reason (5-300 ký tự, bắt buộc) */
export const shopUnverifyBody = z.unknown().transform((value) => {
  const body = object(value, ['reason']);
  return { type: null, reason: text(body.reason, 'reason', 5, 300) };
});

export type ShopVerificationQuery = z.output<typeof shopVerificationQuery>;
export type ShopVerificationBody = z.output<typeof shopVerifyBody> | z.output<typeof shopUnverifyBody>;
