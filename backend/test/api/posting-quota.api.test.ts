import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody, PNG } from './support/fixtures.js';

const { ctx, expect } = useApi('posting-quota');

/** Hạn mức tài khoản Cá nhân, trả xu khi vượt, hết hạn / kích hoạt lại / gia hạn, chặn tin trùng (chuyên mục "other": 2 tin miễn phí, 5 xu, 60 ngày) */
test('posting quota: pay with points, expiry, reactivate, extend, duplicates', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const { expireDueListings } = await import('../../src/modules/listings/services/listing-lifecycle.service.js');
  const token = tokens.buyer;
  const wallet = async () => (await api.get('/credits/wallet', { token })).body.data;
  const decide = async (id: string, decision: 'APPROVED' | 'REJECTED') => {
    await api.post(`/listings/${id}/images`, { token, raw: PNG, contentType: 'image/png' });
    const pending = await api.get('/listings/admin/pending', { token: tokens.admin });
    const updatedAt = pending.body.data.find((item: { id: string }) => item.id === id).updatedAt;
    return api.post(`/listings/admin/${id}/decision`, { token: tokens.admin, body: { decision, updatedAt, reason: 'Ảnh không rõ sản phẩm' } });
  };

  const quota = expect('quota', await api.get('/listings/posting-quota', { token }));
  const other = quota.body.data.categories.find((item: { categoryId: string }) => item.categoryId === 'other');
  assert.deepEqual([other.limit, other.extraCredits, other.displayDays, quota.body.data.total.limit], [2, 5, 60, 5]);

  const a = expect('create free 1', await api.post('/listings', { token, body: listingBody('Đồng hồ treo tường cũ') })).body.data.id;
  expect('create free 2', await api.post('/listings', { token, body: listingBody('Quạt bàn mini') }));
  const over = expect('create over limit', await api.post('/listings', { token, body: listingBody('Máy may cổ') }));
  assert.equal(over.body.code, 'POSTING_LIMIT_REACHED');
  assert.equal(over.body.details.blockedBy, 'CATEGORY');
  const poor = expect('pay without points', await api.post('/listings', { token, body: { ...listingBody('Máy may cổ'), payWithCredits: true } }));
  assert.equal(poor.body.code, 'NOT_ENOUGH_CREDITS');

  await prisma.creditTransaction.create({ data: { userId: 'user-buyer', type: 'TOPUP', bucket: 'PAID', amount: 50, note: 'test' } });
  const paid = expect('pay with points', await api.post('/listings', { token, body: { ...listingBody('Máy may cổ'), payWithCredits: true } }));
  assert.equal(paid.status, 201);
  assert.deepEqual([(await wallet()).available, (await wallet()).held], [45, 5]);

  const duplicate = expect('duplicate of active', await api.post('/listings', { token, body: listingBody('đồng hồ TREO tường cũ!!') }));
  assert.equal(duplicate.body.code, 'DUPLICATE_LISTING');

  assert.equal((await decide(a, 'APPROVED')).status, 200);
  const approved = await api.get(`/listings/mine/${a}`, { token });
  assert.ok(approved.body.data.expiresAt, 'duyệt xong phải có hạn hiển thị');
  assert.equal((await decide(paid.body.data.id, 'REJECTED')).status, 200);
  assert.equal((await wallet()).available, 50, 'từ chối thì hoàn xu');

  await prisma.listing.update({ where: { id: a }, data: { expiresAt: new Date(Date.now() - 1000) } });
  assert.equal(await expireDueListings(), 1);
  expect('expired listing', await api.get(`/listings/mine/${a}`, { token }));
  const inactive = expect('duplicate of expired', await api.post('/listings', { token, body: listingBody('Đồng hồ treo tường cũ') }));
  assert.equal(inactive.body.code, 'DUPLICATE_INACTIVE');
  assert.equal(inactive.body.details.expired, true);

  const free = expect('reactivate free', await api.patch(`/listings/${a}/status`, { token, body: { status: 'AVAILABLE' } }));
  assert.deepEqual([free.body.data.status, free.body.data.paidCredits], ['AVAILABLE', 0]);
  assert.equal((await wallet()).available, 50);

  // Hết hạn lần nữa trong lúc chuyên mục đã đủ 2 tin miễn phí: kích hoạt lại phải trả xu
  await prisma.listing.update({ where: { id: a }, data: { expiresAt: new Date(Date.now() - 1000) } });
  await expireDueListings();
  await prisma.listing.create({ data: {
    ownerId: 'user-buyer', categoryId: 'other', title: 'Ấm siêu tốc', description: 'Mô tả đủ dài cho tin thử.', price: 100_000,
    condition: 'USED_GOOD', status: 'AVAILABLE', images: [], location: {}, publishedAt: new Date(Date.now() - 40 * 86_400_000),
  } });
  const full = expect('reactivate over limit', await api.patch(`/listings/${a}/status`, { token, body: { status: 'AVAILABLE' } }));
  assert.equal(full.body.code, 'POSTING_LIMIT_REACHED');
  const bought = expect('reactivate with points', await api.patch(`/listings/${a}/status`, { token, body: { status: 'AVAILABLE', payWithCredits: true } }));
  assert.deepEqual([bought.body.data.status, bought.body.data.paidCredits], ['AVAILABLE', 5]);
  assert.deepEqual([(await wallet()).available, (await wallet()).held], [45, 0]);

  const before = new Date(bought.body.data.expiresAt).getTime();
  const extended = expect('extend', await api.post(`/listings/${a}/extend`, { token }));
  assert.equal(new Date(extended.body.data.expiresAt).getTime() - before, 60 * 86_400_000);
  assert.equal((await wallet()).available, 40);
  assert.equal(expect('extend too early', await api.post(`/listings/${a}/extend`, { token })).body.code, 'EXTEND_TOO_EARLY');
  expect('extend hidden', await api.post('/listings/listing-1/extend', { token }));

  const boosted = expect('boost with points', await api.post(`/listings/${a}/boost`, { token }));
  assert.deepEqual([boosted.body.data.free, boosted.body.data.credits], [false, 4]);
  assert.equal((await wallet()).available, 36);
  assert.equal(expect('boost too soon', await api.post(`/listings/${a}/boost`, { token })).body.code, 'BOOST_TOO_SOON');
  expect('boost hidden', await api.post('/listings/listing-1/boost', { token }));
  const past = new Date(Date.now() - 1000);
  await prisma.promotion.updateMany({ where: { listingId: a }, data: { endsAt: past } });
  await prisma.storePackage.update({ where: { id: 'personal' }, data: { monthlyPromotionQuota: 1, boostDiscountPercent: 50 } });
  try {
    const gift = expect('boost free', await api.post(`/listings/${a}/boost`, { token }));
    assert.deepEqual([gift.body.data.free, gift.body.data.credits, gift.body.data.freeLeft], [true, 0, 0]);
    await prisma.promotion.updateMany({ where: { listingId: a }, data: { endsAt: past } });
    const discounted = expect('boost discounted', await api.post(`/listings/${a}/boost`, { token }));
    assert.deepEqual([discounted.body.data.free, discounted.body.data.credits], [false, 2]);
    assert.equal((await wallet()).available, 34);
  } finally {
    await prisma.storePackage.update({ where: { id: 'personal' }, data: { monthlyPromotionQuota: 0, boostDiscountPercent: 0 } });
  }

  const quote = expect('feature quote', await api.get(`/listings/${a}/feature`, { token })).body.data;
  assert.deepEqual(quote.options.map((o: { credits: number }) => o.credits), [8, 23, 50]);
  assert.deepEqual([quote.available, quote.runningUntil], [34, null]);
  assert.equal(expect('feature not enough', await api.post(`/listings/${a}/feature`, { token, body: { packageId: 'featured-7' } })).body.code,
    'NOT_ENOUGH_CREDITS');
  expect('feature bump package', await api.post(`/listings/${a}/feature`, { token, body: { packageId: 'bump-1' } }));
  expect('feature bad body', await api.post(`/listings/${a}/feature`, { token, body: {} }));
  const featured = expect('feature 3 days', await api.post(`/listings/${a}/feature`, { token, body: { packageId: 'featured-3' } }));
  assert.equal(featured.body.data.credits, 23);
  assert.equal((await wallet()).available, 11);
  assert.equal(expect('feature again', await api.post(`/listings/${a}/feature`, { token, body: { packageId: 'featured-1' } })).body.code,
    'FEATURE_ALREADY_ACTIVE');
  const hot = await api.get('/listings/recommended?categoryId=other');
  assert.ok(hot.body.data.some((item: { id: string }) => item.id === a));
  const nextPage = await api.get('/listings/recommended?categoryId=other&limit=20&page=2');
  assert.deepEqual(nextPage.body.data, []);
  const otherHot = await api.get('/listings/recommended?categoryId=phones');
  assert.ok(!otherHot.body.data.some((item: { id: string }) => item.id === a));

  await prisma.promotion.updateMany({ where: { listingId: a, package: { kind: 'BUMP' } }, data: { endsAt: past } });
  const racing = await Promise.all([api.post(`/listings/${a}/boost`, { token }), api.post(`/listings/${a}/boost`, { token })]);
  assert.deepEqual(racing.map((res) => res.status).sort(), [200, 409]);
  assert.equal((await wallet()).available, 7);
  expect('quota after', await api.get('/listings/posting-quota', { token }));
});
