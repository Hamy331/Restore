import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { AppError } from '../../../common/errors/app-error.js';
import { deleteRevision } from '../../listings/repositories/listing.repository.js';
import { removeStoredImages, revisionOnlyImages } from '../../listings/services/image.service.js';
import { writableThread, touchThread } from '../repositories/chat.repository.js';
import { publish } from './chat.events.js';
import { publishListingChanged } from '../../listings/services/listing.events.js';

const conflict = () => new AppError(409, 'TRADE_CHANGED', 'Giao dịch đã thay đổi. Hãy mở lại đoạn chat.');
const forbidden = () => new AppError(403, 'TRADE_FORBIDDEN', 'Bạn không thể xác nhận thay người còn lại.');
const reviewInput = z.object({
  stars: z.number().int().min(1).max(5),
  comment: z.string().trim().max(500).default(''),
  tags: z.array(z.enum(['friendly','punctual','reliable','accurate','quality','fairPrice'])).max(6).default([]),
});

export async function changeTrade(userId: string, conversationId: string, action: unknown) {
  if (!['sell','receive','cancel'].includes(String(action))) throw new AppError(422,'INVALID_ACTION','Thao tác không hợp lệ.');
  const result = await prisma.$transaction(async tx => {
    const chat = await tx.conversation.findFirst({ where: { id: conversationId, members: { some: { userId } } },
      select: { threadId: true, listingId: true, members: { select: { userId: true } } } });
    if (!chat?.listingId) throw new AppError(404,'TRADE_NOT_FOUND','Không tìm thấy cuộc trò chuyện của tin đăng.');
    const root = chat.threadId ?? conversationId;
    await writableThread(tx,root);
    // One listing can have several buyer chats. Serialize decisions across all of them.
    await tx.$queryRaw`SELECT id FROM "Listing" WHERE id = ${chat.listingId} FOR UPDATE`;
    const listing = await tx.listing.findUniqueOrThrow({ where: { id: chat.listingId }, select: {
      id: true, ownerId: true, title: true, price: true, images: true, status: true, allowSale: true } });
    const sellerId = listing.ownerId;
    const buyerId = chat.members.find(m => m.userId !== sellerId)?.userId;
    if (!buyerId || !chat.members.some(m => m.userId === sellerId)) throw forbidden();
    const trade = await tx.listingTrade.findUnique({ where: { listingId: listing.id } });
    if (trade && trade.conversationId !== conversationId) throw conflict();
    let message: string;
    let dropped: string[] = [];
    if (action === 'sell') {
      if (userId !== sellerId) throw forbidden();
      if (trade) return null;
      if (!listing.allowSale || !['AVAILABLE','HIDDEN','SOLD'].includes(listing.status)) throw conflict();
      await tx.listingTrade.create({ data: { conversationId, listingId: listing.id, sellerId, buyerId,
        title: listing.title, price: listing.price, image: listing.images[0] } });
      message = 'Người bán đã xác nhận bán món này cho bạn.';
    } else if (action === 'receive') {
      if (userId !== buyerId) throw forbidden();
      if (!trade) throw conflict();
      if (trade.confirmedAt) return null;
      if (!listing.allowSale || !['AVAILABLE','HIDDEN','SOLD'].includes(listing.status)) throw conflict();
      await tx.listing.update({ where: { id: listing.id }, data: { status: 'SOLD' } });
      const revision = await deleteRevision(tx, listing.id);
      dropped = revisionOnlyImages(revision?.images ?? [], listing.images);
      await tx.listingTrade.update({ where: { conversationId }, data: { confirmedAt: new Date() } });
      message = 'Người mua đã nhận hàng. Hai bên có thể đánh giá nhau.';
    } else {
      if (!trade || trade.confirmedAt) throw conflict();
      await tx.listingTrade.delete({ where: { conversationId } });
      message = 'Đã hủy yêu cầu xác nhận giao dịch.';
    }
    await tx.message.create({ data: { conversationId, senderId: userId, clientId: randomUUID(), text: message } });
    await touchThread(tx,root,conversationId);
    return { members: [buyerId,sellerId], dropped, listingId: listing.id };
  });
  if (result) {
    publish(result.members,'message',{ conversationId });
    publishListingChanged(result.listingId);
    await removeStoredImages(result.dropped);
  }
  return { conversationId };
}

export async function submitReview(authorId: string, conversationId: string, input: unknown) {
  const parsed = reviewInput.safeParse(input);
  if (!parsed.success) throw new AppError(422,'INVALID_REVIEW','Vui lòng kiểm tra số sao, nhận xét và thẻ.');
  const trade = await prisma.listingTrade.findUnique({ where: { conversationId } });
  if (!trade || ![trade.sellerId, trade.buyerId].includes(authorId)) throw forbidden();
  if (!trade.confirmedAt) throw conflict();
  const fromSeller = authorId === trade.sellerId;
  const tags = [...new Set(parsed.data.tags)];
  if (tags.some(t => fromSeller ? ['accurate','quality'].includes(t) : t === 'fairPrice')) throw new AppError(422,'INVALID_TAG','Thẻ không phù hợp.');
  const recipientId = fromSeller ? trade.buyerId : trade.sellerId;
  try {
    await prisma.tradeReview.create({ data: { ...parsed.data, tags, authorId, conversationId, fromSeller, recipientId } });
  } catch (error) {
    if (!(error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002')) throw error;
    const prior = await prisma.tradeReview.findUnique({where:{conversationId_authorId:{conversationId,authorId}}});
    if (!prior || prior.stars !== parsed.data.stars || prior.comment !== parsed.data.comment || tags.slice().sort().join() !== prior.tags.slice().sort().join()) throw conflict();
  }
  return { conversationId };
}

export async function listReviews(recipientId: string, query: Record<string, unknown>) {
  const params = z.object({ role: z.enum(['all','seller','buyer']).default('all'),
    sort: z.enum(['newest','oldest','highest','lowest']).default('newest'),
    page: z.coerce.number().int().min(1).max(100000).default(1) }).safeParse(query);
  if (!params.success) throw new AppError(422,'INVALID_FILTER','Bộ lọc không hợp lệ.');
  const {role,sort,page} = params.data;
  // sort: mới nhất (mặc định), cũ nhất, điểm cao, điểm thấp; cùng điểm thì mới trước
  const orderBy: Prisma.TradeReviewOrderByWithRelationInput[] = sort === 'oldest' ? [{createdAt:'asc'},{id:'asc'}]
    : sort === 'highest' ? [{stars:'desc'},{createdAt:'desc'},{id:'desc'}]
    : sort === 'lowest' ? [{stars:'asc'},{createdAt:'desc'},{id:'desc'}]
    : [{createdAt:'desc'},{id:'desc'}];
  const where = {recipientId, ...(role === 'all' ? {} : {fromSeller:role === 'seller'})};
  const [groups, tags, items] = await prisma.$transaction([
    prisma.tradeReview.groupBy({by:['fromSeller'],where:{recipientId},_count:true,_sum:{stars:true}}),
    prisma.$queryRaw<{tag:string,count:number}[]>`SELECT tag,count(*)::int AS count FROM "TradeReview", unnest(tags) AS tag WHERE "recipientId"=${recipientId} GROUP BY tag ORDER BY count DESC,tag`,
    prisma.tradeReview.findMany({ where, orderBy, skip:(page-1)*20,take:21,
      select:{id:true,stars:true,comment:true,tags:true,createdAt:true,fromSeller:true,author:{select:{fullName:true,avatarUrl:true}},trade:{select:{title:true,price:true,image:true}}} })
  ],{isolationLevel:'RepeatableRead'});
  const count = groups.reduce((n,g)=>n+g._count,0);
  return {items:items.slice(0,20),hasMore:items.length>20,tags,count,sellers:groups.find(g=>g.fromSeller)?._count ?? 0,
    average:count ? groups.reduce((n,g)=>n+(g._sum.stars ?? 0),0)/count : 0};
}

export async function listMyReviews(userId: string, query: Record<string, unknown>) {
  const params = z.object({
    /** all: mọi giao dịch đã hoàn tất (trang Lịch sử giao dịch), có hoặc chưa đánh giá */
    status: z.enum(['pending', 'submitted', 'all']).default('pending'),
    page: z.coerce.number().int().min(1).max(100000).default(1),
  }).safeParse(query);
  if (!params.success) throw new AppError(422, 'INVALID_FILTER', 'Bộ lọc không hợp lệ.');

  const { status, page } = params.data;
  const author = { authorId: userId };
  const pageSize = 20;
  const trades = await prisma.listingTrade.findMany({
    where: {
      confirmedAt: { not: null },
      OR: [{ sellerId: userId }, { buyerId: userId }],
      ...(status === 'all' ? {} : { reviews: status === 'pending' ? { none: author } : { some: author } }),
    },
    orderBy: [{ confirmedAt: 'desc' }, { conversationId: 'desc' }],
    skip: (page - 1) * pageSize,
    take: pageSize + 1,
    select: {
      conversationId: true, sellerId: true, buyerId: true,
      title: true, price: true, image: true, confirmedAt: true,
      reviews: { where: author, select: { stars: true, comment: true, tags: true, createdAt: true } },
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
    items: visibleTrades.map(trade => ({
      conversationId: trade.conversationId,
      title: trade.title,
      price: trade.price,
      image: trade.image,
      confirmedAt: trade.confirmedAt,
      isSeller: trade.sellerId === userId,
      recipientName: names.get(otherId(trade)) ?? null,
      review: trade.reviews[0] ?? null,
    })),
    hasMore: trades.length > pageSize,
  };
}
