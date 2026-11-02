/**
 * Môi trường cho contract test.
 * Bắt buộc TEST_DATABASE_URL trỏ tới database THỬ (localhost/127.0.0.1) vì mỗi file test
 * sẽ xóa sạch và tạo lại toàn bộ database đó.
 */
const url = process.env.TEST_DATABASE_URL;
if (!url) {
  throw new Error('Thiếu TEST_DATABASE_URL. VD: postgresql://postgres:postgres@127.0.0.1:54322/restore_test');
}
const host = new URL(url).hostname || new URL(url).searchParams.get('host') || '';
const isLocal = ['localhost', '127.0.0.1', '::1', ''].includes(host) || host.startsWith('/');
if (!isLocal && process.env.TEST_DB_ALLOW_REMOTE !== '1') {
  throw new Error(`TEST_DATABASE_URL phải là database local (đang là ${host}). Đặt TEST_DB_ALLOW_REMOTE=1 nếu chắc chắn.`);
}

Object.assign(process.env, {
  NODE_ENV: 'test',
  DATABASE_URL: url,
  DIRECT_URL: url,
  JWT_SECRET: 'test-jwt-secret-test-jwt-secret-123456',
  JWT_REFRESH_SECRET: 'test-refresh-secret-test-refresh-123456',
  JWT_RESET_SECRET: 'test-reset-secret-test-reset-secret-1234',
  OTP_SECRET: 'test-otp-secret-test-otp-secret-123456',
  RESEND_API_KEY: 're_test',
  EMAIL_FROM: 'no-reply@restore.test',
});

export const TEST_DATABASE_URL = url;
