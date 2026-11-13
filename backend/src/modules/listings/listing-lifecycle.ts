/**
 * Vòng đời hiển thị tin (tài liệu "Hạn mức đăng tin và hệ thống credit", mục "Hết hạn, gia hạn, kích hoạt lại").
 * Phần tính toán thuần, không đụng database, để test được.
 *
 * - Tin hiển thị Category.displayDays ngày kể từ lúc duyệt, quá hạn thì tự ẩn (HIDDEN, expiresAt đã qua).
 * - Kích hoạt lại tin hết hạn tính như đăng mới: còn suất miễn phí thì miễn phí, hết suất thì trả xu.
 * - Gia hạn tin đang hiển thị luôn tốn xu, thêm bao nhiêu ngày tuỳ chọn, miễn không quá thời gian tối đa của chuyên mục (display-pricing.ts).
 * - Đẩy tin lên đầu: gói nào cũng mua được bằng xu (Category.boostCredits), gói cao giảm giá
 *   (StorePackage.boostDiscountPercent) và có lượt tặng mỗi tháng (monthlyPromotionQuota). Mỗi tin đẩy tối đa 1 lần / ngày.
 * - Không cho đăng tin trùng tiêu đề với tin đang hiển thị của chính mình; trùng tin đã ẩn / hết hạn thì gợi ý kích hoạt lại.
 */

const DAY_MS = 24 * 60 * 60 * 1000;

/** Danh mục có hỏi tình trạng hàng không: metadata.hasCondition, mặc định có (thú cưng thì không) */
export const categoryHasCondition = (metadata: unknown) =>
  (metadata as { hasCondition?: unknown } | null)?.hasCondition !== false;

export const addDays = (from: Date, days: number) => new Date(from.getTime() + days * DAY_MS);

/** Tin đã quá hạn hiển thị (null = tin cũ chưa có hạn, coi như chưa hết hạn) */
export const isExpired = (expiresAt: Date | null, now: Date) => expiresAt !== null && expiresAt.getTime() <= now.getTime();

/** Hạn khi admin duyệt: tin sửa lại lúc còn hạn giữ hạn cũ (sửa tin không phải cách gia hạn miễn phí) */
export const approvedExpiry = (expiresAt: Date | null, now: Date, days: number) =>
  expiresAt && !isExpired(expiresAt, now) ? expiresAt : addDays(now, days);

/**
 * Khoảng hiển thị khi duyệt: bắt đầu từ ngày hẹn [startsAt] (duyệt muộn hơn thì từ lúc duyệt, để không mất ngày đã chọn),
 * đủ [days] ngày. [scheduled] = chưa tới ngày hẹn, tin chờ và job tự hiện. Tin còn hạn cũ thì giữ nguyên.
 */
export function approvalWindow(expiresAt: Date | null, startsAt: Date | null, now: Date, days: number) {
  if (expiresAt && !isExpired(expiresAt, now)) return { expiresAt, startsAt: null, scheduled: false };
  const scheduled = startsAt !== null && startsAt.getTime() > now.getTime();
  const start = scheduled ? startsAt! : now;
  return { expiresAt: addDays(start, days), startsAt: scheduled ? start : null, scheduled };
}

/** Số ngày còn thêm được trước khi chạm thời gian tối đa [maxDays] (tính từ hôm nay) */
export const addableDays = (expiresAt: Date | null, now: Date, maxDays: number) =>
  Math.max(0, maxDays - (expiresAt ? daysLeft(expiresAt, now) : 0));

/** Hạn mới sau khi gia hạn thêm [days] ngày */
export const extendedExpiry = (expiresAt: Date | null, now: Date, days: number) =>
  addDays(expiresAt && expiresAt.getTime() > now.getTime() ? expiresAt : now, days);

/** Số ngày còn lại (làm tròn lên), 0 khi đã hết hạn */
export const daysLeft = (expiresAt: Date, now: Date) => Math.max(0, Math.ceil((expiresAt.getTime() - now.getTime()) / DAY_MS));

/** Tiêu đề chuẩn hoá để so tin trùng: bỏ dấu, chữ thường, chỉ giữ chữ và số */
export function normalizeTitle(title: string) {
  return title.normalize('NFD').replace(/\p{M}/gu, '').replace(/đ/gi, 'd').toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ').trim();
}

/** Giá một lần đẩy tin sau khi giảm theo gói, làm tròn, tối thiểu 1 xu */
export const boostPrice = (base: number, discountPercent: number) =>
  Math.max(1, Math.round((base * (100 - Math.min(100, Math.max(0, discountPercent)))) / 100));

/**
 * Giá tin ưu tiên (Hot sale): nhóm A (boostCredits 10) trả giá gói VND / 1.000,
 * nhóm khác theo tỉ lệ boostCredits / 10, rồi giảm theo gói như đẩy tin.
 */
export const featurePrice = (packagePriceVnd: number, boostCredits: number, discountPercent: number) =>
  boostPrice((packagePriceVnd / 1000) * (boostCredits / 10), discountPercent);
