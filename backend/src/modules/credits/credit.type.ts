import { randomInt } from 'node:crypto';
import { CreditBucket, CreditTxnType } from '@prisma/client';

/** Đơn nạp chờ trả quá 15 phút thì hết hạn */
export const TOPUP_TTL_MS = 15 * 60 * 1000;
/** Mỗi người giữ tối đa 3 đơn đang chờ trả cùng lúc */
export const MAX_PENDING_TOPUPS = 3;
/** Xu tặng hết hạn sau 90 ngày, xu nạp sau 12 tháng */
export const BONUS_TTL_MS = 90 * 24 * 60 * 60 * 1000;
export const PAID_TTL_MS = 365 * 24 * 60 * 60 * 1000;
export const DAY_MS = 24 * 60 * 60 * 1000;
/** Nhắc xu tặng sắp hết hạn trước chừng này ngày */
export const BONUS_REMINDER_DAYS = 7;

/** Bộ lọc lịch sử trên app → loại bút toán */
export const HISTORY_FILTERS: Record<string, CreditTxnType[]> = {
  topup: [CreditTxnType.TOPUP, CreditTxnType.BONUS],
  spend: [CreditTxnType.SPEND, CreditTxnType.EXPIRE],
  refund: [CreditTxnType.REFUND],
};

export type BucketSum = { bucket: CreditBucket; amount: number };

/**
 * Số dư ví từ tổng bút toán theo từng loại xu. Xu giữ cho tin chờ duyệt đã bị trừ khỏi số dư
 * (bút toán SPEND), [held] chỉ để hiển thị "đang giữ".
 */
export function summarizeWallet(sums: BucketSum[], nextBonusExpiry: Date | null, held = 0) {
  const paid = Math.max(0, sums.find((s) => s.bucket === CreditBucket.PAID)?.amount ?? 0);
  const bonus = Math.max(0, sums.find((s) => s.bucket === CreditBucket.BONUS)?.amount ?? 0);
  return { available: paid + bonus, paid, bonus, held, nextBonusExpiry: bonus > 0 ? nextBonusExpiry : null };
}

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/**
 * Mã đơn ngắn để ghi vào nội dung chuyển khoản, VD RS8F2K1X (bỏ 0/O/1/I dễ nhầm).
 * Khớp cấu trúc mã thanh toán trên SePay: tiền tố RS, 6 ký tự số và chữ. Dùng số ngẫu nhiên mật mã.
 * random(n) trả về số nguyên trong [0, n).
 */
export function topupCode(random: (max: number) => number = randomInt) {
  let code = 'RS';
  for (let i = 0; i < 6; i++) code += CODE_ALPHABET[random(CODE_ALPHABET.length)];
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

/** BIN của VietinBank trong danh sách ngân hàng VietQR (https://vietqr.app/banks.json) */
export const VIETINBANK_BIN = '970415';

/**
 * Nội dung chuyển khoản cho đơn nạp: mã đơn đứng đầu để ngân hàng có cắt bớt cũng không mất mã.
 * VietinBank (tài khoản cá nhân / hộ kinh doanh) bắt buộc có chuỗi SEVQR, thiếu thì SePay không nhận được
 * giao dịch: https://developer.sepay.vn/vi/tien-ich-khac/tao-qr-code#quy-tac-tao-vietqr-theo-ngan-hang-ma-sepay-ho-tro
 */
export function transferContent(account: Pick<VietQrAccount, 'bankBin'>, code: string) {
  return account.bankBin === VIETINBANK_BIN ? `SEVQR ${code}` : code;
}

/**
 * Ảnh mã VietQR của SePay (vietqr.app), đã điền số tiền và nội dung (mã đơn).
 * bank nhận mã BIN; template "compact" = bố cục gọn kèm logo NAPAS/VietQR và ngân hàng.
 * Tham số: https://developer.sepay.vn/vi/tien-ich-khac/tao-qr-code#cau-truc-link-nhung
 */
export function vietQrImageUrl(account: VietQrAccount, amountVnd: number, content: string) {
  const query = new URLSearchParams({
    acc: account.accountNo,
    bank: account.bankBin,
    amount: String(amountVnd),
    des: content,
    template: 'compact',
  });
  return `https://vietqr.app/img?${query}`;
}

/**
 * Cổng thử (giả lập kết quả trả tiền) chỉ bật khi PAYMENT_MODE="sandbox" được đặt rõ và không phải production.
 * Thiếu PAYMENT_MODE thì tắt (an toàn khi deploy quên biến). Không bao giờ có tiền thật đi qua đây.
 */
export const sandboxEnabled = (env: NodeJS.ProcessEnv = process.env) =>
  env.NODE_ENV !== 'production' && env.PAYMENT_MODE?.trim() === 'sandbox';

/**
 * Chế độ debug: bỏ qua cổng thật (ZaloPay), đơn tạo xong chỉ trả bằng nút giả lập.
 * Chỉ có tác dụng khi sandbox đang bật, production luôn đi qua cổng.
 */
export const gatewaySkipped = (env: NodeJS.ProcessEnv = process.env) =>
  sandboxEnabled(env) && env.PAYMENT_SKIP_GATEWAY?.trim().toLowerCase() === 'true';
