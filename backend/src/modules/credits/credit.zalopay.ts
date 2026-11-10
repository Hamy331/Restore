import { createHmac, timingSafeEqual } from 'node:crypto';

/**
 * Cổng ZaloPay (API v2). Chỉ dùng môi trường sandbox khi PAYMENT_MODE khác "live".
 * Khoá lấy từ biến môi trường; thiếu khoá thì không có cách trả ZaloPay.
 * Tài liệu: https://docs.zalopay.vn/docs/specs/order-create
 */

export const ZALOPAY_SANDBOX_ENDPOINT = 'https://sb-openapi.zalopay.vn/v2';

export type ZaloPayConfig = {
  appId: string; key1: string; key2: string; endpoint: string;
  callbackUrl?: string; redirectUrl: string; methods: string[];
};

/** Đọc cấu hình; thiếu app id hoặc khoá thì trả null */
export function zaloPayConfig(env: NodeJS.ProcessEnv = process.env): ZaloPayConfig | null {
  const appId = env.ZALOPAY_APP_ID?.trim();
  const key1 = env.ZALOPAY_KEY1?.trim();
  const key2 = env.ZALOPAY_KEY2?.trim();
  if (!appId || !key1 || !key2) return null;
  const apiBase = env.PUBLIC_API_URL?.trim().replace(/\/+$/, '');
  return {
    appId,
    key1,
    key2,
    endpoint: (env.ZALOPAY_ENDPOINT?.trim() || ZALOPAY_SANDBOX_ENDPOINT).replace(/\/+$/, ''),
    // ZaloPay chỉ gọi được callback tới địa chỉ public (VD ngrok). Chạy localhost thì app tự hỏi trạng thái.
    callbackUrl: apiBase ? `${apiBase}/api/v1/payments/zalopay/callback` : undefined,
    // Trang ZaloPay chuyển khách về sau khi trả; mặc định là trang báo kết quả của backend
    redirectUrl: env.ZALOPAY_REDIRECT_URL?.trim()
      || `${apiBase ?? `http://localhost:${env.PORT?.trim() || '3000'}`}/api/v1/payments/zalopay/return`,
    // Cách trả hiện trên trang cổng (preferred_payment_method). Mặc định thẻ ATM nội địa để thử trên web.
    // Giá trị: domestic_card, international_card, account, zalopay_wallet, vietqr; "all" = để ZaloPay tự chọn.
    methods: zaloPayMethods(env.ZALOPAY_METHODS),
  };
}

function zaloPayMethods(raw: string | undefined) {
  const value = raw?.trim();
  if (value === 'all') return [];
  return value ? value.split(',').map((m) => m.trim()).filter(Boolean) : ['domestic_card'];
}

export const hmac = (key: string, data: string) => createHmac('sha256', key).update(data).digest('hex');

/** app_trans_id = yymmdd (giờ Việt Nam) + "_" + mã đơn, VD 261109_RS8F2K1X */
export function appTransId(code: string, now: Date = new Date()) {
  const vn = new Date(now.getTime() + 7 * 60 * 60 * 1000);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${pad(vn.getUTCFullYear() % 100)}${pad(vn.getUTCMonth() + 1)}${pad(vn.getUTCDate())}_${code}`;
}

export type CreateOrderInput = { code: string; userId: string; amountVnd: number; expireSeconds: number; now?: Date };

/** Tham số tạo đơn kèm mac = HMAC(key1, app_id|app_trans_id|app_user|amount|app_time|embed_data|item) */
export function buildCreateOrder(config: ZaloPayConfig, { code, userId, amountVnd, expireSeconds, now = new Date() }: CreateOrderInput) {
  const params: Record<string, string> = {
    app_id: config.appId,
    app_user: userId.slice(0, 50),
    app_trans_id: appTransId(code, now),
    app_time: String(now.getTime()),
    expire_duration_seconds: String(expireSeconds),
    amount: String(amountVnd),
    description: `ReStore - Nạp xu đơn #${code}`,
    item: '[]',
    embed_data: JSON.stringify({ redirecturl: config.redirectUrl, preferred_payment_method: config.methods }),
    bank_code: '',
  };
  if (config.callbackUrl) params.callback_url = config.callbackUrl;
  params.mac = hmac(config.key1, [params.app_id, params.app_trans_id, params.app_user, params.amount, params.app_time, params.embed_data, params.item].join('|'));
  return params;
}

async function post<T>(config: ZaloPayConfig, path: string, params: Record<string, string>): Promise<T> {
  const response = await fetch(`${config.endpoint}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(params),
    signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) throw new Error(`ZaloPay ${path} HTTP ${response.status}`);
  return response.json() as Promise<T>;
}

type CreateResponse = { return_code: number; return_message?: string; sub_return_message?: string; order_url?: string };

/** Tạo đơn trên ZaloPay, trả về app_trans_id và URL trang thanh toán */
export async function createOrder(config: ZaloPayConfig, input: CreateOrderInput) {
  const params = buildCreateOrder(config, input);
  const result = await post<CreateResponse>(config, '/create', params);
  if (result.return_code !== 1 || !result.order_url) {
    throw new Error(`ZaloPay create: ${result.return_code} ${result.sub_return_message ?? result.return_message ?? ''}`);
  }
  return { appTransId: params.app_trans_id, orderUrl: result.order_url };
}

export type QueryResult =
  | { status: 'paid'; zpTransId: string; amount: number }
  | { status: 'failed' }
  | { status: 'pending' };

type QueryResponse = { return_code: number; is_processing?: boolean; amount?: number; zp_trans_id?: number | string };

/** Hỏi trạng thái đơn. return_code 1 = đã trả, 2 = thất bại, 3 = chưa trả / đang xử lý */
export async function queryOrder(config: ZaloPayConfig, transId: string): Promise<QueryResult> {
  const result = await post<QueryResponse>(config, '/query', {
    app_id: config.appId,
    app_trans_id: transId,
    mac: hmac(config.key1, `${config.appId}|${transId}|${config.key1}`),
  });
  if (result.return_code === 1 && result.zp_trans_id != null && typeof result.amount === 'number') {
    return { status: 'paid', zpTransId: String(result.zp_trans_id), amount: result.amount };
  }
  if (result.return_code === 2 && !result.is_processing) return { status: 'failed' };
  return { status: 'pending' };
}

export type CallbackData = { app_trans_id: string; zp_trans_id: number | string; amount: number };

/** Kiểm chữ ký callback: mac = HMAC(key2, data) trên nguyên chuỗi data. Sai chữ ký trả null. */
export function verifyCallback(config: ZaloPayConfig, data: unknown, mac: unknown): CallbackData | null {
  if (typeof data !== 'string' || typeof mac !== 'string') return null;
  const expected = Buffer.from(hmac(config.key2, data));
  const given = Buffer.from(mac.toLowerCase());
  if (expected.length !== given.length || !timingSafeEqual(expected, given)) return null;
  try {
    const parsed = JSON.parse(data) as Partial<CallbackData>;
    if (typeof parsed.app_trans_id !== 'string' || parsed.zp_trans_id == null || typeof parsed.amount !== 'number') return null;
    return { app_trans_id: parsed.app_trans_id, zp_trans_id: parsed.zp_trans_id, amount: parsed.amount };
  } catch {
    return null;
  }
}
