/**
 * Thời gian hiển thị tin (tài liệu "Hạn mức đăng tin và hệ thống credit", mục "Chọn thời gian hiển thị và gia hạn tuỳ ngày").
 * Phần tính toán thuần, không đụng database, để test được. App tính lại cùng công thức để báo giá ngay khi chọn ngày.
 *
 * - Mỗi chuyên mục có số ngày miễn phí (Category.displayDays), thời gian tối đa (maxDisplayDays) và giá 30 ngày thêm (dayPackCredits).
 * - Giá một ngày = giá 30 ngày / 30. Mua đúng một mốc (30 / 60 / 90 ngày) thì giảm theo mốc, rồi giảm theo gói; làm tròn lên, ít nhất 1 xu.
 * - Gói cao được thêm ngày miễn phí (StorePackage.freeDaysPercent) nhưng không quá thời gian tối đa.
 */

export type DisplayRule = { displayDays: number; maxDisplayDays: number; dayPackCredits: number };
export type DayPack = { days: number; discountPercent: number };
export type PlanDisplay = { freeDaysPercent: number; extendDiscountPercent: number };

/** Ngày hẹn bắt đầu xa nhất (tính từ hôm nay) */
export const MAX_START_DELAY_DAYS = 14;
/** Số ngày mỗi lần tự gia hạn */
export const AUTO_EXTEND_DAYS = 30;

const percent = (value: number) => Math.min(100, Math.max(0, Math.round(value)));

/** Số ngày miễn phí của chuyên mục theo gói, ít nhất 1, không quá thời gian tối đa */
export const freeDaysFor = (rule: DisplayRule, plan: Pick<PlanDisplay, 'freeDaysPercent'>) =>
  Math.min(rule.maxDisplayDays, Math.max(1, Math.round((rule.displayDays * plan.freeDaysPercent) / 100)));

/** Giá xu cho [days] ngày thêm (0 khi không thêm ngày) */
export function extraDaysCredits(days: number, rule: DisplayRule, packs: DayPack[], plan: Pick<PlanDisplay, 'extendDiscountPercent'>) {
  if (days <= 0) return 0;
  const pack = packs.find((item) => item.days === days)?.discountPercent ?? 0;
  // Tính bằng số nguyên để không lệch làm tròn: days x giá30 x (100 - mốc) x (100 - gói) / (30 x 100 x 100)
  const numerator = days * rule.dayPackCredits * (100 - percent(pack)) * (100 - percent(plan.extendDiscountPercent));
  return Math.max(1, Math.ceil(numerator / 300_000));
}

/**
 * Mốc nên gợi ý thay cho [days] ngày lẻ: mốc nhỏ nhất dài hơn mà giá không cao hơn, và không vượt [maxDays].
 * Null khi [days] đã là một mốc hoặc không có mốc nào lợi hơn.
 */
export function suggestedPack(days: number, maxDays: number, rule: DisplayRule, packs: DayPack[], plan: Pick<PlanDisplay, 'extendDiscountPercent'>) {
  if (days <= 0 || packs.some((item) => item.days === days)) return null;
  const price = extraDaysCredits(days, rule, packs, plan);
  const better = [...packs].sort((a, b) => a.days - b.days)
    .find((item) => item.days > days && item.days <= maxDays && extraDaysCredits(item.days, rule, packs, plan) <= price);
  return better ? { days: better.days, credits: extraDaysCredits(better.days, rule, packs, plan) } : null;
}

/** Báo giá khi đăng: số ngày chọn (mặc định = miễn phí), số ngày phải trả và giá */
export function postingDisplayQuote(chosenDays: number | null, rule: DisplayRule, packs: DayPack[], plan: PlanDisplay) {
  const freeDays = freeDaysFor(rule, plan);
  const displayDays = chosenDays ?? freeDays;
  const paidDays = Math.max(0, displayDays - freeDays);
  return { freeDays, displayDays, paidDays, credits: extraDaysCredits(paidDays, rule, packs, plan) };
}
