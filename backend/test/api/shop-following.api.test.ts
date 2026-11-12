import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx } = useApi('shop-following');

/** Theo dõi shop: danh sách shop đang theo dõi, tin mới từ các shop đó, chủ shop xem người theo dõi */
test('shop following: followed shops, their listings, my shop followers, profile count', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  await prisma.shop.create({ data: {
    id: 'shop-seller', ownerId: 'user-seller', name: 'Nội Thất Test', verificationType: 'CERTIFIED', verifiedAt: new Date(), categoryIds: ['furniture'],
  } });
  await prisma.shop.create({ data: { id: 'shop-hidden', ownerId: 'user-admin', name: 'Chưa xác minh', categoryIds: [] } });

  assert.equal((await api.get('/shops/following')).status, 401);
  const empty = await api.get('/shops/following', { token: tokens.buyer });
  assert.equal(empty.status, 200, JSON.stringify(empty.body));
  assert.deepEqual([empty.body.data, empty.body.pagination.totalItems], [[], 0]);
  assert.deepEqual((await api.get('/shops/following/listings', { token: tokens.buyer })).body.data, []);

  assert.equal((await api.post('/shops/shop-seller/follow', { token: tokens.buyer })).status, 204);
  // shop chưa xác minh không theo dõi được và không hiện
  assert.equal((await api.post('/shops/shop-hidden/follow', { token: tokens.buyer })).status, 404);

  const followed = await api.get('/shops/following', { token: tokens.buyer });
  assert.equal(followed.body.data.length, 1);
  const shop = followed.body.data[0];
  assert.deepEqual([shop.id, shop.isFollowing, shop.followerCount], ['shop-seller', true, 1]);
  assert.ok(shop.followedAt);
  assert.ok(shop.newListingCount >= 0 && shop.newListingCount <= shop.listingCount);

  const listings = await api.get('/shops/following/listings?limit=5', { token: tokens.buyer });
  assert.equal(listings.status, 200, JSON.stringify(listings.body));
  assert.ok(listings.body.data.length >= 1);
  const owners = await prisma.listing.findMany({ where: { id: { in: listings.body.data.map((item: { id: string }) => item.id) } }, select: { ownerId: true } });
  assert.ok(owners.every((row) => row.ownerId === 'user-seller'), 'chỉ tin của shop đang theo dõi');

  const profile = await api.get('/users/me', { token: tokens.buyer });
  assert.equal(profile.body.data.followingShopCount, 1, JSON.stringify(profile.body.data));

  // chủ shop xem người theo dõi
  const mine = await api.get('/shops/me/followers', { token: tokens.seller });
  assert.equal(mine.status, 200, JSON.stringify(mine.body));
  assert.deepEqual(mine.body.data.map((user: { id: string }) => user.id), ['user-buyer']);
  assert.ok(mine.body.data[0].followedAt);

  await api.delete('/shops/shop-seller/follow', { token: tokens.buyer });
  assert.deepEqual((await api.get('/shops/following', { token: tokens.buyer })).body.data, []);
  assert.deepEqual((await api.get('/shops/me/followers', { token: tokens.seller })).body.data, []);
});

/** Gợi ý shop: shop chưa theo dõi, hợp danh mục tin đã lưu xếp trước, kèm tin xem trước */
test('shop following: suggestions rank by saved categories and skip followed shops', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const listing = await prisma.listing.findFirstOrThrow({ where: { ownerId: 'user-seller', status: 'AVAILABLE', categoryId: { not: null } } });
  await prisma.shop.upsert({
    where: { id: 'shop-seller' }, update: { categoryIds: [listing.categoryId!] },
    create: { id: 'shop-seller', ownerId: 'user-seller', name: 'Nội Thất Test', verificationType: 'CERTIFIED', verifiedAt: new Date(), categoryIds: [listing.categoryId!] },
  });
  await prisma.shop.upsert({
    where: { id: 'shop-hidden' }, update: { verificationType: 'OFFICIAL_BRAND', verifiedAt: new Date(), categoryIds: ['khac'] },
    create: { id: 'shop-hidden', ownerId: 'user-admin', name: 'Admin Brand', verificationType: 'OFFICIAL_BRAND', verifiedAt: new Date(), categoryIds: ['khac'] },
  });

  assert.equal((await api.get('/shops/following/suggestions')).status, 401);
  await api.post(`/listings/${listing.id}/favorite`, { token: tokens.buyer });
  const res = await api.get('/shops/following/suggestions', { token: tokens.buyer });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  const ids = res.body.data.map((shop: { id: string }) => shop.id);
  assert.equal(ids[0], 'shop-seller');
  assert.equal(res.body.data[0].reason, 'MATCHES_INTEREST');
  assert.equal(res.body.data[0].isFollowing, false);
  assert.ok(res.body.data[0].previews.length >= 1 && res.body.data[0].previews.length <= 3);
  const brand = res.body.data.find((shop: { id: string }) => shop.id === 'shop-hidden');
  assert.deepEqual([brand.isPartner, brand.reason], [true, 'PARTNER'], 'chính hãng là đối tác, xếp sau shop hợp sở thích');
  assert.equal(res.body.data[0].isPartner, false);

  // chủ shop không thấy shop của mình
  const own = await api.get('/shops/following/suggestions', { token: tokens.seller });
  assert.ok(!own.body.data.some((shop: { id: string }) => shop.id === 'shop-seller'));

  await api.post('/shops/shop-seller/follow', { token: tokens.buyer });
  const after = await api.get('/shops/following/suggestions', { token: tokens.buyer });
  assert.ok(!after.body.data.some((shop: { id: string }) => shop.id === 'shop-seller'), 'đã theo dõi thì không gợi ý');
  await api.delete('/shops/shop-seller/follow', { token: tokens.buyer });
  await api.delete(`/listings/${listing.id}/favorite`, { token: tokens.buyer });
});
