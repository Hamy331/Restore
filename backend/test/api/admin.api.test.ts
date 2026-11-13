import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx, expect } = useApi('admin');

test('admin: access and overview', async () => {
  const { api, tokens } = ctx;
  expect('admin me as user', await api.get('/admin/me', { token: tokens.buyer }));
  expect('admin me as guest', await api.get('/admin/me'));
  expect('admin me', await api.get('/admin/me', { token: tokens.admin }));
  expect('dashboard', await api.get('/admin/dashboard', { token: tokens.admin }));
  expect('listings', await api.get('/admin/listings?status=AVAILABLE&q=gh%E1%BA%BF', { token: tokens.admin }));
  expect('listings invalid page', await api.get('/admin/listings?page=0', { token: tokens.admin }));
  expect('store packages', await api.get('/admin/store-packages', { token: tokens.admin }));
  expect('store orders', await api.get('/admin/store-orders?status=PENDING', { token: tokens.admin }));
  expect('promotion orders', await api.get('/admin/promotion-orders', { token: tokens.admin }));
});

test('admin: users', async () => {
  const { api, tokens } = ctx;
  const users = expect('users', await api.get('/admin/users?q=user-seller', { token: tokens.admin }));
  const seller = users.body.data.items[0];
  expect('warn user', await api.post(`/admin/users/${seller.id}/action`, { token: tokens.admin, body: { action: 'WARN', reason: 'Nhắc nhở lần đầu', updatedAt: seller.updatedAt } }));
  expect('suspend user', await api.post(`/admin/users/${seller.id}/action`, { token: tokens.admin, body: { action: 'SUSPEND', reason: 'Vi phạm nhiều lần', days: 3, updatedAt: seller.updatedAt } }));
  expect('suspended token rejected', await api.get('/stores/me', { token: tokens.seller }));
  const after = await api.get('/admin/users?q=user-seller', { token: tokens.admin });
  expect('restore user', await api.post(`/admin/users/${seller.id}/action`, { token: tokens.admin, body: { action: 'RESTORE', reason: 'Đã khắc phục vi phạm', updatedAt: after.body.data.items[0].updatedAt } }));
});

test('admin: catalog, packages, listing decisions, audit', async () => {
  const { api, tokens } = ctx;
  expect('catalog', await api.get('/admin/catalog', { token: tokens.admin }));
  expect('create category invalid id', await api.post('/admin/catalog/categories', { token: tokens.admin, body: { id: 'Bad Id', name: 'Đồ cổ', description: '', active: true } }));
  expect('create category', await api.post('/admin/catalog/categories', { token: tokens.admin, body: { id: 'antiques', name: 'Đồ cổ', description: 'Đồ sưu tầm', active: true } }));
  expect('create category duplicate', await api.post('/admin/catalog/categories', { token: tokens.admin, body: { id: 'antiques-2', name: 'Đồ cổ', description: '', active: true } }));
  expect('update category', await api.put('/admin/catalog/categories/antiques', { token: tokens.admin, body: { name: 'Đồ cổ sưu tầm', description: 'Đồ sưu tầm', active: false } }));
  expect('update condition', await api.put('/admin/catalog/conditions/FOR_PARTS', { token: tokens.admin, body: { name: 'Bán xác', active: true } }));
  expect('update store package', await api.put('/admin/store-packages/basic', { token: tokens.admin, body: { name: 'Cửa hàng Basic', monthlyPrice: '109000', dailyListingLimit: 10, activeListingLimit: 30, monthlyPromotionQuota: 2, priorityLevel: 1 } }));
  expect('update personal package invalid', await api.put('/admin/store-packages/personal', { token: tokens.admin, body: { name: 'Cá nhân', monthlyPrice: '1000', dailyListingLimit: 3, activeListingLimit: 10, monthlyPromotionQuota: 0, priorityLevel: 0 } }));

  const listing = (await api.get('/admin/listings?q=B%C3%A0n', { token: tokens.admin })).body.data.items[0];
  expect('remove listing', await api.post(`/admin/listings/${listing.id}/decision`, { token: tokens.admin, body: { action: 'REMOVE', reason: 'Vi phạm chính sách', updatedAt: listing.updatedAt } }));
  expect('remove listing stale', await api.post(`/admin/listings/${listing.id}/decision`, { token: tokens.admin, body: { action: 'REMOVE', reason: 'Vi phạm chính sách', updatedAt: listing.updatedAt } }));
  expect('audit', await api.get('/admin/audit', { token: tokens.admin }));
});

test('admin dashboard groups confirmed revenue by Vietnam date and audit filters before paging', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const decidedAt = new Date();
  decidedAt.setUTCDate(decidedAt.getUTCDate() - 1);
  decidedAt.setUTCHours(18, 30, 0, 0);
  const day = new Date(+decidedAt + 7 * 3600000).toISOString().slice(0, 10);
  const order = { userId: 'user-seller', listingId: 'listing-1', packageId: 'bump-1', decidedAt, amount: 27000 };
  await prisma.promotionOrder.createMany({ data: [
    { ...order, status: 'CONFIRMED' }, { ...order, status: 'REJECTED' },
  ] });
  const options = { token: tokens.admin };
  const result = await api.get('/admin/dashboard/insights', options);
  assert.equal(result.status, 200);
  const bucket = result.body.data.daily.find((row: { day: string; packageId: string }) =>
    row.day === day && row.packageId === order.packageId);
  assert.equal(bucket?.orders, 1);
  assert.equal(Number(bucket.amount), order.amount);
  assert.equal((await api.get('/admin/dashboard/insights', { token: tokens.buyer })).status, 403);
  await prisma.adminAudit.createMany({ data: [
    { actorId:'user-admin', action:'CREATE',targetType:'POST',targetId:'qa-post',reason:'Kiểm tra bộ lọc' },
    { actorId:'user-admin', action:'CREATE',targetType:'CATEGORY',targetId:'qa-category',reason:'Kiểm tra bộ lọc' },
  ] });
  const filtered = await api.get('/admin/audit?targetType=POST&action=CREATE&q=qa-', options);
  assert.equal(filtered.status, 200);
  assert.equal(filtered.body.data.total, 1);
  assert.equal(filtered.body.data.items[0].targetId, 'qa-post');
  const old = await api.get('/admin/audit?targetType=POST&before=2000-01-01T00:00:00.000Z', options);
  assert.equal(old.body.data.total, 0);
});
