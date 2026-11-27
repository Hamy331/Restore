import { notifyEndedPromotions, remindStorePlans } from '../modules/commerce/index.js';
import {
  expireBonusCredits, expireStaleTopups, reconcileSepayTransactions, remindBonusExpiring,
} from '../modules/credits/index.js';

/**
 * Mỗi 5 phút (chạy một lần ngay khi khởi động), cho nhóm thông báo Ví Xu, đẩy tin, gói:
 * đối soát giao dịch SePay mà webhook bị lỡ (cần SEPAY_API_TOKEN),
 * đóng đơn nạp quá 15 phút chưa trả (2.2), trừ xu tặng đã hết hạn, nhắc xu tặng sắp hết hạn (2.4),
 * báo hết thời gian đẩy tin / Hot sale (2.6), nhắc gói cửa hàng sắp hết / đã hết hạn (2.9).
 * Mỗi việc chạy riêng: một việc lỗi không chặn việc khác.
 */
export function startWalletReminderJob(intervalMs = 5 * 60_000) {
  // Đối soát chạy trước khi đóng đơn quá hạn: tiền đã tới thì đơn được trả, không bị báo hết hạn nhầm
  const tasks = [reconcileSepayTransactions, expireStaleTopups, expireBonusCredits, remindBonusExpiring, notifyEndedPromotions, remindStorePlans];
  const run = async () => {
    for (const task of tasks) {
      try {
        await task();
      } catch (error) {
        console.error(`[jobs] ${task.name} failed`, (error as { code?: string }).code ?? error);
      }
    }
  };
  void run();
  const timer = setInterval(run, intervalMs);
  timer.unref();
  return timer;
}
