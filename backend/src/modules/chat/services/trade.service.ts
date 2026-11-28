import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { AppError } from '../../../common/errors/app-error.js';
// Không đi qua notifications/index.js: index đăng ký hook của module listings khi nạp (vòng import)
import { notify, type NotificationInput } from '../../notifications/notification.service.js';
import { writableThread, touchThread } from '../repositories/chat.repository.js';
import { publishChange } from './chat.service.js';
import {
  BUYER_REVIEW_TAGS,
  REVEAL_DELAY_MS,
  REVIEW_LAST_CALL_MS,
  REVIEW_REMINDER_AFTER_MS,
  REVIEW_WINDOW_MS,
  SELLER_REVIEW_TAGS,
  effectiveOfferStatus,
  money,
  reviewDeadline,
} from './trade.rules.js';

const conflict = (message = 'Giao dịch đã thay đổi. Hãy mở lại đoạn chat.') => new AppError(409, 'TRADE_CHANGED', message);
const forbidden = () => new AppError(403, 'TRADE_FORBIDDEN', 'Bạn không thể thực hiện thao tác này.');
const reviewClosed = () => new AppError(409, 'REVIEW_CLOSED', 'Đã hết thời hạn đánh giá cho giao dịch này.');

/** Hội thoại gốc (thread) của một hội thoại theo tin */
async function rootOf(conversationId: string) {
  const row = await prisma.conversation.findUnique({ where: { id: conversationId }, select: { threadId: true } });
  return row?.threadId ?? conversationId;
}

/* ---------------- Đề nghị giá ---------------- */

const OFFER_ACTIONS = ['accept', 'reject', 'cancel'] as const;
type OfferAction = (typeof OFFER_ACTIONS)[number];

/**
 * Người bán chấp nhận / từ chối, người mua thu hồi một đề nghị đang chờ.
 * Chấp nhận tạo thỏa thuận (ListingTrade) và mở quyền đánh giá 30 ngày; tin vẫn tiếp tục bán.
 */
export async function respondOffer(userId: string, offerId: string, action: unknown) {
  if (!OFFER_ACTIONS.includes(action as OfferAction)) throw new AppError(422, 'INVALID_ACTION', 'Thao tác không hợp lệ.');
  const found = await prisma.offer.findUnique({ where: { id: offerId }, select: { listingId: true, buyerId: true, sellerId: true } });
  if (!found || ![found.buyerId, found.sellerId].includes(userId)) {
    throw new AppError(404, 'OFFER_NOT_FOUND', 'Không tìm thấy đề nghị.');
  }
  const result = await prisma.$transaction(async (tx) => {
    // Tuần tự hoá mọi quyết định trên cùng một tin
    await tx.$queryRaw`SELECT id FROM "Listing" WHERE id = ${found.listingId} FOR UPDATE`;
    const offer = await tx.offer.findUniqueOrThrow({
      where: { id: offerId },
      include: { conversation: { select: { threadId: true } }, listing: { select: { ownerId: true, title: true, price: true, images: true, status: true, allowSale: true } } },
    });
    const root = offer.conversation.threadId ?? offer.conversationId;
    await writableThread(tx, root);
    const now = new Date();
    if (offer.status !== 'PENDING') throw conflict('Đề nghị này đã được xử lý.');
    if (effectiveOfferStatus(offer, now) === 'EXPIRED') {
      await tx.offer.update({ where: { id: offer.id }, data: { status: 'EXPIRED' } });
      return { expired: true as const };
    }
    const act = action as OfferAction;
    if ((act === 'cancel') !== (userId === offer.buyerId)) throw forbidden();
    const price = money(offer.amount);
    let text: string;
    if (act === 'accept') {
      const { listing } = offer;
      if (listing.ownerId !== offer.sellerId || listing.status !== 'AVAILABLE' || !listing.allowSale) {
        throw conflict('Tin đăng không còn khả dụng.');
      }
      if (await tx.listingTrade.findUnique({ where: { conversationId: offer.conversationId }, select: { conversationId: true } })) {
        throw conflict('Hai bên đã thống nhất giá cho tin này.');
      }
      await tx.listingTrade.create({
        data: {
          conversationId: offer.conversationId, offerId: offer.id, listingId: offer.listingId,
          sellerId: offer.sellerId, buyerId: offer.buyerId, title: listing.title, price: offer.amount,
          listedPrice: listing.price, image: listing.images[0] ?? null,
          acceptedAt: now, reviewDeadline: new Date(now.getTime() + REVIEW_WINDOW_MS),
        },
      });
      text = `Đã chấp nhận đề nghị ${price}. Hai bên có thể đánh giá nhau trong 30 ngày.`;
    } else {
      text = act === 'reject' ? `Đã từ chối đề nghị ${price}.` : `Đã thu hồi đề nghị ${price}.`;
    }
    await tx.offer.update({
      where: { id: offer.id },
      data: { status: act === 'accept' ? 'ACCEPTED' : act === 'reject' ? 'REJECTED' : 'CANCELLED', respondedAt: now },
    });
    const message = await tx.message.create({
      data: { conversationId: offer.conversationId, senderId: userId, clientId: randomUUID(), text },
    });
    await touchThread(tx, root, offer.conversationId);
    if (act !== 'cancel') {
      await notify({
        userId: offer.buyerId,
        type: act === 'accept' ? 'OFFER_ACCEPTED' : 'OFFER_REJECTED',
        title: act === 'accept' ? 'Đề nghị được chấp nhận' : 'Đề nghị bị từ chối',
        body: act === 'accept'
          ? `Người bán đã chấp nhận ${price} cho "${offer.listing.title}". Hãy đánh giá sau khi giao dịch.`
          : `Người bán đã từ chối ${price} cho "${offer.listing.title}". Bạn có thể gửi giá khác.`,
        imageUrl: offer.listing.images[0] ?? null,
        link: `/messages/${offer.conversationId}`,
        data: { listingId: offer.listingId, listingTitle: offer.listing.title, amount: offer.amount.toString(), conversationId: offer.conversationId },
      }, tx);
    }
    return { expired: false as const, root, message, contextId: offer.conversationId, members: [offer.buyerId, offer.sellerId] };
  });
  if (result.expired) throw new AppError(409, 'OFFER_EXPIRED', 'Đề nghị đã hết hiệu lực.');
  publishChange(result.members, 'trade.updated', result.root, { contextId: result.contextId, message: result.message });
  return { offerId, status: action === 'accept' ? 'ACCEPTED' : action === 'reject' ? 'REJECTED' : 'CANCELLED' };
}

/** Job: đề nghị quá 72 giờ hoặc tin không còn bán thì hết hiệu lực */
export async function expireOffers() {
  const rows = await prisma.$queryRaw<{ conversationId: string; buyerId: string; sellerId: string }[]>`
    UPDATE "Offer" o SET status = 'EXPIRED', "updatedAt" = now()
    FROM "Listing" l
    WHERE o."listingId" = l.id AND o.status = 'PENDING'
      AND (o."expiresAt" <= now() OR l.status <> 'AVAILABLE' OR l."allowSale" = false)
    RETURNING o."conversationId", o."buyerId", o."sellerId"`;
  for (const row of rows) {
    publishChange([row.buyerId, row.sellerId], 'trade.updated', await rootOf(row.conversationId), { contextId: row.conversationId });
  }
  return rows.length;
}

/* ---------------- Đánh giá ---------------- */

const reviewInput = z.object({
  stars: z.number().int().min(1).max(5),
  comment: z.string().trim().max(500).default(''),
  tags: z.array(z.string()).max(5).default([]),
});

/**
 * Gửi hoặc sửa đánh giá cho một thỏa thuận (double-blind).
 * - Hạn: 30 ngày từ khi chấp nhận; sau đánh giá đầu tiên, bên còn lại có 7 ngày.
 * - Cả hai đã gửi: công khai ngay và đóng lượt đánh giá. Chưa công khai thì được sửa.
 */
export async function submitReview(authorId: string, conversationId: string, input: unknown) {
  const parsed = reviewInput.safeParse(input);
  if (!parsed.success) throw new AppError(422, 'INVALID_REVIEW', 'Vui lòng kiểm tra số sao, nhận xét và tiêu chí.');
  const result = await prisma.$transaction(async (tx) => {
    await tx.$queryRaw`SELECT "conversationId" FROM "ListingTrade" WHERE "conversationId" = ${conversationId} FOR UPDATE`;
    const trade = await tx.listingTrade.findUnique({ where: { conversationId }, include: { reviews: true } });
    if (!trade || ![trade.sellerId, trade.buyerId].includes(authorId)) throw forbidden();
    const now = new Date();
    if (trade.closedAt || reviewDeadline(trade) <= now) throw reviewClosed();
    const fromSeller = authorId === trade.sellerId;
    const allowed: readonly string[] = fromSeller ? BUYER_REVIEW_TAGS : SELLER_REVIEW_TAGS;
    const tags = [...new Set(parsed.data.tags)];
    if (tags.some((t) => !allowed.includes(t))) throw new AppError(422, 'INVALID_TAG', 'Tiêu chí không phù hợp.');
    const recipientId = fromSeller ? trade.buyerId : trade.sellerId;
    const own = trade.reviews.find((r) => r.authorId === authorId);
    const other = trade.reviews.find((r) => r.authorId !== authorId);
    const data = { stars: parsed.data.stars, comment: parsed.data.comment, tags };
    if (own) {
      if (own.publishedAt) throw new AppError(409, 'REVIEW_LOCKED', 'Đánh giá đã công khai nên không sửa được.');
      await tx.tradeReview.update({ where: { id: own.id }, data });
    } else {
      await tx.tradeReview.create({ data: { ...data, conversationId, authorId, recipientId, fromSeller } });
    }
    let published = false;
    if (other) {
      await tx.tradeReview.updateMany({ where: { conversationId, publishedAt: null }, data: { publishedAt: now } });
      await tx.listingTrade.update({ where: { conversationId }, data: { closedAt: now } });
      published = true;
    } else if (!own) {
      await tx.listingTrade.update({ where: { conversationId }, data: { revealAt: new Date(now.getTime() + REVEAL_DELAY_MS) } });
    }
    const author = await tx.user.findUniqueOrThrow({ where: { id: authorId }, select: { fullName: true } });
    if (published) {
      await notify(publishedNotices(trade, now), tx);
    } else if (!own) {
      await notify({
        userId: recipientId,
        type: 'REVIEW_WAITING',
        title: 'Bạn vừa nhận được đánh giá',
        body: `${author.fullName} đã đánh giá bạn cho "${trade.title}". Đánh giá sẽ công khai khi bạn đánh giá lại hoặc sau 7 ngày.`,
        imageUrl: trade.image,
        link: `/messages/${conversationId}`,
        data: { conversationId, listingTitle: trade.title, userName: author.fullName },
        dedupeKey: `review-wait:${conversationId}`,
      }, tx);
    }
    return { members: [trade.sellerId, trade.buyerId], published };
  });
  publishChange(result.members, 'trade.updated', await rootOf(conversationId), { contextId: conversationId });
  return { conversationId, published: result.published };
}

function publishedNotices(trade: { conversationId: string; sellerId: string; buyerId: string; title: string; image: string | null }, now: Date): NotificationInput[] {
  return [trade.sellerId, trade.buyerId].map((userId) => ({
    userId,
    type: 'REVIEW_PUBLISHED' as const,
    title: 'Đánh giá đã được công khai',
    body: `Đánh giá cho giao dịch "${trade.title}" đã hiển thị trên hồ sơ.`,
    imageUrl: trade.image,
    link: '/account/ratings',
    data: { conversationId: trade.conversationId, listingTitle: trade.title },
    dedupeKey: `review-published:${trade.conversationId}:${now.getTime()}`,
  }));
}

/** Job: công khai đánh giá đã đủ 7 ngày, đóng thỏa thuận quá 30 ngày không ai đánh giá, nhắc đánh giá */
export async function publishDueReviews(limit = 200) {
  const now = new Date();
  const due = await prisma.listingTrade.findMany({
    where: { closedAt: null, revealAt: { lte: now } },
    select: { conversationId: true },
    take: limit,
  });
  let published = 0;
  for (const { conversationId } of due) {
    const done = await prisma.$transaction(async (tx) => {
      await tx.$queryRaw`SELECT "conversationId" FROM "ListingTrade" WHERE "conversationId" = ${conversationId} FOR UPDATE`;
      const trade = await tx.listingTrade.findUnique({ where: { conversationId } });
      if (!trade || trade.closedAt || !trade.revealAt || trade.revealAt > now) return null;
      await tx.tradeReview.updateMany({ where: { conversationId, publishedAt: null }, data: { publishedAt: now } });
      await tx.listingTrade.update({ where: { conversationId }, data: { closedAt: now } });
      await notify(publishedNotices(trade, now), tx);
      return trade;
    });
    if (done) {
      published++;
      publishChange([done.sellerId, done.buyerId], 'trade.updated', await rootOf(conversationId), { contextId: conversationId });
    }
  }
  // Không ai đánh giá trong 30 ngày: đóng quyền đánh giá
  const lapsed = await prisma.listingTrade.updateMany({
    where: { closedAt: null, revealAt: null, reviewDeadline: { lte: now } },
    data: { closedAt: now },
  });
  await sendReviewReminders(now, limit);
  return { published, lapsed: lapsed.count };
}

/** Nhắc đánh giá: 3 ngày sau khi chấp nhận, và còn 1 ngày trước hạn chờ 7 ngày */
async function sendReviewReminders(now: Date, limit: number) {
  const open = await prisma.listingTrade.findMany({
    where: {
      closedAt: null,
      OR: [
        { revealAt: null, acceptedAt: { lte: new Date(now.getTime() - REVIEW_REMINDER_AFTER_MS) }, reviewDeadline: { gt: now } },
        { revealAt: { gt: now, lte: new Date(now.getTime() + REVIEW_LAST_CALL_MS) } },
      ],
    },
    select: { conversationId: true, sellerId: true, buyerId: true, title: true, image: true, revealAt: true, reviews: { select: { authorId: true } } },
    orderBy: { acceptedAt: 'asc' },
    take: limit,
  });
  const inputs: NotificationInput[] = [];
  for (const trade of open) {
    for (const userId of [trade.sellerId, trade.buyerId]) {
      if (trade.reviews.some((r) => r.authorId === userId)) continue;
      const lastCall = !!trade.revealAt;
      inputs.push({
        userId,
        type: 'REVIEW_REMINDER',
        title: lastCall ? 'Còn 1 ngày để đánh giá' : 'Đừng quên đánh giá giao dịch',
        body: lastCall
          ? `Bên kia đã đánh giá bạn cho "${trade.title}". Còn khoảng 1 ngày để bạn gửi đánh giá của mình.`
          : `Hãy chia sẻ trải nghiệm giao dịch "${trade.title}" để cộng đồng mua bán tin cậy hơn.`,
        imageUrl: trade.image,
        link: `/messages/${trade.conversationId}`,
        data: { conversationId: trade.conversationId, listingTitle: trade.title },
        dedupeKey: `${lastCall ? 'review-last' : 'review-remind'}:${trade.conversationId}`,
      });
    }
  }
  await notify(inputs);
}

/** Người được đánh giá phản hồi công khai, một lần, sau khi đánh giá đã công khai */
export async function replyToReview(userId: string, reviewId: string, input: unknown) {
  const parsed = z.object({ text: z.string().trim().min(1).max(500) }).safeParse(input);
  if (!parsed.success) throw new AppError(422, 'INVALID_REPLY', 'Phản hồi cần 1–500 ký tự.');
  const { count } = await prisma.tradeReview.updateMany({
    where: { id: reviewId, recipientId: userId, publishedAt: { not: null }, removedAt: null, reply: null },
    data: { reply: parsed.data.text, repliedAt: new Date() },
  });
  if (!count) throw new AppError(409, 'REPLY_NOT_ALLOWED', 'Không thể phản hồi đánh giá này.');
  return { reviewId };
}

/** Đánh giá công khai trên hồ sơ (đã công khai, chưa bị gỡ) */
export async function listReviews(recipientId: string, query: Record<string, unknown>) {
  const params = z.object({ role: z.enum(['all','seller','buyer']).default('all'),
    sort: z.enum(['newest','oldest','highest','lowest']).default('newest'),
    page: z.coerce.number().int().min(1).max(100000).default(1) }).safeParse(query);
  if (!params.success) throw new AppError(422,'INVALID_FILTER','Bộ lọc không hợp lệ.');
  const {role,sort,page} = params.data;
  // sort: mới nhất (mặc định), cũ nhất, điểm cao, điểm thấp; cùng điểm thì mới trước
  const orderBy: Prisma.TradeReviewOrderByWithRelationInput[] = sort === 'oldest' ? [{publishedAt:'asc'},{id:'asc'}]
    : sort === 'highest' ? [{stars:'desc'},{publishedAt:'desc'},{id:'desc'}]
    : sort === 'lowest' ? [{stars:'asc'},{publishedAt:'desc'},{id:'desc'}]
    : [{publishedAt:'desc'},{id:'desc'}];
  const visible = { recipientId, publishedAt: { not: null }, removedAt: null } satisfies Prisma.TradeReviewWhereInput;
  const where = {...visible, ...(role === 'all' ? {} : {fromSeller:role === 'seller'})};
  const [groups, tags, items] = await prisma.$transaction([
    prisma.tradeReview.groupBy({by:['fromSeller'],where:visible,_count:true,_sum:{stars:true}}),
    prisma.$queryRaw<{tag:string,count:number}[]>`SELECT tag,count(*)::int AS count FROM "TradeReview", unnest(tags) AS tag
      WHERE "recipientId"=${recipientId} AND "publishedAt" IS NOT NULL AND "removedAt" IS NULL GROUP BY tag ORDER BY count DESC,tag`,
    prisma.tradeReview.findMany({ where, orderBy, skip:(page-1)*20,take:21,
      select:{id:true,stars:true,comment:true,tags:true,publishedAt:true,fromSeller:true,reply:true,repliedAt:true,
        author:{select:{id:true,fullName:true,avatarUrl:true}},trade:{select:{title:true,price:true,image:true}}} })
  ],{isolationLevel:'RepeatableRead'});
  const count = groups.reduce((n,g)=>n+g._count,0);
  return {
    items: items.slice(0,20).map(({ publishedAt, ...item }) => ({ ...item, createdAt: publishedAt })),
    hasMore:items.length>20,tags,count,sellers:groups.find(g=>g.fromSeller)?._count ?? 0,
    average:count ? groups.reduce((n,g)=>n+(g._sum.stars ?? 0),0)/count : 0,
  };
}

/**
 * Đánh giá của tôi. pending: còn hạn và mình chưa đánh giá; submitted: mình đã gửi;
 * all: mọi thỏa thuận (trang Lịch sử giao dịch).
 */
export async function listMyReviews(userId: string, query: Record<string, unknown>) {
  const params = z.object({
    status: z.enum(['pending', 'submitted', 'all']).default('pending'),
    page: z.coerce.number().int().min(1).max(100000).default(1),
  }).safeParse(query);
  if (!params.success) throw new AppError(422, 'INVALID_FILTER', 'Bộ lọc không hợp lệ.');

  const { status, page } = params.data;
  const now = new Date();
  const author = { authorId: userId };
  const pageSize = 20;
  const where: Prisma.ListingTradeWhereInput = {
    OR: [{ sellerId: userId }, { buyerId: userId }],
    ...(status === 'submitted' && { reviews: { some: author } }),
    ...(status === 'pending' && {
      closedAt: null,
      reviews: { none: author },
      AND: [{ OR: [{ revealAt: { gt: now } }, { revealAt: null, reviewDeadline: { gt: now } }] }],
    }),
  };
  const trades = await prisma.listingTrade.findMany({
    where,
    orderBy: [{ acceptedAt: 'desc' }, { conversationId: 'desc' }],
    skip: (page - 1) * pageSize,
    take: pageSize + 1,
    select: {
      conversationId: true, sellerId: true, buyerId: true, title: true, price: true, listedPrice: true,
      image: true, acceptedAt: true, reviewDeadline: true, revealAt: true, closedAt: true,
      reviews: { select: { authorId: true, stars: true, comment: true, tags: true, createdAt: true, publishedAt: true, removedAt: true } },
    },
  });
  const visibleTrades = trades.slice(0, pageSize);
  const otherId = (trade: { sellerId: string; buyerId: string }) =>
    trade.sellerId === userId ? trade.buyerId : trade.sellerId;
  const ids = [...new Set(visibleTrades.map(otherId))];
  const people = ids.length ? await prisma.user.findMany({
    where: { id: { in: ids } },
    select: { id: true, fullName: true },
  }) : [];
  const names = new Map(people.map(person => [person.id, person.fullName]));
  return {
    items: visibleTrades.map(trade => {
      const mine = trade.reviews.find((r) => r.authorId === userId);
      const deadline = reviewDeadline(trade);
      return {
        conversationId: trade.conversationId,
        title: trade.title,
        price: trade.price,
        listedPrice: trade.listedPrice,
        image: trade.image,
        acceptedAt: trade.acceptedAt,
        deadline,
        closed: !!trade.closedAt || deadline <= now,
        isSeller: trade.sellerId === userId,
        recipientName: names.get(otherId(trade)) ?? null,
        otherReviewed: trade.reviews.some((r) => r.authorId !== userId),
        review: mine
          ? {
              stars: mine.stars, comment: mine.comment, tags: mine.tags, createdAt: mine.createdAt,
              publishedAt: mine.publishedAt, removed: !!mine.removedAt,
            }
          : null,
      };
    }),
    hasMore: trades.length > pageSize,
  };
}

/* ---------------- Báo cáo / kiểm duyệt đánh giá ---------------- */

/** Đánh giá có thể bị báo cáo: đã công khai, chưa bị gỡ */
export const findReportableReview = (tx: Prisma.TransactionClient, id: string) =>
  tx.tradeReview.findFirst({ where: { id, publishedAt: { not: null }, removedAt: null }, select: { id: true, authorId: true } });

/** Chi tiết đánh giá cho trang quản trị */
export const getAdminReview = (id: string) =>
  prisma.tradeReview.findUnique({
    where: { id },
    select: {
      id: true, stars: true, comment: true, tags: true, fromSeller: true, createdAt: true, updatedAt: true,
      publishedAt: true, removedAt: true, removedReason: true, reply: true,
      author: { select: { id: true, fullName: true, email: true, status: true } },
      recipient: { select: { id: true, fullName: true, email: true, status: true } },
      trade: { select: { title: true, price: true } },
    },
  });

/** Admin gỡ đánh giá vi phạm: không hiển thị, điểm trung bình tính lại (trigger) và báo người viết */
export async function removeReviewForAdmin(tx: Prisma.TransactionClient, id: string, reason: string, updatedAt: Date) {
  const { count } = await tx.tradeReview.updateMany({
    where: { id, updatedAt, removedAt: null },
    data: { removedAt: new Date(), removedReason: reason.slice(0, 500) },
  });
  if (!count) throw new AppError(409, 'TARGET_CHANGED', 'Đánh giá đã thay đổi. Tải lại để xem.');
  const review = await tx.tradeReview.findUniqueOrThrow({ where: { id }, select: { authorId: true, trade: { select: { title: true } } } });
  await notify({
    userId: review.authorId,
    type: 'REVIEW_REMOVED',
    title: 'Đánh giá của bạn đã bị gỡ',
    body: `Đánh giá cho giao dịch "${review.trade.title}" vi phạm chính sách và đã bị gỡ. Lý do: ${reason}`,
    link: '/policies?section=conduct',
    data: { reviewId: id, listingTitle: review.trade.title, reason },
  }, tx);
}
