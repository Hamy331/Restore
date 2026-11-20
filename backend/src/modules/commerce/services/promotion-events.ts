import type { DomainEvents } from '../../../common/events/domain-events.js';
import { DAY_MS } from '../commerce.type.js';

type ListingLike = { id: string; ownerId: string; title: string; images: string[] };
type PromotionLike = { id: string; startsAt: Date; endsAt: Date; package: { kind: 'BUMP' | 'FEATURED' } };

/** Sự kiện "tin bắt đầu được đẩy / lên Hot sale" (2.5) cho một lượt quảng bá vừa tạo */
export const promotionEvent = (listing: ListingLike, promotion: PromotionLike): DomainEvents['promotion.started'] => ({
  listingId: listing.id,
  ownerId: listing.ownerId,
  title: listing.title,
  image: listing.images[0] ?? null,
  promotionId: promotion.id,
  kind: promotion.package.kind,
  days: Math.max(1, Math.round((promotion.endsAt.getTime() - promotion.startsAt.getTime()) / DAY_MS)),
  startsAt: promotion.startsAt,
  endsAt: promotion.endsAt,
});
