import { autoExtendDueListings, expireDueListings, publishScheduledListings, remindExpiringListings } from '../modules/listings/index.js';

/**
 * Mỗi 10 phút (chạy một lần ngay khi khởi động): tự gia hạn tin bật tự gia hạn, hiện tin tới ngày hẹn,
 * ẩn các tin đã hết thời gian hiển thị, rồi nhắc người bán các tin sắp hết hạn.
 */
export function startListingExpiryJob(intervalMs = 10 * 60_000) {
  const run = async () => {
    try {
      await autoExtendDueListings();
      await publishScheduledListings();
      await expireDueListings();
      await remindExpiringListings();
    } catch (error) {
      console.error('Listing expiry failed', (error as { code?: string }).code ?? error);
    }
  };
  void run();
  const timer = setInterval(run, intervalMs);
  timer.unref();
  return timer;
}
