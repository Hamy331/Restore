import { expireDueListings } from '../modules/listings/index.js';

/** Mỗi 10 phút ẩn các tin đã hết thời gian hiển thị (chạy một lần ngay khi khởi động). */
export function startListingExpiryJob(intervalMs = 10 * 60_000) {
  const run = () => expireDueListings().catch((error) => console.error('Listing expiry failed', error.code ?? error));
  void run();
  const timer = setInterval(run, intervalMs);
  timer.unref();
  return timer;
}
