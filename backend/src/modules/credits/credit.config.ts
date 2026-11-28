import { ZALOPAY_SANDBOX_APP_IDS, ZALOPAY_SANDBOX_ENDPOINT } from './credit.zalopay.js';

const filled = (value: string | undefined) => !!value?.trim();

/**
 * Lỗi cấu hình thanh toán khi chạy production (NODE_ENV=production). Có lỗi thì server không khởi động,
 * để không bao giờ chạy tiền thật với cấu hình thử: nút giả lập, cổng sandbox, key công khai.
 * Trả về danh sách lỗi (rỗng = ổn).
 */
export function paymentEnvironmentProblems(env: NodeJS.ProcessEnv = process.env): string[] {
  const problems: string[] = [];
  if (env.PAYMENT_MODE?.trim() !== 'live') problems.push('PAYMENT_MODE phải là "live" khi NODE_ENV=production');
  if (env.PAYMENT_SKIP_GATEWAY?.trim().toLowerCase() === 'true') problems.push('PAYMENT_SKIP_GATEWAY phải để trống ở production');

  const apiBase = env.PUBLIC_API_URL?.trim();
  if (apiBase && !apiBase.startsWith('https://')) problems.push('PUBLIC_API_URL phải dùng https:// ở production');

  // VietQR: có tài khoản nhận thì phải có cách xác thực webhook SePay, không thì đơn không bao giờ được xác nhận
  const vietQr = ['VIETQR_BANK_BIN', 'VIETQR_ACCOUNT_NO', 'VIETQR_ACCOUNT_NAME'].filter((name) => filled(env[name]));
  if (vietQr.length > 0 && vietQr.length < 3) problems.push('VIETQR_BANK_BIN, VIETQR_ACCOUNT_NO, VIETQR_ACCOUNT_NAME phải điền đủ cả ba');
  if (vietQr.length === 3 && !filled(env.SEPAY_WEBHOOK_SECRET) && !filled(env.SEPAY_WEBHOOK_API_KEY)) {
    problems.push('Có VietQR nhưng thiếu SEPAY_WEBHOOK_SECRET (khuyến nghị) hoặc SEPAY_WEBHOOK_API_KEY');
  }
  // Job đối soát cần API key để tìm giao dịch mà webhook bị lỡ (server sập, deploy lỗi...)
  if (vietQr.length === 3 && !filled(env.SEPAY_API_TOKEN)) {
    problems.push('Có VietQR nhưng thiếu SEPAY_API_TOKEN (API key Live, cho job đối soát giao dịch)');
  }
  const secret = env.SEPAY_WEBHOOK_SECRET?.trim();
  if (secret && secret.length < 32) problems.push('SEPAY_WEBHOOK_SECRET quá ngắn (tối thiểu 32 ký tự)');

  // ZaloPay: có app id thì phải là cổng thật với key thật
  if (filled(env.ZALOPAY_APP_ID)) {
    const endpoint = env.ZALOPAY_ENDPOINT?.trim().replace(/\/+$/, '');
    if (!endpoint || endpoint === ZALOPAY_SANDBOX_ENDPOINT) {
      problems.push('ZALOPAY_ENDPOINT phải là cổng thật của ZaloPay (hoặc để trống ZALOPAY_APP_ID để tắt ZaloPay)');
    }
    if (ZALOPAY_SANDBOX_APP_IDS.has(env.ZALOPAY_APP_ID!.trim())) {
      problems.push('ZALOPAY_APP_ID đang là app sandbox công khai, key của nó ai cũng biết: thay bằng app thật');
    }
    if (!filled(env.ZALOPAY_KEY1) || !filled(env.ZALOPAY_KEY2)) problems.push('ZaloPay thiếu ZALOPAY_KEY1 / ZALOPAY_KEY2');
    if (!apiBase) problems.push('ZaloPay cần PUBLIC_API_URL để nhận callback');
  }
  return problems;
}
