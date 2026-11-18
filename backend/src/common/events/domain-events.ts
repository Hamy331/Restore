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
};

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
