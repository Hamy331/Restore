import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx, expect } = useApi('commerce');

test('stores: packages and orders', async () => {
  const { api, tokens } = ctx;
  expect('store me (personal)', await api.get('/stores/me', { token: tokens.seller }));
  expect('store me as admin', await api.get('/stores/me', { token: tokens.admin }));
  expect('order invalid', await api.post('/stores/orders', { token: tokens.seller, body: { packageId: 'personal', categoryId: 'furniture' } }));
  const order = expect('order basic', await api.post('/stores/orders', { token: tokens.seller, body: { packageId: 'basic', categoryId: 'furniture' } }));
  expect('order while pending', await api.post('/stores/orders', { token: tokens.seller, body: { packageId: 'pro', categoryId: 'furniture' } }));
  expect('admin orders as user', await api.get('/stores/admin/orders', { token: tokens.seller }));
  expect('admin orders', await api.get('/stores/admin/orders', { token: tokens.admin }));
  expect('confirm order', await api.post(`/stores/admin/orders/${order.body.data.id}/confirm`, { token: tokens.admin, body: {} }));
  expect('confirm again', await api.post(`/stores/admin/orders/${order.body.data.id}/confirm`, { token: tokens.admin, body: {} }));
  expect('store me (basic)', await api.get('/stores/me', { token: tokens.seller }));

  const rejected = await api.post('/stores/orders', { token: tokens.buyer, body: { packageId: 'pro', categoryId: 'phones' } });
  expect('reject order', await api.post(`/stores/admin/orders/${rejected.body.data.id}/reject`, { token: tokens.admin, body: { reason: 'Chưa nhận được thanh toán' } }));
});

test('promotions: redeem, orders, packages', async () => {
  const { api, tokens } = ctx;
  expect('redeem listing of other user', await api.post('/promotions/redeem', { token: tokens.buyer, body: { listingId: 'listing-1', packageId: 'bump-1' } }));
  expect('redeem', await api.post('/promotions/redeem', { token: tokens.seller, body: { listingId: 'listing-1', packageId: 'bump-1' } }));
  expect('redeem quota exhausted', await api.post('/promotions/redeem', { token: tokens.seller, body: { listingId: 'listing-1', packageId: 'bump-3' } }));
  expect('promotions mine', await api.get('/promotions/my', { token: tokens.seller }));

  expect('order invalid body', await api.post('/promotions/orders', { token: tokens.seller, body: {} }));
  const order = expect('order featured', await api.post('/promotions/orders', { token: tokens.seller, body: { listingId: 'listing-2', packageId: 'featured-3' } }));
  expect('order duplicate', await api.post('/promotions/orders', { token: tokens.seller, body: { listingId: 'listing-2', packageId: 'featured-1' } }));
  expect('admin promotion orders', await api.get('/promotions/admin/orders', { token: tokens.admin }));
  expect('confirm promotion order', await api.post(`/promotions/admin/orders/${order.body.data.id}/confirm`, { token: tokens.admin, body: {} }));
  const second = await api.post('/promotions/orders', { token: tokens.seller, body: { listingId: 'listing-1', packageId: 'featured-1' } });
  expect('reject promotion order', await api.post(`/promotions/admin/orders/${second.body.data.id}/reject`, { token: tokens.admin, body: { reason: 'Không nhận được thanh toán' } }));
  expect('recommended after featured', await api.get('/listings/recommended'));

  const pkg = { name: 'Gói thử', kind: 'BUMP', durationDays: 2, priority: 0, price: '15000', active: true };
  expect('create package as user', await api.post('/promotions/packages', { token: tokens.seller, body: pkg }));
  expect('create package invalid', await api.post('/promotions/packages', { token: tokens.admin, body: { ...pkg, priority: 3 } }));
  const created = expect('create package', await api.post('/promotions/packages', { token: tokens.admin, body: pkg }));
  expect('update package', await api.put(`/promotions/packages/${created.body.data.id}`, { token: tokens.admin, body: { ...pkg, name: 'Gói thử đã sửa' } }));
  expect('update package in use', await api.put('/promotions/packages/bump-1', { token: tokens.admin, body: { ...pkg, name: 'Đẩy tin 1 ngày', durationDays: 5, price: '10000' } }));
});
