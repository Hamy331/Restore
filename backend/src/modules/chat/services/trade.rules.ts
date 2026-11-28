import { Prisma } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';

const HOUR = 3_600_000;
const DAY = 24 * HOUR;

/** Người bán không phản hồi trong 72 giờ thì đề nghị hết hiệu lực */
export const OFFER_TTL_MS = 72 * HOUR;
/** Mỗi hội thoại tối đa chừng này đề nghị trong 24 giờ (chống spam trả giá) */
export const MAX_OFFERS_PER_DAY = 5;
/** Hạn gửi đánh giá đầu tiên kể từ khi chấp nhận đề nghị */
export const REVIEW_WINDOW_MS = 30 * DAY;
/** Thời gian chờ bên còn lại kể từ đánh giá đầu tiên */
export const REVEAL_DELAY_MS = 7 * DAY;
/** Nhắc đánh giá sau chừng này kể từ khi chấp nhận */
export const REVIEW_REMINDER_AFTER_MS = 3 * DAY;
/** Nhắc lần cuối khi còn chừng này tới hạn */
export const REVIEW_LAST_CALL_MS = DAY;

/** Người mua đánh giá người bán */
export const SELLER_REVIEW_TAGS = ['communication', 'asDescribed', 'punctual', 'keptDeal', 'friendly'] as const;
/** Người bán đánh giá người mua */
export const BUYER_REVIEW_TAGS = ['communication', 'punctual', 'keptDeal', 'paidAsAgreed', 'polite'] as const;

export const money = (value: Prisma.Decimal | number | string) =>
  `${Number(value).toLocaleString('vi-VN')} đ`;

/** Đề nghị PENDING đã quá hạn được coi là EXPIRED dù job chưa kịp cập nhật */
export const effectiveOfferStatus = (offer: { status: string; expiresAt: Date }, now = new Date()) =>
  offer.status === 'PENDING' && offer.expiresAt <= now ? 'EXPIRED' : offer.status;

/** Hạn còn được gửi / sửa đánh giá của một thỏa thuận */
export const reviewDeadline = (trade: { revealAt: Date | null; reviewDeadline: Date }) =>
  trade.revealAt ?? trade.reviewDeadline;

/**
 * Tạo đề nghị giá trong transaction gửi tin nhắn trả giá. Trả về id đề nghị để gắn vào thẻ tin nhắn.
 * Chỉ người mua (không phải chủ tin), tin còn bán, giá trong (0, giá niêm yết], chưa có thỏa thuận,
 * không có đề nghị đang chờ, tối đa MAX_OFFERS_PER_DAY đề nghị mỗi 24 giờ.
 */
export async function openOffer(
  tx: Prisma.TransactionClient,
  input: {
    contextId: string;
    buyerId: string;
    amount: number;
    listing: { id: string; ownerId: string; price: Prisma.Decimal; allowSale: boolean; status: string };
  },
) {
  const { contextId, buyerId, amount, listing } = input;
  const now = new Date();
  if (listing.ownerId === buyerId) {
    throw new AppError(403, 'OFFER_OWN_LISTING', 'Bạn không thể trả giá tin của chính mình.');
  }
  if (!listing.allowSale || listing.status !== 'AVAILABLE') {
    throw new AppError(409, 'LISTING_UNAVAILABLE', 'Tin đăng không còn khả dụng.');
  }
  if (!(amount > 0) || new Prisma.Decimal(amount).greaterThan(listing.price)) {
    throw new AppError(422, 'INVALID_OFFER', 'Giá đề nghị phải lớn hơn 0 và không cao hơn giá niêm yết.');
  }
  if (await tx.listingTrade.findUnique({ where: { conversationId: contextId }, select: { conversationId: true } })) {
    throw new AppError(409, 'OFFER_AGREED', 'Hai bên đã thống nhất giá cho tin này.');
  }
  await tx.offer.updateMany({
    where: { conversationId: contextId, status: 'PENDING', expiresAt: { lte: now } },
    data: { status: 'EXPIRED' },
  });
  if (await tx.offer.findFirst({ where: { conversationId: contextId, status: 'PENDING' }, select: { id: true } })) {
    throw new AppError(409, 'OFFER_PENDING', 'Bạn đã có đề nghị đang chờ. Thu hồi đề nghị đó trước khi gửi giá mới.');
  }
  const recent = await tx.offer.count({
    where: { conversationId: contextId, createdAt: { gt: new Date(now.getTime() - 24 * 3_600_000) } },
  });
  if (recent >= MAX_OFFERS_PER_DAY) {
    throw new AppError(429, 'OFFER_LIMIT', 'Bạn đã gửi quá nhiều đề nghị cho tin này. Thử lại sau 24 giờ.');
  }
  const offer = await tx.offer.create({
    data: {
      conversationId: contextId,
      listingId: listing.id,
      buyerId,
      sellerId: listing.ownerId,
      amount,
      listedPrice: listing.price,
      expiresAt: new Date(now.getTime() + OFFER_TTL_MS),
    },
    select: { id: true },
  });
  return offer.id;
}
