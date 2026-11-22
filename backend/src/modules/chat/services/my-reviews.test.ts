import assert from 'node:assert/strict';
import test from 'node:test';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { listMyReviews } from './trade.service.js';

test('my reviews filters confirmed trades and only returns reviews written by the caller', async (t) => {
  const confirmedAt = new Date('2026-11-15T09:00:00.000Z');
  const review = { stars: 5, comment: 'Great trade', tags: ['friendly'], createdAt: confirmedAt };
  const findTrades = prisma.listingTrade.findMany;
  const findUsers = prisma.user.findMany;
  t.after(() => {
    prisma.listingTrade.findMany = findTrades;
    prisma.user.findMany = findUsers;
  });
  const queries: Prisma.ListingTradeFindManyArgs[] = [];
  prisma.listingTrade.findMany = (async (args: Prisma.ListingTradeFindManyArgs) => {
    queries.push(args);
    return [{
      conversationId: 'trade-context',
      sellerId: 'shop',
      buyerId: 'buyer',
      title: 'Film camera',
      price: 1500000,
      image: null,
      confirmedAt,
      reviews: args.where?.reviews?.some ? [review] : [],
    }];
  }) as never;
  prisma.user.findMany = (async () => [{ id: 'shop', fullName: 'Camera shop' }]) as never;

  const pending = await listMyReviews('buyer', {});
  assert.deepEqual(queries[0]?.where, {
    confirmedAt: { not: null },
    OR: [{ sellerId: 'buyer' }, { buyerId: 'buyer' }],
    reviews: { none: { authorId: 'buyer' } },
  });
  assert.deepEqual(pending, {
    items: [{
      conversationId: 'trade-context',
      title: 'Film camera',
      price: 1500000,
      image: null,
      confirmedAt,
      isSeller: false,
      recipientName: 'Camera shop',
      review: null,
    }],
    hasMore: false,
  });

  const submitted = await listMyReviews('buyer', { status: 'submitted' });
  assert.deepEqual(queries[1]?.where?.reviews, {
    some: { authorId: 'buyer' },
  });
  assert.deepEqual(submitted.items[0]?.review, review);
  // Lịch sử giao dịch: mọi giao dịch đã hoàn tất, không lọc theo đánh giá
  await listMyReviews('buyer', { status: 'all' });
  assert.deepEqual(queries[2]?.where, {
    confirmedAt: { not: null },
    OR: [{ sellerId: 'buyer' }, { buyerId: 'buyer' }],
  });
  await assert.rejects(listMyReviews('buyer', { status: 'received' }), { code: 'INVALID_FILTER' });
  assert.equal(queries.length, 3);
});
