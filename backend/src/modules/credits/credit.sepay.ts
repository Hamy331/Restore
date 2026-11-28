import { createHmac, timingSafeEqual } from 'node:crypto';

/**
 * SePay: báo biến động số dư của tài khoản nhận VietQR qua webhook.
 * Test Mode của SePay giả lập chuyển khoản (không có tiền thật), dùng key riêng cho Test Mode.
 */

/** Key đặt ở mục Webhook của SePay (xác thực "API Key"); thiếu thì webhook bị tắt */
export const sepayWebhookKey = (env: NodeJS.ProcessEnv = process.env) => env.SEPAY_WEBHOOK_API_KEY?.trim() || null;

/** Secret Key của webhook (xác thực "HMAC-SHA256"), ưu tiên hơn API Key */
export const sepayWebhookSecret = (env: NodeJS.ProcessEnv = process.env) => env.SEPAY_WEBHOOK_SECRET?.trim() || null;

/** Lệch giờ tối đa cho phép giữa SePay và máy chủ, chống gửi lại request cũ */
export const SIGNATURE_TOLERANCE_SECONDS = 300;

const safeEqual = (a: string, b: string) => {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
};

/**
 * HMAC-SHA256 của SePay: X-SePay-Signature = "sha256=" + hex(HMAC(secret, "{timestamp}.{body gốc}")),
 * X-SePay-Timestamp = giây Unix lúc ký.
 */
export function verifySignature(input: { signature: unknown; timestamp: unknown; rawBody: Buffer | undefined; secret: string; nowSeconds?: number }) {
  const { signature, timestamp, rawBody, secret } = input;
  if (typeof signature !== 'string' || typeof timestamp !== 'string' || !rawBody) return false;
  const ts = Number(timestamp);
  const now = input.nowSeconds ?? Math.floor(Date.now() / 1000);
  if (!Number.isInteger(ts) || Math.abs(now - ts) > SIGNATURE_TOLERANCE_SECONDS) return false;
  const expected = 'sha256=' + createHmac('sha256', secret).update(`${timestamp}.`).update(rawBody).digest('hex');
  return safeEqual(expected, signature.trim().toLowerCase());
}

/** SePay gửi header "Authorization: Apikey <key>"; so sánh hằng thời gian */
export function verifyApiKey(header: unknown, key: string) {
  if (typeof header !== 'string') return false;
  const match = /^apikey\s+(.+)$/i.exec(header.trim());
  if (!match) return false;
  return safeEqual(match[1].trim(), key);
}

/** Mô tả header Authorization để ghi log khi sai key, không lộ giá trị */
export function describeAuthHeader(header: unknown) {
  if (typeof header !== 'string' || !header.trim()) return 'missing Authorization header';
  const [scheme, ...rest] = header.trim().split(/\s+/);
  return `scheme "${scheme}", value length ${rest.join(' ').length}`;
}

export type SepayTransfer = {
  id: string; transferType: string; amount: number; code: string | null; content: string;
  accountNumber: string | null; referenceCode: string | null; transactionDate: string | null;
};

/** Chuỗi không rỗng, hoặc null (SePay có thể gửi null, "" hoặc 0 cho trường trống) */
const text = (value: unknown) => (typeof value === 'string' || typeof value === 'number') && String(value).trim() ? String(value).trim() : null;

/** Lấy các trường cần dùng từ body webhook; sai kiểu thì null */
export function parseWebhook(body: unknown): SepayTransfer | null {
  if (!body || typeof body !== 'object') return null;
  const b = body as Record<string, unknown>;
  const id = typeof b.id === 'number' || typeof b.id === 'string' ? String(b.id) : '';
  const amount = Number(b.transferAmount);
  if (!id || !Number.isInteger(amount) || amount <= 0) return null;
  return {
    id,
    transferType: typeof b.transferType === 'string' ? b.transferType : '',
    amount,
    code: typeof b.code === 'string' && b.code ? b.code : null,
    content: typeof b.content === 'string' ? b.content : '',
    accountNumber: text(b.accountNumber),
    referenceCode: text(b.referenceCode),
    transactionDate: text(b.transactionDate),
  };
}

/** Những gì đã lưu của một giao dịch, đủ để so với giao dịch khác */
export type TransferFingerprint = { amountVnd: number; transactionDate: string | null; referenceCode: string | null; accountNumber: string | null };

/**
 * Hai bản ghi có phải cùng một lần chuyển tiền không (VD webhook và job đối soát cùng thấy một giao dịch).
 * id của webhook và của API khác nhau nên so số tiền, thời điểm, mã tham chiếu ngân hàng và tài khoản.
 */
export function isSameTransfer(saved: TransferFingerprint, transfer: Pick<SepayTransfer, 'amount' | 'transactionDate' | 'referenceCode' | 'accountNumber'>) {
  if (saved.amountVnd !== transfer.amount) return false;
  if (!saved.transactionDate || saved.transactionDate !== transfer.transactionDate) return false;
  if (saved.referenceCode && transfer.referenceCode && saved.referenceCode !== transfer.referenceCode) return false;
  if (saved.accountNumber && transfer.accountNumber && saved.accountNumber !== transfer.accountNumber) return false;
  return true;
}

/**
 * Tiền phải vào đúng tài khoản nhận VietQR. Chưa cấu hình tài khoản hoặc SePay không gửi số tài khoản thì không chặn.
 */
export function isExpectedAccount(accountNumber: string | null, expected: string | null | undefined) {
  if (!expected || !accountNumber) return true;
  return accountNumber.replace(/\s+/g, '') === expected.replace(/\s+/g, '');
}

/** Mã đơn nạp RS + 6 ký tự (xem topupCode). Ngân hàng hay viết hoa và dính chữ nên tìm cả trong nội dung */
const TOPUP_CODE = /RS[A-HJ-NP-Z2-9]{6}/;

export function extractTopupCode(transfer: Pick<SepayTransfer, 'code' | 'content'>) {
  for (const text of [transfer.code, transfer.content]) {
    const match = text && TOPUP_CODE.exec(text.toUpperCase());
    if (match) return match[0];
  }
  return null;
}
