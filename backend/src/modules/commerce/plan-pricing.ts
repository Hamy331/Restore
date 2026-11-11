/**
 * Giá mua / gia hạn / nâng cấp gói tài khoản bằng xu (tài liệu "Hạn mức đăng tin và hệ thống credit",
 * mục "Loại tài khoản theo gói" và "Vòng đời gói"). Phần tính toán thuần để test được.
 *
 * - Giá gói lưu bằng VND (StorePackage.monthlyPrice), trả bằng xu: 1 xu = 1.000 đ, làm tròn lên.
 * - Mua mới: trả đủ giá, dùng 30 ngày từ hôm nay.
 * - Gia hạn đúng gói đang dùng: trả đủ giá, cộng 30 ngày nối tiếp ngày hết hạn cũ.
 * - Nâng gói giữa kỳ: có hiệu lực ngay, trừ phần giá trị còn lại của gói cũ theo số ngày còn lại,
 *   kỳ mới 30 ngày tính từ hôm nay.
 * - Hạ gói khi gói cao hơn còn hạn: không cho, đợi gói hiện tại hết hạn.
 */

export const VND_PER_CREDIT = 1000;
export const PLAN_PERIOD_MS = 30 * 24 * 60 * 60 * 1000;

/** Giá gói theo xu từ giá VND */
export const planPriceCredits = (monthlyPrice: { toString(): string } | number) =>
  Math.ceil(Number(monthlyPrice.toString()) / VND_PER_CREDIT);

export type PlanRef = { packageId: string; priorityLevel: number; priceCredits: number };
export type CurrentPlan = PlanRef & { endsAt: Date };
export type PlanMode = 'NEW' | 'RENEW' | 'UPGRADE';
export type PlanQuote = { mode: PlanMode; price: number; credit: number; amount: number; endsAt: Date };

/** Báo giá đổi sang gói [target]; null khi là hạ gói lúc gói hiện tại còn hạn */
export function quotePlan(target: PlanRef, current: CurrentPlan | null, now: Date): PlanQuote | null {
  const price = target.priceCredits;
  const active = current && current.endsAt.getTime() > now.getTime() ? current : null;
  if (!active) return { mode: 'NEW', price, credit: 0, amount: price, endsAt: new Date(now.getTime() + PLAN_PERIOD_MS) };
  if (active.packageId === target.packageId) {
    return { mode: 'RENEW', price, credit: 0, amount: price, endsAt: new Date(active.endsAt.getTime() + PLAN_PERIOD_MS) };
  }
  if (target.priorityLevel <= active.priorityLevel) return null;
  const left = Math.min(1, (active.endsAt.getTime() - now.getTime()) / PLAN_PERIOD_MS);
  const credit = Math.min(price, Math.floor(active.priceCredits * left));
  return { mode: 'UPGRADE', price, credit, amount: price - credit, endsAt: new Date(now.getTime() + PLAN_PERIOD_MS) };
}
