/**
 * Hạn mức đăng tin miễn phí của tài khoản Cá nhân (tài liệu "Hạn mức đăng tin và hệ thống credit").
 * Phần tính toán thuần, không đụng database, để test được.
 *
 * - Mỗi chuyên mục có số tin miễn phí riêng (Category.freeListingLimit).
 * - Cả tài khoản tối đa [totalLimit] tin miễn phí (StorePackage PERSONAL.activeListingLimit = 5).
 * - Chỉ tính tin đang chờ duyệt / đang hiển thị / đang giữ chỗ; tin trả bằng xu không chiếm suất.
 * - Chống đăng rồi ẩn liên tục: trong 30 ngày, mỗi chuyên mục đăng miễn phí tối đa gấp đôi số suất.
 * - Hết suất thì đăng được bằng xu (Category.extraListingCredits).
 * - Tin hiển thị số ngày người bán chọn (miễn phí tới Category.displayDays theo gói) rồi tự ẩn; xem display-pricing.ts.
 */

export const DISPLAY_DAYS = 60;
export const RECENT_WINDOW_DAYS = 30;
export const RECENT_MULTIPLIER = 2;

export type QuotaBlock = 'CATEGORY' | 'TOTAL' | 'RECENT';

export type CategoryRule = { id: string; freeListingLimit: number; extraListingCredits: number; displayDays: number };
export type CategoryUsage = { categoryId: string; used: number; recent: number };

export type CategoryQuota = {
  categoryId: string;
  used: number;
  limit: number;
  recentUsed: number;
  recentLimit: number;
  extraCredits: number;
  /** Giá (xu) mốc 30 ngày hiển thị thêm; service ghi đè theo gói */
  extendCredits: number;
  /** Số ngày hiển thị miễn phí; service ghi đè theo gói */
  displayDays: number;
  freeAvailable: boolean;
  blockedBy: QuotaBlock | null;
};

/** Lý do hết suất miễn phí ở chuyên mục, null = còn suất. Ưu tiên báo lý do người dùng dễ hiểu nhất. */
export function blockOf(used: number, limit: number, recent: number, totalUsed: number, totalLimit: number): QuotaBlock | null {
  if (used >= limit) return 'CATEGORY';
  if (totalUsed >= totalLimit) return 'TOTAL';
  if (recent >= limit * RECENT_MULTIPLIER) return 'RECENT';
  return null;
}

/** Hạn mức từng chuyên mục từ quy tắc và số tin đã dùng */
export function personalQuota(rules: CategoryRule[], usage: CategoryUsage[], totalLimit: number) {
  const byId = new Map(usage.map((item) => [item.categoryId, item]));
  const totalUsed = usage.reduce((sum, item) => sum + item.used, 0);
  const categories: CategoryQuota[] = rules.map((rule) => {
    const used = byId.get(rule.id)?.used ?? 0;
    const recent = byId.get(rule.id)?.recent ?? 0;
    const blockedBy = blockOf(used, rule.freeListingLimit, recent, totalUsed, totalLimit);
    return {
      categoryId: rule.id,
      used,
      limit: rule.freeListingLimit,
      recentUsed: recent,
      recentLimit: rule.freeListingLimit * RECENT_MULTIPLIER,
      extraCredits: rule.extraListingCredits,
      extendCredits: rule.extraListingCredits,
      displayDays: rule.displayDays,
      freeAvailable: blockedBy === null,
      blockedBy,
    };
  });
  return { total: { used: totalUsed, limit: totalLimit }, categories };
}
