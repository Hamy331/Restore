import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody, PNG } from './support/fixtures.js';

const { ctx, expect } = useApi('listings');

test('listings: public feed', async () => {
  const { api, tokens } = ctx;
  expect('feed newest', await api.get('/listings?filter=newest&page=1&limit=2'));
  expect('feed page 2', await api.get('/listings?page=2&limit=2'));
  expect('feed legacy pageSize', await api.get('/listings?pageSize=1'));
  expect('feed nearby', await api.get('/listings?filter=nearby&latitude=10.78&longitude=106.70'));
  expect('feed nearby without location', await api.get('/listings?filter=nearby'));
  expect('feed exchange', await api.get('/listings?filter=exchange'));
  expect('feed search', await api.get('/listings?q=gh%E1%BA%BF&categoryId=furniture&minPrice=1000&maxPrice=2000000'));
  expect('feed invalid limit', await api.get('/listings?limit=500'));
  expect('feed as buyer', await api.get('/listings', { token: tokens.buyer }));
  expect('recommended', await api.get('/listings/recommended?limit=5'));
  expect('detail', await api.get('/listings/listing-1'));
  expect('detail missing', await api.get('/listings/nope'));
});

test('listings: favorites', async () => {
  const { api, tokens } = ctx;
  expect('favorite as guest', await api.post('/listings/listing-1/favorite'));
  expect('favorite as admin', await api.post('/listings/listing-1/favorite', { token: tokens.admin }));
  expect('favorite add', await api.post('/listings/listing-1/favorite', { token: tokens.buyer }));
  expect('favorite add again (PUT)', await api.put('/listings/listing-1/favorite', { token: tokens.buyer }));
  expect('favorite missing listing', await api.post('/listings/nope/favorite', { token: tokens.buyer }));
  expect('favorite check', await api.get('/listings/listing-1/favorite', { token: tokens.buyer }));
  expect('favorites list', await api.get('/listings/favorites', { token: tokens.buyer }));
  expect('feed shows favorite', await api.get('/listings?limit=10', { token: tokens.buyer }));
  expect('favorite remove', await api.delete('/listings/listing-1/favorite', { token: tokens.buyer }));
  expect('favorite check after remove', await api.get('/listings/listing-1/favorite', { token: tokens.buyer }));
});

test('listings: create, images, moderation, status', async () => {
  const { api, tokens } = ctx;
  expect('create invalid', await api.post('/listings', { token: tokens.buyer, body: { title: 'x' } }));
  expect('create as guest', await api.post('/listings', { body: listingBody() }));
  const created = expect('create', await api.post('/listings', { token: tokens.buyer, body: listingBody() }));
  const id = created.body.data.id;
  expect('mine detail', await api.get(`/listings/mine/${id}`, { token: tokens.buyer }));
  expect('mine detail of other user', await api.get(`/listings/mine/${id}`, { token: tokens.seller }));
  expect('upload invalid image', await api.post(`/listings/${id}/images`, { token: tokens.buyer, raw: 'not an image', contentType: 'image/png' }));
  const image = expect('upload image', await api.post(`/listings/${id}/images`, { token: tokens.buyer, raw: PNG, contentType: 'image/png' }));
  const second = await api.post(`/listings/${id}/images`, { token: tokens.buyer, raw: PNG, contentType: 'image/png' });
  const urls = [second.body.data.url, image.body.data.url];
  expect('reorder images', await api.put(`/listings/${id}/images`, { token: tokens.buyer, body: { images: urls } }));
  const filename = String(image.body.data.url).split('/').pop();
  const media = await api.get(`/listings/media/${filename}`, { token: tokens.buyer });
  expect('media as owner', { ...media, body: { bytes: media.status === 200 ? PNG.length : media.body } });
  expect('media as guest before approval', await api.get(`/listings/media/${filename}`));
  expect('update listing', await api.put(`/listings/${id}`, { token: tokens.buyer, body: listingBody('Tin đã sửa qua API') }));

  expect('admin pending as user', await api.get('/listings/admin/pending', { token: tokens.buyer }));
  const pending = expect('admin pending', await api.get('/listings/admin/pending', { token: tokens.admin }));
  const updatedAt = pending.body.data.find((item: { id: string }) => item.id === id).updatedAt;
  expect('decision invalid', await api.post(`/listings/admin/${id}/decision`, { token: tokens.admin, body: { decision: 'MAYBE', updatedAt } }));
  expect('decision approve', await api.post(`/listings/admin/${id}/decision`, { token: tokens.admin, body: { decision: 'APPROVED', updatedAt } }));
  expect('detail after approve', await api.get(`/listings/${id}`));

  expect('status invalid', await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'PENDING' } }));
  expect('status hide', await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'HIDDEN' } }));
  expect('status show', await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'AVAILABLE' } }));
  expect('status sold', await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'SOLD' } }));
  expect('summary', await api.get('/listings/summary', { token: tokens.buyer }));
  expect('mine', await api.get('/listings/mine', { token: tokens.buyer }));
  expect('mine filtered', await api.get('/listings/mine?status=SOLD&page=1&pageSize=5', { token: tokens.buyer }));
});

test('listings: drafts', async () => {
  const { api, tokens } = ctx;
  const draft = expect('draft create', await api.post('/listings/drafts', { token: tokens.buyer, body: { title: 'Nháp' } }));
  const id = draft.body.data.id;
  expect('draft update', await api.put(`/listings/drafts/${id}`, { token: tokens.buyer, body: listingBody('Nháp đã đủ thông tin') }));
  expect('draft publish without image', await api.post(`/listings/drafts/${id}/publish`, { token: tokens.buyer }));
  await api.post(`/listings/${id}/images`, { token: tokens.buyer, raw: PNG, contentType: 'image/png' });
  expect('draft publish', await api.post(`/listings/drafts/${id}/publish`, { token: tokens.buyer }));
  expect('draft delete after publish', await api.delete(`/listings/drafts/${id}`, { token: tokens.buyer }));
  const other = await api.post('/listings/drafts', { token: tokens.buyer, body: {} });
  expect('draft delete', await api.delete(`/listings/drafts/${other.body.data.id}`, { token: tokens.buyer }));
});
