import { expireOffers, publishDueReviews } from '../modules/chat/services/trade.service.js';

/**
 * Mỗi 5 phút (chạy một lần ngay khi khởi động, nên khởi động lại server vẫn xử lý bù):
 * đề nghị giá quá 72 giờ hoặc tin không còn bán thì hết hiệu lực; đánh giá đủ 7 ngày thì công khai;
 * thỏa thuận quá 30 ngày không ai đánh giá thì đóng; gửi nhắc đánh giá.
 * Mọi bước kiểm tra lại trạng thái trong transaction nên chạy trùng (nhiều instance) không gây sai.
 */
export function startTradeJob(intervalMs = 5 * 60_000) {
  let running = false;
  const run = async () => {
    if (running) return;
    running = true;
    try {
      await expireOffers();
      await publishDueReviews();
    } catch (error) {
      console.error('Trade job failed', (error as { code?: string }).code ?? error);
    } finally {
      running = false;
    }
  };
  void run();
  const timer = setInterval(run, intervalMs);
  timer.unref();
  return timer;
}
