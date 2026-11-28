import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Prisma } from '@prisma/client';
import { prisma } from '../src/lib/prisma.js';
import { respondOffer, submitReview } from '../src/modules/chat/services/trade.service.js';

type Review = {
  id: string; conversationId: string; authorId: string; recipientId: string; fromSeller: boolean;
  stars: number; comment: string; tags: string[]; publishedAt: Date | null;
};

/** Bộ nhớ giả cho một tin, một người mua, một hội thoại theo tin */
function fakeStore() {
  const listing = { id: 'phone', title: 'Phone', images: ['img'], price: new Prisma.Decimal(500), ownerId: 'seller', status: 'AVAILABLE', allowSale: true };
  const offer = {
    id: 'offer1', conversationId: 'ctx', listingId: 'phone', buyerId: 'buyer', sellerId: 'seller',
    amount: new Prisma.Decimal(450), listedPrice: new Prisma.Decimal(500), status: 'PENDING',
    expiresAt: new Date(Date.now() + 3_600_000), conversation: { threadId: 'root' }, listing,
  };
  const state = {
    listing, offer,
    trade: null as null | Record<string, any>,
    reviews: [] as Review[],
    messages: [] as string[],
    notifications: [] as { userId: string; type: string }[],
  };
  const tx = {
    $queryRaw: async () => [],
    $executeRaw: async () => 0,
    conversationMember: { findFirst: async () => null, updateMany: async () => ({ count: 0 }) },
    conversation: { updateMany: async () => ({ count: 0 }) },
    offer: {
      findUniqueOrThrow: async () => state.offer,
      update: async ({ data }: any) => Object.assign(state.offer, data),
    },
    listingTrade: {
      findUnique: async ({ include }: any = {}) =>
        state.trade && (include?.reviews ? { ...state.trade, reviews: state.reviews } : state.trade),
      create: async ({ data }: any) => (state.trade = { revealAt: null, closedAt: null, ...data }),
      update: async ({ data }: any) => Object.assign(state.trade!, data),
    },
    tradeReview: {
      create: async ({ data }: any) => state.reviews.push({ id: `r${state.reviews.length}`, publishedAt: null, ...data }),
      update: async ({ where, data }: any) => Object.assign(state.reviews.find((r) => r.id === where.id)!, data),
      updateMany: async ({ data }: any) => {
        const open = state.reviews.filter((r) => !r.publishedAt);
        open.forEach((r) => Object.assign(r, data));
        return { count: open.length };
      },
    },
    message: { create: async ({ data }: any) => (state.messages.push(data.text), { id: 'm', ...data }) },
    user: { findUniqueOrThrow: async ({ where }: any) => ({ fullName: where.id === 'buyer' ? 'Bình' : 'An' }) },
    notification: {
      createMany: async ({ data }: any) => (state.notifications.push(...data), { count: data.length }),
      findFirst: async () => null,
      deleteMany: async () => ({ count: 0 }),
    },
  };
  return { state, tx };
}

function mockPrisma(t: any, tx: any, state: ReturnType<typeof fakeStore>['state']) {
  t.mock.method(prisma, '$transaction', async (run: any) => run(tx));
  // Delegate của Prisma là proxy: gán thẳng thao tác cần dùng
  Object.assign(prisma.offer, { findUnique: async () => state.offer });
  Object.assign(prisma.conversation, { findUnique: async () => ({ threadId: 'root' }) });
}

test('seller accepts an offer: agreement opens reviews, listing stays for sale', async (t) => {
  const { state, tx } = fakeStore();
  mockPrisma(t, tx, state);

  await assert.rejects(respondOffer('buyer', 'offer1', 'accept'), { code: 'TRADE_FORBIDDEN' });
  await assert.rejects(respondOffer('seller', 'offer1', 'cancel'), { code: 'TRADE_FORBIDDEN' });
  await assert.rejects(respondOffer('stranger', 'offer1', 'accept'), { code: 'OFFER_NOT_FOUND' });

  const result = await respondOffer('seller', 'offer1', 'accept');
  assert.equal(result.status, 'ACCEPTED');
  assert.equal(state.offer.status, 'ACCEPTED');
  assert.equal(String(state.trade!.price), '450');
  assert.equal(String(state.trade!.listedPrice), '500');
  // Hạn đánh giá 30 ngày
  const days = (state.trade!.reviewDeadline.getTime() - state.trade!.acceptedAt.getTime()) / 86_400_000;
  assert.equal(days, 30);
  assert.equal(state.listing.status, 'AVAILABLE');
  assert.match(state.messages[0], /Đã chấp nhận đề nghị/);
  assert.deepEqual(state.notifications.map((n) => [n.userId, n.type]), [['buyer', 'OFFER_ACCEPTED']]);

  // Đề nghị đã xử lý thì không xử lý lại
  await assert.rejects(respondOffer('seller', 'offer1', 'reject'), { code: 'TRADE_CHANGED' });
});

test('expired offers cannot be accepted', async (t) => {
  const { state, tx } = fakeStore();
  state.offer.expiresAt = new Date(Date.now() - 1000);
  mockPrisma(t, tx, state);
  await assert.rejects(respondOffer('seller', 'offer1', 'accept'), { code: 'OFFER_EXPIRED' });
  assert.equal(state.offer.status, 'EXPIRED');
  assert.equal(state.trade, null);
});

test('reviews stay hidden until both sides review, editable until then', async (t) => {
  const { state, tx } = fakeStore();
  mockPrisma(t, tx, state);
  await respondOffer('seller', 'offer1', 'accept');
  state.notifications.length = 0;

  // Chưa thỏa thuận / người ngoài: không được đánh giá
  await assert.rejects(submitReview('stranger', 'ctx', { stars: 5 }), { code: 'TRADE_FORBIDDEN' });
  // Tiêu chí sai vai trò
  await assert.rejects(submitReview('buyer', 'ctx', { stars: 5, tags: ['paidAsAgreed'] }), { code: 'INVALID_TAG' });

  const first = await submitReview('buyer', 'ctx', { stars: 2, tags: ['communication'], comment: 'Trễ hẹn' });
  assert.equal(first.published, false);
  assert.equal(state.reviews[0].publishedAt, null);
  // Đánh giá đầu tiên mở 7 ngày chờ bên kia
  assert.ok(state.trade!.revealAt instanceof Date);
  assert.deepEqual(state.notifications.map((n) => [n.userId, n.type]), [['seller', 'REVIEW_WAITING']]);

  // Sửa trước khi công khai
  await submitReview('buyer', 'ctx', { stars: 3, tags: ['punctual'] });
  assert.equal(state.reviews.length, 1);
  assert.equal(state.reviews[0].stars, 3);

  // Bên kia gửi: công khai cả hai, đóng lượt đánh giá
  const second = await submitReview('seller', 'ctx', { stars: 5, tags: ['paidAsAgreed'] });
  assert.equal(second.published, true);
  assert.ok(state.reviews.every((r) => r.publishedAt instanceof Date));
  assert.ok(state.trade!.closedAt instanceof Date);
  await assert.rejects(submitReview('buyer', 'ctx', { stars: 4 }), { code: 'REVIEW_CLOSED' });
});

test('no review after the 30-day window when nobody has reviewed', async (t) => {
  const { state, tx } = fakeStore();
  mockPrisma(t, tx, state);
  await respondOffer('seller', 'offer1', 'accept');
  state.trade!.reviewDeadline = new Date(Date.now() - 1000);
  await assert.rejects(submitReview('buyer', 'ctx', { stars: 5 }), { code: 'REVIEW_CLOSED' });
  // Bên kia đã đánh giá ngày 30: vẫn còn đủ 7 ngày dù quá 30 ngày
  state.trade!.revealAt = new Date(Date.now() + 86_400_000);
  state.reviews.push({ id: 'old', conversationId: 'ctx', authorId: 'seller', recipientId: 'buyer', fromSeller: true, stars: 4, comment: '', tags: [], publishedAt: null });
  const late = await submitReview('buyer', 'ctx', { stars: 5 });
  assert.equal(late.published, true);
});
