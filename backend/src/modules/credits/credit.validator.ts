import { CreditPayMethod } from '@prisma/client';
import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { HISTORY_FILTERS } from './credit.type.js';

/** Cách trả đang mở: ZaloPay (cổng) và VietQR (chuyển khoản). VNPay chưa có khoá nên chưa nhận. */
export const TOPUP_METHODS: readonly CreditPayMethod[] = [CreditPayMethod.ZALOPAY, CreditPayMethod.VIETQR];

/** Body POST /credits/topups: { packageId, method: ZALOPAY | VIETQR } */
export const topupBody = z.unknown().transform((body) => {
  const { packageId, method } = (body ?? {}) as Record<string, unknown>;
  if (typeof packageId !== 'string' || !packageId || packageId.length > 100) {
    throw new AppError(400, 'INVALID_TOPUP', 'Gói nạp không hợp lệ.', 'packageId');
  }
  if (!TOPUP_METHODS.includes(method as CreditPayMethod)) {
    throw new AppError(400, 'INVALID_TOPUP', 'Cách thanh toán không hợp lệ.', 'method');
  }
  return { packageId, method: method as CreditPayMethod };
});
export type TopupInput = z.output<typeof topupBody>;

/** Query GET /credits/transactions: page (1+), limit (1-50, mặc định 20), type? topup | spend | refund */
export const historyQuery = z.record(z.string(), z.unknown()).transform((query) => {
  const page = query.page == null ? 1 : Number(query.page);
  const limit = query.limit == null ? 20 : Number(query.limit);
  const type = query.type == null || query.type === 'all' ? undefined : String(query.type);
  if (!Number.isInteger(page) || page < 1 || page > 100000) throw new AppError(400, 'INVALID_QUERY', 'Trang không hợp lệ.', 'page');
  if (!Number.isInteger(limit) || limit < 1 || limit > 50) throw new AppError(400, 'INVALID_QUERY', 'Số dòng không hợp lệ.', 'limit');
  if (type && !(type in HISTORY_FILTERS)) throw new AppError(400, 'INVALID_QUERY', 'Bộ lọc không hợp lệ.', 'type');
  return { page, limit, type };
});
export type HistoryQuery = z.output<typeof historyQuery>;

export const idParams = z.object({ id: z.string().min(1).max(100) });

/** Body POST /credits/topups/:id/sandbox: { result: success | fail } */
export const sandboxBody = z.unknown().transform((body) => {
  const { result } = (body ?? {}) as Record<string, unknown>;
  if (result !== 'success' && result !== 'fail') throw new AppError(400, 'INVALID_SANDBOX_RESULT', 'Kết quả giả lập không hợp lệ.', 'result');
  return { result: result as 'success' | 'fail' };
});
