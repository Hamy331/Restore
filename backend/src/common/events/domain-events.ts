import type { Prisma } from '@prisma/client';

/**
 * Sự kiện nghiệp vụ giữa các module. Module phát sự kiện không cần biết ai nghe
 * (VD notifications nghe để ghi thông báo), nên không phải import ngược module đó.
 *
 * Phát trong transaction thì truyền [tx]: người nghe ghi cùng transaction, nghiệp vụ lỗi thì
 * không có gì được ghi. Phát ngoài transaction: lỗi của người nghe chỉ ghi log, không làm hỏng nghiệp vụ.
 */
export type DomainEvents = {
  /** Job hiện tin hẹn ngày đăng (1.7) */
  'listing.published': ListingRef;
  /** Job nhắc tin sắp hết hạn (1.8): còn [daysLeft] ngày (làm tròn lên), hết hạn lúc [expiresAt] */
  'listing.expiring': ListingRef & { expiresAt: Date; daysLeft: number };
  /** Job ẩn tin hết thời gian hiển thị (1.9) */
  'listing.expired': ListingRef & { expiresAt: Date };
  /** Job tự gia hạn tin: đã trừ [credits] xu, thêm [days] ngày (1.10) */
  'listing.autoExtended': ListingRef & { credits: number; days: number };
  /** Job tự gia hạn tin nhưng không đủ xu (1.10) */
  'listing.autoExtendFailed': ListingRef & { expiresAt: Date };
  /** Đơn nạp đã trả, đã cộng [credits] xu nạp + [bonus] xu tặng (2.1) */
  'credit.topupPaid': TopupRef & { credits: number; bonus: number };
  /** Đơn nạp thất bại trên cổng hoặc quá 15 phút chưa trả (2.2) */
  'credit.topupFailed': TopupRef & { status: 'FAILED' | 'EXPIRED' };
  /** Job nhắc xu tặng sắp hết hạn: [amount] xu hết hạn sớm nhất lúc [expiresAt] (2.4) */
  'credit.bonusExpiring': { userId: string; amount: number; expiresAt: Date; daysLeft: number };
  /** Tin bắt đầu được đẩy / lên Hot sale (2.5) */
  'promotion.started': ListingRef & PromotionRef;
  /** Job: lượt đẩy tin / Hot sale đã hết, không có lượt cùng loại nối tiếp (2.6) */
  'promotion.ended': ListingRef & PromotionRef;
  /** Admin từ chối đơn mua gói / đơn đẩy tin (2.7) */
  'order.rejected': { userId: string; orderId: string; kind: 'STORE_ORDER' | 'PROMOTION_ORDER'; packageName: string;
    listingId: string | null; listingTitle: string | null; reason: string };
  /** Mua / gia hạn / nâng cấp gói cửa hàng xong (2.8) */
  'plan.activated': PlanRef & { mode: 'NEW' | 'RENEW' | 'UPGRADE' | 'ORDER' };
  /** Job nhắc gói cửa hàng sắp hết hạn (2.9) */
  'plan.expiring': PlanRef & { daysLeft: number };
  /** Job: gói cửa hàng đã hết hạn, tài khoản về gói Cá nhân (2.9) */
  'plan.expired': PlanRef;
  /** Admin duyệt / từ chối poster của shop (2.10) */
  'poster.reviewed': { ownerId: string; posterId: string; title: string; imageUrl: string | null; approved: boolean;
    reason: string | null; note: string | null };
};

export type TopupRef = { userId: string; orderId: string; code: string };
export type PromotionRef = { promotionId: string; kind: 'BUMP' | 'FEATURED'; days: number; startsAt: Date; endsAt: Date };
export type PlanRef = { userId: string; packageId: string; planName: string; endsAt: Date };

export type ListingRef = { listingId: string; ownerId: string; title: string; image: string | null };

export type DomainEvent = keyof DomainEvents;
type Handler<K extends DomainEvent> = (payload: DomainEvents[K], tx?: Prisma.TransactionClient) => Promise<void>;

const handlers = new Map<DomainEvent, Handler<never>[]>();

/** Đăng ký nghe một sự kiện (gọi trong index.ts của module nghe) */
export function on<K extends DomainEvent>(event: K, handler: Handler<K>) {
  const list = handlers.get(event) ?? [];
  if (!list.includes(handler as Handler<never>)) list.push(handler as Handler<never>);
  handlers.set(event, list);
}

/** Phát sự kiện, chờ mọi người nghe chạy xong */
export async function emit<K extends DomainEvent>(event: K, payload: DomainEvents[K], tx?: Prisma.TransactionClient) {
  for (const handler of (handlers.get(event) ?? []) as Handler<K>[]) {
    if (tx) {
      await handler(payload, tx);
      continue;
    }
    try {
      await handler(payload);
    } catch (error) {
      console.error(`[events] ${event} handler failed`, error);
    }
  }
}

/** Xoá mọi người nghe (test) */
export const resetHandlers = () => handlers.clear();
