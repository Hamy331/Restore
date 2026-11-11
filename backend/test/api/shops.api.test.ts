import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody } from './support/fixtures.js';

const { ctx } = useApi('shops');

/** Trang Shop uy tín: chỉ shop đã xác minh, tin giảm giá, tin theo shop, theo dõi shop */
test('trusted shops: overview, shop page, listings, follow, verified-shop feed', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const { Prisma } = await import('@prisma/client');

  // user-seller là shop đã xác minh; tin listing-1 đang giảm giá. user-admin có shop chưa xác minh (không hiện)
  await prisma.shop.create({ data: {
    id: 'shop-seller', ownerId: 'user-seller', name: 'Nội Thất Test', tagline: 'Gỗ thật', accentColor: '#8B5E3C',
    verificationType: 'CERTIFIED', verifiedAt: new Date(Date.now() - 86_400_000), categoryIds: ['furniture'],
  } });
  await prisma.shop.create({ data: { id: 'shop-hidden', ownerId: 'user-admin', name: 'Chưa xác minh', categoryIds: [] } });
  // poster chỉ hiện khi chủ shop còn gói Cửa hàng
  await prisma.storeSubscription.create({ data: {
    userId: 'user-seller', packageId: 'pro', categoryId: 'furniture', endsAt: new Date(Date.now() + 10 * 86_400_000),
  } });
  await prisma.shopBanner.create({ data: { id: 'banner-1', shopId: 'shop-seller', title: 'Sale', imageUrl: 'assets/images/banners/x.jpg', status: 'APPROVED' } });
  await prisma.shopBanner.create({ data: { id: 'banner-2', shopId: 'shop-seller', title: 'Chờ duyệt', imageUrl: 'assets/images/banners/y.jpg' } });
  await prisma.listing.update({ where: { id: 'listing-1' }, data: { originalPrice: new Prisma.Decimal(9_000_000), price: new Prisma.Decimal(6_000_000) } });

  const overview = await api.get('/shops/trusted/overview', { token: tokens.buyer });
  assert.equal(overview.status, 200, JSON.stringify(overview.body));
  const data = overview.body.data;
  assert.equal(data.stats.shopCount, 1);
  assert.ok(data.stats.listingCount >= 1);
  assert.deepEqual(data.categories.map((category: { id: string }) => category.id), ['furniture']);
  assert.deepEqual(data.banners.map((banner: { id: string; shop: { id: string } }) => [banner.id, banner.shop.id]), [['banner-1', 'shop-seller']]);
  assert.deepEqual(data.famousShops, [], 'chỉ shop chính hãng mới ở Thương hiệu nổi tiếng');
  assert.deepEqual(data.newShops.map((shop: { id: string }) => shop.id), ['shop-seller']);
  assert.deepEqual(data.deals.map((listing: { id: string }) => listing.id), ['listing-1']);
  assert.equal(data.deals[0].originalPrice, '9000000');
  assert.equal(data.showcases[0].shop.id, 'shop-seller');
  assert.ok(data.showcases[0].listings.length >= 1);

  const shop = await api.get('/shops/shop-seller', { token: tokens.buyer });
  assert.deepEqual([shop.body.data.name, shop.body.data.isFollowing, shop.body.data.followerCount], ['Nội Thất Test', false, 0]);
  assert.equal((await api.get('/shops/shop-hidden')).status, 404);

  assert.equal((await api.post('/shops/shop-seller/follow', { token: tokens.buyer })).status, 204);
  assert.equal((await api.post('/shops/shop-seller/follow', { token: tokens.buyer })).status, 204, 'theo dõi lại không lỗi');
  const followed = (await api.get('/shops/shop-seller', { token: tokens.buyer })).body.data;
  assert.deepEqual([followed.isFollowing, followed.followerCount], [true, 1]);
  assert.equal((await api.post('/shops/shop-seller/follow', { token: tokens.seller })).body.code, 'CANNOT_FOLLOW_OWN_SHOP');
  assert.equal((await api.post('/shops/shop-seller/follow')).status, 401);
  assert.equal((await api.delete('/shops/shop-seller/follow', { token: tokens.buyer })).status, 204);
  assert.equal((await api.get('/shops/shop-seller', { token: tokens.buyer })).body.data.followerCount, 0);

  const banners = await api.get('/shops/shop-seller/banners');
  assert.deepEqual(banners.body.data.map((banner: { id: string }) => banner.id), ['banner-1']);

  const cheap = await api.get('/shops/shop-seller/listings?sort=price_asc&condition=USED_GOOD,LIKE_NEW,NEW&limit=2');
  assert.equal(cheap.status, 200, JSON.stringify(cheap.body));
  assert.equal(cheap.body.data.length, 2);
  const prices = cheap.body.data.map((listing: { price: string }) => Number(listing.price));
  assert.deepEqual(prices, [...prices].sort((a, b) => a - b));
  assert.equal((await api.get('/shops/shop-seller/listings?condition=BROKEN')).body.code, 'INVALID_QUERY');

  const verified = await api.get('/listings?verifiedShop=true&onSale=true');
  assert.deepEqual(verified.body.data.map((listing: { id: string }) => listing.id), ['listing-1']);
  await prisma.shop.update({ where: { id: 'shop-seller' }, data: { verificationType: null } });
  assert.deepEqual((await api.get('/listings?verifiedShop=true')).body.data, [], 'bỏ xác minh thì không còn tin');
});

/** Giá gốc (bán giảm giá): chỉ gói Cửa hàng, cao hơn giá bán, sửa tin không được nâng giá gốc */
test('original price: only store plan, above price, cannot be raised on edit', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const token = tokens.buyer;
  const body = { ...listingBody('Máy pha cà phê Delonghi'), price: '2000000', originalPrice: '3000000' };

  const personal = await api.post('/listings', { token, body });
  assert.deepEqual([personal.status, personal.body.code, personal.body.field], [403, 'ORIGINAL_PRICE_NOT_ALLOWED', 'originalPrice']);

  await prisma.storeSubscription.create({ data: {
    userId: 'user-buyer', packageId: 'pro', categoryId: 'other', endsAt: new Date(Date.now() + 10 * 86_400_000),
  } });
  const lower = await api.post('/listings', { token, body: { ...body, originalPrice: '2000000' } });
  assert.deepEqual([lower.status, lower.body.field], [400, 'originalPrice']);

  const created = await api.post('/listings', { token, body });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  assert.equal(created.body.data.originalPrice, '3000000');
  const id = created.body.data.id;

  const raised = await api.put(`/listings/${id}`, { token, body: { ...body, originalPrice: '3500000' } });
  assert.deepEqual([raised.status, raised.body.code, raised.body.details?.maxOriginalPrice], [400, 'ORIGINAL_PRICE_RAISED', '3000000']);

  const deeper = await api.put(`/listings/${id}`, { token, body: { ...body, price: '1500000' } });
  assert.equal(deeper.status, 200, JSON.stringify(deeper.body));
  assert.deepEqual([deeper.body.data.price, deeper.body.data.originalPrice], ['1500000', '3000000']);

  const cleared = await api.put(`/listings/${id}`, { token, body: { ...body, price: '1500000', originalPrice: null } });
  assert.equal(cleared.body.data.originalPrice, null);
});
