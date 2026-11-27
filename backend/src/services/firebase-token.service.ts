import { readFileSync } from 'node:fs';
import jwt from 'jsonwebtoken';
import { parseServiceAccount } from './push.service.js';

/**
 * Kiểm tra ID token của Firebase Authentication (app xác minh số điện thoại bằng OTP qua Firebase rồi gửi token lên).
 * Không dùng firebase-admin: lấy khoá công khai của Google, kiểm chữ ký RS256 và các claim theo tài liệu
 * "Verify ID tokens using a third-party JWT library" của Firebase.
 *
 * Project id lấy từ FIREBASE_PROJECT_ID, không có thì từ khoá service account của push (FIREBASE_SERVICE_ACCOUNT_*).
 */
const CERTS_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
const TIMEOUT_MS = 10_000;

export type FirebaseTokenClaims = {
  sub: string;
  phone_number?: string;
  auth_time: number;
  firebase?: { sign_in_provider?: string };
};

let projectId: string | null | undefined;
let certs: { keys: Record<string, string>; expiresAt: number } | null = null;

export function firebaseProjectId(): string | null {
  if (projectId !== undefined) return projectId;
  const explicit = process.env.FIREBASE_PROJECT_ID?.trim();
  if (explicit) return (projectId = explicit);
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT_JSON?.trim();
  const path = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
  try {
    if (inline || path) return (projectId = parseServiceAccount(inline ? inline : readFileSync(path!, 'utf8')).project_id ?? null);
  } catch {
    // Khoá hỏng: coi như chưa cấu hình
  }
  return (projectId = null);
}

/** Khoá công khai theo kid, giữ trong bộ nhớ theo Cache-Control max-age của Google */
async function publicKeys() {
  if (certs && certs.expiresAt > Date.now()) return certs.keys;
  const response = await fetch(CERTS_URL, { signal: AbortSignal.timeout(TIMEOUT_MS) });
  if (!response.ok) throw new Error(`certs ${response.status}`);
  const maxAge = Number(/max-age=(\d+)/.exec(response.headers.get('cache-control') ?? '')?.[1] ?? 3600);
  certs = { keys: await response.json() as Record<string, string>, expiresAt: Date.now() + maxAge * 1000 };
  return certs.keys;
}

export class FirebaseTokenError extends Error {
  constructor(readonly reason: 'unconfigured' | 'unavailable' | 'invalid') {
    super(reason);
  }
}

/** Trả claim của token hợp lệ; ném FirebaseTokenError nếu chưa cấu hình, không lấy được khoá hoặc token sai */
export async function verifyFirebaseIdToken(token: string): Promise<FirebaseTokenClaims> {
  const project = firebaseProjectId();
  if (!project) throw new FirebaseTokenError('unconfigured');
  const decoded = jwt.decode(token, { complete: true });
  const kid = decoded && typeof decoded.header.kid === 'string' ? decoded.header.kid : null;
  if (!kid) throw new FirebaseTokenError('invalid');
  let keys: Record<string, string>;
  try {
    keys = await publicKeys();
  } catch {
    throw new FirebaseTokenError('unavailable');
  }
  const cert = keys[kid];
  if (!cert) throw new FirebaseTokenError('invalid');
  try {
    const claims = jwt.verify(token, cert, {
      algorithms: ['RS256'], audience: project, issuer: `https://securetoken.google.com/${project}`,
    }) as FirebaseTokenClaims;
    if (!claims.sub || typeof claims.auth_time !== 'number' || claims.auth_time * 1000 > Date.now() + 60_000) {
      throw new FirebaseTokenError('invalid');
    }
    return claims;
  } catch {
    throw new FirebaseTokenError('invalid');
  }
}
