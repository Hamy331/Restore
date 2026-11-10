import { CreditBucket, CreditTxnType } from '@prisma/client';

/** Đơn nạp chờ trả quá 15 phút thì hết hạn */
export const TOPUP_TTL_MS = 15 * 60 * 1000;
/** Mỗi người giữ tối đa 3 đơn đang chờ trả cùng lúc */
export const MAX_PENDING_TOPUPS = 3;
/** Xu tặng hết hạn sau 90 ngày, xu nạp sau 12 tháng */
export const BONUS_TTL_MS = 90 * 24 * 60 * 60 * 1000;
export const PAID_TTL_MS = 365 * 24 * 60 * 60 * 1000;

/** Bộ lọc lịch sử trên app → loại bút toán */
export const HISTORY_FILTERS: Record<string, CreditTxnType[]> = {
  topup: [CreditTxnType.TOPUP, CreditTxnType.BONUS],
  spend: [CreditTxnType.SPEND, CreditTxnType.EXPIRE],
  refund: [CreditTxnType.REFUND],
};

export type BucketSum = { bucket: CreditBucket; amount: number };

/** Số dư ví từ tổng bút toán theo từng loại xu. Chưa có giữ xu nên held = 0. */
export function summarizeWallet(sums: BucketSum[], nextBonusExpiry: Date | null) {
  const paid = Math.max(0, sums.find((s) => s.bucket === CreditBucket.PAID)?.amount ?? 0);
  const bonus = Math.max(0, sums.find((s) => s.bucket === CreditBucket.BONUS)?.amount ?? 0);
  return { available: paid + bonus, paid, bonus, held: 0, nextBonusExpiry: bonus > 0 ? nextBonusExpiry : null };
}

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** Mã đơn ngắn để ghi vào nội dung chuyển khoản, VD RS8F2K1X (bỏ 0/O/1/I dễ nhầm) */
export function topupCode(random: () => number = Math.random) {
  let code = 'RS';
  for (let i = 0; i < 6; i++) code += CODE_ALPHABET[Math.floor(random() * CODE_ALPHABET.length)];
  return code;
}

export type VietQrAccount = { bankBin: string; accountNo: string; accountName: string };

/** Tài khoản nhận chuyển khoản lấy từ biến môi trường; thiếu thì không có VietQR */
export function vietQrAccount(env: NodeJS.ProcessEnv = process.env): VietQrAccount | null {
  const bankBin = env.VIETQR_BANK_BIN?.trim();
  const accountNo = env.VIETQR_ACCOUNT_NO?.trim();
  const accountName = env.VIETQR_ACCOUNT_NAME?.trim();
  return bankBin && accountNo && accountName ? { bankBin, accountNo, accountName } : null;
}

/** Ảnh mã VietQR miễn phí của img.vietqr.io, đã điền số tiền và nội dung */
export function vietQrImageUrl(account: VietQrAccount, amountVnd: number, content: string) {
  const query = new URLSearchParams({ amount: String(amountVnd), addInfo: content, accountName: account.accountName });
  return `https://img.vietqr.io/image/${encodeURIComponent(account.bankBin)}-${encodeURIComponent(account.accountNo)}-compact2.png?${query}`;
}

/**
 * Cổng thử (giả lập kết quả trả tiền) chỉ bật ngoài production và khi PAYMENT_MODE khác "live".
 * Không bao giờ có tiền thật đi qua đây.
 */
export const sandboxEnabled = (env: NodeJS.ProcessEnv = process.env) =>
  env.NODE_ENV !== 'production' && (env.PAYMENT_MODE ?? 'sandbox') !== 'live';

/**
 * Chế độ debug: bỏ qua cổng thật (ZaloPay), đơn tạo xong chỉ trả bằng nút giả lập.
 * Chỉ có tác dụng khi sandbox đang bật, production luôn đi qua cổng.
 */
export const gatewaySkipped = (env: NodeJS.ProcessEnv = process.env) =>
  sandboxEnabled(env) && env.PAYMENT_SKIP_GATEWAY?.trim().toLowerCase() === 'true';
