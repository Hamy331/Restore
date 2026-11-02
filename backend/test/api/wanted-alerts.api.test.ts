import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody, PNG } from './support/fixtures.js';

const { ctx, expect } = useApi('wanted-alerts');

const wanted = (keywords: string, extra: Record<string, unknown> = {}) => ({
  keywords, categoryId: null, minPrice: null, maxPrice: null, conditions: [], dealTypes: [], area: null, matchLevel: 'BALANCED', ...extra,
});

test('wanted alerts: access and validation', async () => {
  const { api, tokens } = ctx;
  expect('list as guest', await api.get('/wanted-alerts'));
  expect('list as admin', await api.get('/wanted-alerts', { token: tokens.admin }));
  expect('list empty', await api.get('/wanted-alerts', { token: tokens.buyer }));
  expect('create filler keywords', await api.post('/wanted-alerts', { token: tokens.buyer, body: wanted('cần mua') }));
  expect('create invalid price range', await api.post('/wanted-alerts', { token: tokens.buyer, body: wanted('ghế', { minPrice: 5, maxPrice: 1 }) }));
  expect('create invalid area', await api.post('/wanted-alerts', { token: tokens.buyer, body: wanted('ghế', { area: { code: 'nope', level: 'ward' } }) }));
  expect('create unknown category', await api.post('/wanted-alerts', { token: tokens.buyer, body: wanted('ghế', { categoryId: 'nope' }) }));
  expect('create unknown field', await api.post('/wanted-alerts', { token: tokens.buyer, body: { ...wanted('ghế'), sort: 'newest' } }));
});

test('wanted alerts: preview, create, match on approval, seen, delete', async () => {
  const { api, tokens } = ctx;
  expect('preview', await api.post('/wanted-alerts/preview?limit=5', { token: tokens.buyer, body: wanted('ghế xoay văn phòng') }));
  expect('preview with filters', await api.post('/wanted-alerts/preview', { token: tokens.buyer,
    body: wanted('ban go', { categoryId: 'furniture', maxPrice: 2000000, conditions: ['USED_GOOD'], area: { code: '79', level: 'province' }, matchLevel: 'BROAD' }) }));
  expect('preview own listings excluded', await api.post('/wanted-alerts/preview', { token: tokens.seller, body: wanted('ghế xoay văn phòng') }));

  const alert = expect('create', await api.post('/wanted-alerts', { token: tokens.buyer,
    body: wanted('ghế công thái học', { categoryId: 'other', area: { code: '79-SG', level: 'ward', label: 'Sài Gòn' }, dealTypes: ['buy'] }) }));
  const id = alert.body.data.id;
  expect('create strict', await api.post('/wanted-alerts', { token: tokens.buyer, body: wanted('ghế công thái học màu đỏ ergonomic', { matchLevel: 'STRICT' }) }));
  expect('seller own alert', await api.post('/wanted-alerts', { token: tokens.seller, body: wanted('ghế công thái học') }));

  // Người bán đăng tin, admin duyệt → chấm điểm
  const listing = await api.post('/listings', { token: tokens.seller, body: listingBody('Ghế công thái học Ergohuman') });
  const listingId = listing.body.data.id;
  await api.post(`/listings/${listingId}/images`, { token: tokens.seller, raw: PNG, contentType: 'image/png' });
  const pending = await api.get('/listings/admin/pending', { token: tokens.admin });
  const updatedAt = pending.body.data.find((item: { id: string }) => item.id === listingId).updatedAt;
  expect('approve listing', await api.post(`/listings/admin/${listingId}/decision`, { token: tokens.admin, body: { decision: 'APPROVED', updatedAt } }));

  expect('list after match', await api.get('/wanted-alerts', { token: tokens.buyer }));
  expect('seller alerts ignore own listing', await api.get('/wanted-alerts', { token: tokens.seller }));
  expect('detail', await api.get(`/wanted-alerts/${id}`, { token: tokens.buyer }));
  expect('detail of other user', await api.get(`/wanted-alerts/${id}`, { token: tokens.seller }));
  expect('matches', await api.get(`/wanted-alerts/${id}/matches?page=1&limit=10`, { token: tokens.buyer }));
  expect('matches invalid limit', await api.get(`/wanted-alerts/${id}/matches?limit=500`, { token: tokens.buyer }));
  expect('seen', await api.post(`/wanted-alerts/${id}/seen`, { token: tokens.buyer }));
  expect('matches after seen', await api.get(`/wanted-alerts/${id}/matches`, { token: tokens.buyer }));
  expect('detail after seen', await api.get(`/wanted-alerts/${id}`, { token: tokens.buyer }));

  await api.patch(`/listings/${listingId}/status`, { token: tokens.seller, body: { status: 'HIDDEN' } });
  expect('matches hide hidden listing', await api.get(`/wanted-alerts/${id}/matches`, { token: tokens.buyer }));

  expect('delete of other user', await api.delete(`/wanted-alerts/${id}`, { token: tokens.seller }));
  expect('delete', await api.delete(`/wanted-alerts/${id}`, { token: tokens.buyer }));
  expect('detail after delete', await api.get(`/wanted-alerts/${id}`, { token: tokens.buyer }));
  expect('seen after delete', await api.post(`/wanted-alerts/${id}/seen`, { token: tokens.buyer }));
});
