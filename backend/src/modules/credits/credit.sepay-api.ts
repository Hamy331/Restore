import type { SepayTransfer } from './credit.sepay.js';

/**
 * SePay API v2 (danh sách giao dịch), dùng cho job đối soát: tìm giao dịch mà webhook bị lỡ.
 * Tài liệu: https://developer.sepay.vn/vi/sepay-api/v2/giao-dich/danh-sach
 * Token chỉ ở server (SEPAY_API_TOKEN), có quyền trên toàn công ty: không đưa vào app, không ghi log.
 */
export const SEPAY_API_SANDBOX = 'https://userapi-sandbox.sepay.vn/v2';
export const SEPAY_API_LIVE = 'https://userapi.sepay.vn/v2';

export type SepayApiConfig = { token: string; base: string };

/** Thiếu token thì null (job đối soát không chạy). PAYMENT_MODE=live dùng API thật, còn lại dùng sandbox */
export function sepayApiConfig(env: NodeJS.ProcessEnv = process.env): SepayApiConfig | null {
  const token = env.SEPAY_API_TOKEN?.trim();
  if (!token) return null;
  return { token, base: env.PAYMENT_MODE?.trim() === 'live' ? SEPAY_API_LIVE : SEPAY_API_SANDBOX };
}

/** Một dòng trong GET /v2/transactions (chỉ các trường dùng tới) */
export type ApiTransaction = {
  id: string;
  transaction_date?: string | null;
  account_number?: string | null;
  transfer_type?: string | null;
  amount_in?: number | string | null;
  transaction_content?: string | null;
  reference_number?: string | null;
  code?: string | null;
};

const text = (value: unknown) => (typeof value === 'string' || typeof value === 'number') && String(value).trim() ? String(value).trim() : null;

/**
 * Đưa một dòng API về cùng dạng với webhook để dùng chung logic xử lý.
 * id có tiền tố "api:" vì UUID của API khác id số của webhook. Dòng không hợp lệ trả null.
 */
export function apiRowToTransfer(row: ApiTransaction): SepayTransfer | null {
  const amount = Number(row.amount_in);
  if (!row.id || !Number.isInteger(amount) || amount <= 0) return null;
  return {
    id: `api:${row.id}`,
    transferType: row.transfer_type === 'in' ? 'in' : String(row.transfer_type ?? ''),
    amount,
    code: text(row.code),
    content: typeof row.transaction_content === 'string' ? row.transaction_content : '',
    accountNumber: text(row.account_number),
    referenceCode: text(row.reference_number),
    transactionDate: text(row.transaction_date),
  };
}

/** transaction_date của SePay là giờ Việt Nam, không có múi giờ: "YYYY-MM-DD HH:mm:ss" */
export function parseVnDateTime(value: string | null | undefined) {
  if (!value) return null;
  const date = new Date(`${value.trim().replace(' ', 'T')}+07:00`);
  return Number.isNaN(date.getTime()) ? null : date;
}

/** Định dạng ngày giờ Việt Nam cho tham số transaction_date_from */
export function formatVnDateTime(date: Date) {
  const vn = new Date(date.getTime() + 7 * 60 * 60 * 1000);
  return vn.toISOString().slice(0, 19).replace('T', ' ');
}

export class SepayApiError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

/** Một trang giao dịch. 429 (quá 3 request/giây) hoặc lỗi khác ném SepayApiError, lần chạy sau thử lại */
export async function listTransactionsPage(config: SepayApiConfig, query: Record<string, string>) {
  const response = await fetch(`${config.base}/transactions?${new URLSearchParams(query)}`, {
    headers: { Authorization: `Bearer ${config.token}`, Accept: 'application/json' },
    signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) throw new SepayApiError(response.status, `SePay API /transactions HTTP ${response.status}`);
  const body = await response.json() as { data?: ApiTransaction[]; meta?: { pagination?: { has_more?: boolean } } };
  return { rows: Array.isArray(body.data) ? body.data : [], hasMore: body.meta?.pagination?.has_more === true };
}
