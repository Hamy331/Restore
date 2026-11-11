import type { ShopBannerRejectReason } from '@prisma/client';

/**
 * Luật poster shop (số lượng theo gói nằm ở StorePackage.posterActiveLimit / posterMonthlyLimit):
 * mỗi poster chạy 3-14 ngày, hẹn ngày bắt đầu trước tối đa 14 ngày,
 * bị từ chối 3 lần trong 30 ngày thì khóa gửi 7 ngày tính từ lần từ chối gần nhất.
 */
export const POSTER_RULES = {
  minDays: 3,
  maxDays: 14,
  maxLeadDays: 14,
  rejectWindowDays: 30,
  rejectsBeforeCooldown: 3,
  cooldownDays: 7,
} as const;

export const REJECT_REASONS = ['WRONG_SIZE', 'MISLEADING_PRICE', 'BRAND_MISUSE', 'PROHIBITED', 'TOO_MUCH_TEXT', 'OTHER'] as const satisfies readonly ShopBannerRejectReason[];

export const DAY = 86_400_000;

/** Trạng thái hiển thị cho app: chờ duyệt, đã lên lịch, đang chạy, đã kết thúc, bị từ chối, đã dừng */
export type PosterState = 'PENDING' | 'SCHEDULED' | 'RUNNING' | 'ENDED' | 'REJECTED' | 'STOPPED';

export function posterState(poster: { status: string; startsAt: Date | null; endsAt: Date | null }, now: Date): PosterState {
  const ended = poster.endsAt !== null && poster.endsAt <= now;
  switch (poster.status) {
    case 'PENDING': return ended ? 'ENDED' : 'PENDING';
    case 'REJECTED': return 'REJECTED';
    case 'STOPPED': return 'STOPPED';
    default:
      if (ended) return 'ENDED';
      return poster.startsAt && poster.startsAt > now ? 'SCHEDULED' : 'RUNNING';
  }
}

/**
 * Hạn khóa gửi poster: [rejections] là thời điểm bị từ chối (mới nhất trước) trong 30 ngày gần đây.
 * Đủ 3 lần thì khóa tới lần gần nhất + 7 ngày; hết khóa hoặc chưa đủ thì null.
 */
export function cooldownUntil(rejections: Date[], now: Date): Date | null {
  if (rejections.length < POSTER_RULES.rejectsBeforeCooldown) return null;
  const until = new Date(rejections[0].getTime() + POSTER_RULES.cooldownDays * DAY);
  return until > now ? until : null;
}
