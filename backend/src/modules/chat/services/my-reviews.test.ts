import assert from 'node:assert/strict';
import test from 'node:test';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { listMyReviews } from './trade.service.js';
import { effectiveOfferStatus, reviewDeadline } from './trade.rules.js';

test('my reviews lists open agreements, own reviews and the whole history', async (t) => {
  const acceptedAt = new Date('2026-11-15T09:00:00.000Z');
  const reviewDeadlineAt = new Date('2099-12-15T09:00:00.000Z');
  const own = { authorId: 'buyer', stars: 5, comment: 'Great trade', tags: ['keptDeal'], createdAt: acceptedAt, publishedAt: null, removedAt: null };
  const theirs = { ...own, authorId: 'shop', stars: 2 };
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
      price: 1400000,
      listedPrice: 1500000,
      image: null,
      acceptedAt,
      reviewDeadline: reviewDeadlineAt,
      revealAt: null,
      closedAt: null,
      reviews: args.where?.reviews && 'some' in args.where.reviews ? [own, theirs] : [theirs],
    }];
  }) as never;
  prisma.user.findMany = (async () => [{ id: 'shop', fullName: 'Camera shop' }]) as never;

  const pending = await listMyReviews('buyer', {});
  const where = queries[0]?.where as Record<string, unknown>;
  assert.deepEqual(where.OR, [{ sellerId: 'buyer' }, { buyerId: 'buyer' }]);
  assert.deepEqual(where.reviews, { none: { authorId: 'buyer' } });
  assert.equal(where.closedAt, null);
  assert.deepEqual(pending.items[0], {
    conversationId: 'trade-context',
    title: 'Film camera',
    price: 1400000,
    listedPrice: 1500000,
    image: null,
    acceptedAt,
    deadline: reviewDeadlineAt,
    closed: false,
    isSeller: false,
    recipientName: 'Camera shop',
    // Biết bên kia đã đánh giá nhưng không thấy nội dung
    otherReviewed: true,
    review: null,
  });
  assert.equal(JSON.stringify(pending).includes('"stars":2'), false);

  const submitted = await listMyReviews('buyer', { status: 'submitted' });
  assert.deepEqual(queries[1]?.where?.reviews, { some: { authorId: 'buyer' } });
  assert.deepEqual(submitted.items[0]?.review, {
    stars: 5, comment: 'Great trade', tags: ['keptDeal'], createdAt: acceptedAt, publishedAt: null, removed: false,
  });
  // Lịch sử giao dịch: mọi thỏa thuận, không lọc theo đánh giá
  await listMyReviews('buyer', { status: 'all' });
  assert.deepEqual(queries[2]?.where, { OR: [{ sellerId: 'buyer' }, { buyerId: 'buyer' }] });
  await assert.rejects(listMyReviews('buyer', { status: 'received' }), { code: 'INVALID_FILTER' });
  assert.equal(queries.length, 3);
});

test('pending offers past their expiry read as expired; review deadline follows the 7-day wait', () => {
  const now = new Date('2026-12-01T00:00:00.000Z');
  assert.equal(effectiveOfferStatus({ status: 'PENDING', expiresAt: new Date('2026-11-30T00:00:00.000Z') }, now), 'EXPIRED');
  assert.equal(effectiveOfferStatus({ status: 'PENDING', expiresAt: new Date('2026-12-02T00:00:00.000Z') }, now), 'PENDING');
  assert.equal(effectiveOfferStatus({ status: 'REJECTED', expiresAt: new Date('2026-11-30T00:00:00.000Z') }, now), 'REJECTED');
  const deadline = new Date('2026-12-31T00:00:00.000Z');
  const reveal = new Date('2026-12-08T00:00:00.000Z');
  assert.equal(reviewDeadline({ revealAt: null, reviewDeadline: deadline }), deadline);
  // Đánh giá đầu tiên gửi ngày 30: bên kia vẫn có đủ 7 ngày, kể cả quá hạn 30 ngày
  const late = new Date('2027-01-06T00:00:00.000Z');
  assert.equal(reviewDeadline({ revealAt: late, reviewDeadline: deadline }), late);
  assert.equal(reviewDeadline({ revealAt: reveal, reviewDeadline: deadline }), reveal);
});
