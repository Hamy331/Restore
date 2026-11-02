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
  expect('create category invalid id', await api.post('/admin/categories', { token: tokens.admin, body: { id: 'Bad Id', name: 'Đồ cổ', description: '', active: true } }));
  expect('create category', await api.post('/admin/categories', { token: tokens.admin, body: { id: 'antiques', name: 'Đồ cổ', description: 'Đồ sưu tầm', active: true } }));
  expect('create category duplicate', await api.post('/admin/categories', { token: tokens.admin, body: { id: 'antiques-2', name: 'Đồ cổ', description: '', active: true } }));
  expect('update category', await api.put('/admin/categories/antiques', { token: tokens.admin, body: { name: 'Đồ cổ sưu tầm', description: 'Đồ sưu tầm', active: false } }));
  expect('update condition', await api.put('/admin/conditions/FOR_PARTS', { token: tokens.admin, body: { name: 'Bán xác', active: true } }));
  expect('update store package', await api.put('/admin/store-packages/basic', { token: tokens.admin, body: { name: 'Cửa hàng Basic', monthlyPrice: '109000', dailyListingLimit: 10, activeListingLimit: 30, monthlyPromotionQuota: 2, priorityLevel: 1 } }));
  expect('update personal package invalid', await api.put('/admin/store-packages/personal', { token: tokens.admin, body: { name: 'Cá nhân', monthlyPrice: '1000', dailyListingLimit: 3, activeListingLimit: 10, monthlyPromotionQuota: 0, priorityLevel: 0 } }));

  const listing = (await api.get('/admin/listings?q=B%C3%A0n', { token: tokens.admin })).body.data.items[0];
  expect('remove listing', await api.post(`/admin/listings/${listing.id}/decision`, { token: tokens.admin, body: { action: 'REMOVE', reason: 'Vi phạm chính sách', updatedAt: listing.updatedAt } }));
  expect('remove listing stale', await api.post(`/admin/listings/${listing.id}/decision`, { token: tokens.admin, body: { action: 'REMOVE', reason: 'Vi phạm chính sách', updatedAt: listing.updatedAt } }));
  expect('audit', await api.get('/admin/audit', { token: tokens.admin }));
});
