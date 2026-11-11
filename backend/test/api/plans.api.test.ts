import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx, expect } = useApi('plans');

/** Mua, nâng cấp, gia hạn gói bằng xu (Bán chuyên = basic 99 xu, Cửa hàng = pro 299 xu); hạ gói lúc còn hạn bị chặn */
test('plans: buy, upgrade with credit for unused days, renew, no downgrade', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const token = tokens.buyer;
  const wallet = async () => (await api.get('/credits/wallet', { token })).body.data.available;

  const packages = expect('packages', await api.get('/stores/packages')).body.data;
  assert.deepEqual(packages.map((item: { id: string; priceCredits: number }) => [item.id, item.priceCredits]), [['basic', 99], ['pro', 299]]);

  const quote = expect('quote new', await api.get('/stores/quote?packageId=basic', { token })).body.data;
  assert.deepEqual([quote.mode, quote.amount, quote.available], ['NEW', 99, 0]);
  assert.equal(expect('buy without points', await api.post('/stores/subscribe', { token, body: { packageId: 'basic', categoryId: 'phones' } })).body.code, 'NOT_ENOUGH_CREDITS');

  await prisma.creditTransaction.create({ data: { userId: 'user-buyer', type: 'TOPUP', bucket: 'PAID', amount: 500, note: 'test' } });
  assert.equal(expect('buy without category', await api.post('/stores/subscribe', { token, body: { packageId: 'basic' } })).body.code, 'STORE_CATEGORY_REQUIRED');
  const bought = expect('buy basic', await api.post('/stores/subscribe', { token, body: { packageId: 'basic', categoryId: 'phones' } })).body.data;
  assert.deepEqual([bought.mode, bought.amount], ['NEW', 99]);
  assert.equal(await wallet(), 401);
  assert.equal(expect('me basic', await api.get('/stores/me', { token })).body.data.package.tier, 'BASIC');

  const upgrade = expect('quote upgrade', await api.get('/stores/quote?packageId=pro', { token })).body.data;
  assert.deepEqual([upgrade.mode, upgrade.credit, upgrade.amount], ['UPGRADE', 98, 201]);
  expect('upgrade pro', await api.post('/stores/subscribe', { token, body: { packageId: 'pro' } }));
  assert.equal(await wallet(), 200);
  const me = expect('me pro', await api.get('/stores/me', { token })).body.data;
  assert.deepEqual([me.package.tier, me.category.id], ['PRO', 'phones']);

  assert.equal(expect('downgrade blocked', await api.get('/stores/quote?packageId=basic', { token })).body.code, 'STORE_DOWNGRADE_NOT_ALLOWED');
  assert.equal(expect('renew pro without points', await api.post('/stores/subscribe', { token, body: { packageId: 'pro' } })).body.code, 'NOT_ENOUGH_CREDITS');
  expect('quota as shop', await api.get('/listings/posting-quota', { token }));
});
