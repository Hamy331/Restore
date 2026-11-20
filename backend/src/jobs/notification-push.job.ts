import { dispatchPendingPushes } from '../modules/notifications/notification.push.js';
import { isPushEnabled } from '../services/push.service.js';

/**
 * Mỗi 30 giây gửi push FCM cho thông báo chưa gửi (dòng commit chậm hơn lượt gửi ngay sau notify()).
 * Không cấu hình FIREBASE_SERVICE_ACCOUNT_PATH thì không chạy.
 */
export function startNotificationPushJob(intervalMs = 30_000) {
  if (!isPushEnabled()) return null;
  const run = () => dispatchPendingPushes().catch((error) => console.error('[push] job failed', error));
  void run();
  const timer = setInterval(run, intervalMs);
  timer.unref();
  return timer;
}
