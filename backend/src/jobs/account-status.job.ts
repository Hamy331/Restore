import { releaseExpiredSuspensions } from '../lib/account-status.js';

/** Mỗi phút mở khóa các tài khoản đã hết thời hạn tạm khóa. */
export function startAccountStatusJob(intervalMs = 60_000) {
  const timer = setInterval(
    () => releaseExpiredSuspensions().catch((error) => console.error('Suspension expiry failed', error.code)),
    intervalMs,
  );
  timer.unref();
  return timer;
}
