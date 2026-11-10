/**
 * Vòng đời hiển thị tin (tài liệu "Hạn mức đăng tin và hệ thống credit", mục "Hết hạn, gia hạn, kích hoạt lại").
 * Phần tính toán thuần, không đụng database, để test được.
 *
 * - Tin hiển thị Category.displayDays ngày kể từ lúc duyệt, quá hạn thì tự ẩn (HIDDEN, expiresAt đã qua).
 * - Kích hoạt lại tin hết hạn tính như đăng mới: còn suất miễn phí thì miễn phí, hết suất thì trả xu.
 * - Gia hạn tin đang hiển thị luôn tốn xu, mỗi lần thêm displayDays ngày; chỉ gia hạn khi còn tối đa displayDays ngày.
 * - Không cho đăng tin trùng tiêu đề với tin đang hiển thị của chính mình; trùng tin đã ẩn / hết hạn thì gợi ý kích hoạt lại.
 */

const DAY_MS = 24 * 60 * 60 * 1000;

export const addDays = (from: Date, days: number) => new Date(from.getTime() + days * DAY_MS);

/** Tin đã quá hạn hiển thị (null = tin cũ chưa có hạn, coi như chưa hết hạn) */
export const isExpired = (expiresAt: Date | null, now: Date) => expiresAt !== null && expiresAt.getTime() <= now.getTime();

/** Hạn khi admin duyệt: tin sửa lại lúc còn hạn giữ hạn cũ (sửa tin không phải cách gia hạn miễn phí) */
export const approvedExpiry = (expiresAt: Date | null, now: Date, days: number) =>
  expiresAt && !isExpired(expiresAt, now) ? expiresAt : addDays(now, days);

/** Còn gia hạn được không: chỉ khi thời gian còn lại không quá một kỳ hiển thị */
export const canExtend = (expiresAt: Date | null, now: Date, days: number) =>
  expiresAt === null || expiresAt.getTime() - now.getTime() <= days * DAY_MS;

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
