import { autoExtendDueListings, expireDueListings, publishScheduledListings } from '../modules/listings/index.js';

/**
 * Mỗi 10 phút (chạy một lần ngay khi khởi động): tự gia hạn tin bật tự gia hạn, hiện tin tới ngày hẹn,
 * rồi ẩn các tin đã hết thời gian hiển thị.
 */
export function startListingExpiryJob(intervalMs = 10 * 60_000) {
  const run = async () => {
    try {
      await autoExtendDueListings();
      await publishScheduledListings();
      await expireDueListings();
    } catch (error) {
      console.error('Listing expiry failed', (error as { code?: string }).code ?? error);
    }
  };
  void run();
  const timer = setInterval(run, intervalMs);
  timer.unref();
  return timer;
}
