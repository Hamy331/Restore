import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';

/**
 * Gửi push qua Firebase Cloud Messaging (HTTP v1), miễn phí.
 *
 * Cấu hình (một trong hai, trong .env), khoá service account tải ở Firebase Console > Project settings > Service accounts:
 *  - FIREBASE_SERVICE_ACCOUNT_PATH = đường dẫn file .json (máy dev; để file NGOÀI thư mục repo)
 *  - FIREBASE_SERVICE_ACCOUNT_JSON = nội dung file .json, nguyên văn hoặc base64 (server deploy, không có file)
 * Không cấu hình thì push tắt (thông báo vẫn ghi trong app), không lỗi.
 *
 * Không dùng firebase-admin: tự ký JWT (RS256) đổi lấy access token của Google, rồi gọi REST.
 */
type ServiceAccount = { project_id: string; client_email: string; private_key: string };

export type PushMessage = {
  title: string;
  body: string;
  /** Giá trị phải là chuỗi (yêu cầu của FCM) */
  data: Record<string, string>;
  imageUrl?: string | null;
};

/** ok: đã gửi; invalid: token hỏng / đã gỡ app, nên xoá; error: lỗi tạm thời */
export type PushResult = 'ok' | 'invalid' | 'error';

const TOKEN_URL = 'https://oauth2.googleapis.com/token';
const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TIMEOUT_MS = 10_000;

let account: ServiceAccount | null | undefined;
let accessToken: { value: string; expiresAt: number } | null = null;

function loadAccount(): ServiceAccount | null {
  if (account !== undefined) return account;
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  const path = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
  if (!inline && !path) {
    console.info('[push] Chưa cấu hình FIREBASE_SERVICE_ACCOUNT_PATH / _JSON: tắt push FCM.');
    return (account = null);
  }
  try {
    const json = parseServiceAccount(inline ? inline : readFileSync(path!, 'utf8'));
    if (!json.project_id || !json.client_email || !json.private_key) throw new Error('thiếu project_id / client_email / private_key');
    account = { project_id: json.project_id, client_email: json.client_email, private_key: json.private_key };
  } catch (error) {
    console.error('[push] Không đọc được file service account, tắt push FCM:', (error as Error).message);
    account = null;
  }
  return account;
}

/** Nội dung khoá: JSON nguyên văn, hoặc base64 của JSON (dễ dán vào biến môi trường của server) */
export function parseServiceAccount(raw: string): Partial<ServiceAccount> {
  const text = raw.trim().startsWith('{') ? raw : Buffer.from(raw.trim(), 'base64').toString('utf8');
  return JSON.parse(text) as Partial<ServiceAccount>;
}

/** Push có bật không (đã cấu hình khoá hợp lệ) */
export const isPushEnabled = () => loadAccount() !== null;

const base64url = (value: string | Buffer) => Buffer.from(value).toString('base64url');

/** JWT RS256 để đổi lấy access token (OAuth 2.0 service account flow) */
export function signAssertion(sa: ServiceAccount, nowSeconds: number) {
  const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = base64url(JSON.stringify({ iss: sa.client_email, scope: SCOPE, aud: TOKEN_URL, iat: nowSeconds, exp: nowSeconds + 3600 }));
  const signature = createSign('RSA-SHA256').update(`${header}.${claims}`).sign(sa.private_key);
  return `${header}.${claims}.${base64url(signature)}`;
}

async function getAccessToken(sa: ServiceAccount) {
  if (accessToken && accessToken.expiresAt > Date.now() + 60_000) return accessToken.value;
  const response = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: signAssertion(sa, Math.floor(Date.now() / 1000)),
    }),
    signal: AbortSignal.timeout(TIMEOUT_MS),
  });
  const json = await response.json() as { access_token?: string; expires_in?: number; error?: string };
  if (!response.ok || !json.access_token) throw new Error(`Google OAuth ${response.status}: ${json.error ?? 'no token'}`);
  accessToken = { value: json.access_token, expiresAt: Date.now() + (json.expires_in ?? 3600) * 1000 };
  return accessToken.value;
}

/** Body gửi FCM cho một token */
export function buildFcmMessage(token: string, { title, body, data, imageUrl }: PushMessage) {
  const image = imageUrl && /^https:\/\//.test(imageUrl) ? imageUrl : undefined;
  return {
    message: {
      token,
      notification: { title, body, ...(image && { image }) },
      data,
      android: { priority: 'HIGH', notification: { ...(data.tag && { tag: data.tag }) } },
      webpush: { headers: { Urgency: 'high' }, notification: { icon: '/icons/Icon-192.png', ...(data.tag && { tag: data.tag }) } },
    },
  };
}

/** Gửi một push tới một token */
export async function sendPush(token: string, message: PushMessage): Promise<PushResult> {
  const sa = loadAccount();
  if (!sa) return 'error';
  try {
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${await getAccessToken(sa)}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(buildFcmMessage(token, message)),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (response.ok) return 'ok';
    const text = await response.text();
    // Token không còn hợp lệ: gỡ app, xoá dữ liệu, token sai định dạng
    if (response.status === 404 || /UNREGISTERED|registration token is not a valid/i.test(text)) return 'invalid';
    if (response.status === 401) accessToken = null;
    console.error(`[push] FCM ${response.status}: ${text.slice(0, 300)}`);
    return 'error';
  } catch (error) {
    console.error('[push] FCM request failed:', (error as Error).message);
    return 'error';
  }
}
