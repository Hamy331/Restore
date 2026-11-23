/*
 * Cảnh báo giá bất thường cho admin (không chặn người đăng): giá "câu khách" rất thấp là dấu hiệu lừa đảo hay gặp.
 * Giá 0 là tin chỉ trao đổi, không xét.
 */

/** Dưới mức này coi là giá ảo (VD 1đ, 1.000đ) */
export const TOO_LOW_PRICE = 10_000;
/** Thấp hơn 1/LOW_RATIO giá thường gặp của chuyên mục */
export const LOW_RATIO = 10;
/** Chuyên mục cần ít nhất ngần này tin có giá để tính giá thường gặp */
export const MIN_SAMPLES = 20;

export type PriceWarning = { reason: 'TOO_LOW' } | { reason: 'BELOW_TYPICAL'; typical: string };

/** [typical]: giá giữa (median) của chuyên mục, null khi chưa đủ mẫu */
export function priceWarning(price: { toString(): string }, typical: number | null | undefined): PriceWarning | null {
  const value = Number(price.toString());
  if (!(value > 0)) return null;
  if (value < TOO_LOW_PRICE) return { reason: 'TOO_LOW' };
  if (typical && value * LOW_RATIO < typical) return { reason: 'BELOW_TYPICAL', typical: Math.round(typical).toString() };
  return null;
}
