import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody, PNG } from './support/fixtures.js';

const { ctx } = useApi('listing-edit');

/** Tạo tin có một ảnh và duyệt, trả về id và URL ảnh */
async function approvedListing(title: string) {
  const { api, tokens } = ctx;
  const created = await api.post('/listings', { token: tokens.buyer, body: listingBody(title) });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const id = created.body.data.id as string;
  const image = await api.post(`/listings/${id}/images`, { token: tokens.buyer, raw: PNG, contentType: 'image/png' });
  assert.equal(image.status, 201, JSON.stringify(image.body));
  await decide(id, 'APPROVED');
  return { id, image: image.body.data.url as string };
}

/** Admin duyệt / từ chối mục [id] trong hàng chờ (tin mới hoặc bản sửa) */
async function decide(id: string, decision: 'APPROVED' | 'REJECTED', reason?: string) {
  const { api, tokens } = ctx;
  const pending = await api.get('/listings/admin/pending', { token: tokens.admin });
  const item = pending.body.data.find((row: { id: string }) => row.id === id);
  assert.ok(item, `không thấy ${id} trong hàng chờ`);
  const res = await api.post(`/listings/admin/${id}/decision`, { token: tokens.admin, body: { decision, reason, updatedAt: item.updatedAt } });
  assert.equal(res.status, 200, JSON.stringify(res.body));
  return item;
}

test('edit approved listing: old version stays live until the edit is approved', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const { id, image } = await approvedListing('Đèn bàn gỗ cũ');
  const before = await prisma.listing.findUniqueOrThrow({ where: { id } });
  // Đang chạy đẩy tin + Hot sale
  await prisma.promotion.createMany({ data: [
    { userId: 'user-buyer', listingId: id, packageId: 'bump-1', startsAt: new Date(), endsAt: new Date(Date.now() + 86_400_000) },
    { userId: 'user-buyer', listingId: id, packageId: 'featured-3', source: 'PURCHASED', startsAt: new Date(), endsAt: new Date(Date.now() + 3 * 86_400_000) },
  ] });

  const moved = await api.put(`/listings/${id}`, { token: tokens.buyer, body: { ...listingBody('Đèn bàn'), categoryId: 'furniture' } });
  assert.deepEqual([moved.status, moved.body.code], [409, 'CATEGORY_LOCKED']);

  const edited = await api.put(`/listings/${id}`, { token: tokens.buyer, body: { ...listingBody('Đèn bàn gỗ sồi'), price: '200000' } });
  assert.equal(edited.status, 200, JSON.stringify(edited.body));
  assert.equal(edited.body.data.status, 'AVAILABLE');
  assert.equal(edited.body.data.title, 'Đèn bàn gỗ cũ');
  assert.deepEqual([edited.body.data.pendingEdit.status, edited.body.data.pendingEdit.title, edited.body.data.pendingEdit.price],
    ['PENDING', 'Đèn bàn gỗ sồi', '200000']);
  assert.deepEqual(edited.body.data.pendingEdit.images, [image]);

  // Đổi ảnh: áp vào bản sửa, tin vẫn ảnh cũ
  const added = await api.post(`/listings/${id}/images`, { token: tokens.buyer, raw: PNG, contentType: 'image/png' });
  assert.equal(added.status, 201, JSON.stringify(added.body));
  const newImage = added.body.data.url as string;
  const reordered = await api.put(`/listings/${id}/images`, { token: tokens.buyer, body: { images: [newImage] } });
  assert.equal(reordered.status, 200, JSON.stringify(reordered.body));
  const filename = (url: string) => url.split('/').pop();
  assert.equal((await api.get(`/listings/media/${filename(image)}`)).status, 200, 'ảnh cũ vẫn hiện công khai');
  assert.equal((await api.get(`/listings/media/${filename(newImage)}`)).status, 404, 'ảnh mới chưa duyệt không công khai');
  assert.equal((await api.get(`/listings/media/${filename(newImage)}`, { token: tokens.buyer })).status, 200);

  // Người mua vẫn thấy bản cũ
  const publicDetail = await api.get(`/listings/${id}`);
  assert.deepEqual([publicDetail.status, publicDetail.body.data.title, publicDetail.body.data.pendingEdit], [200, 'Đèn bàn gỗ cũ', undefined]);
  const feed = await api.get('/listings?limit=50');
  assert.ok(feed.body.data.some((row: { id: string }) => row.id === id), 'tin vẫn ở feed');

  const adminList = await api.get('/admin/listings?q=%C4%90%C3%A8n%20b%C3%A0n', { token: tokens.admin });
  const adminRow = adminList.body.data.items.find((row: { id: string }) => row.id === id);
  assert.deepEqual([adminRow.title, adminRow.pendingEdit.status, adminRow.pendingEdit.title], ['Đèn bàn gỗ cũ', 'PENDING', 'Đèn bàn gỗ sồi']);

  const queued = await decide(id, 'APPROVED');
  assert.deepEqual([queued.edit, queued.title, queued.current.title], [true, 'Đèn bàn gỗ sồi', 'Đèn bàn gỗ cũ']);

  const after = await prisma.listing.findUniqueOrThrow({ where: { id }, include: { revision: true, promotions: true } });
  assert.deepEqual([after.status, after.title, after.price.toString(), after.images], ['AVAILABLE', 'Đèn bàn gỗ sồi', '200000', [newImage]]);
  assert.equal(after.revision, null);
  assert.deepEqual([after.expiresAt, after.publishedAt, after.paidCredits], [before.expiresAt, before.publishedAt, before.paidCredits]);
  assert.equal(after.promotions.length, 2, 'đẩy tin, Hot sale giữ nguyên');
  assert.equal((await api.get(`/listings/media/${filename(image)}`, { token: tokens.buyer })).status, 404, 'ảnh cũ đã thay thì xóa');
  await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'SOLD' } });
});

test('rejected edit keeps the old version; owner can discard it', async () => {
  const { api, tokens } = ctx;
  const { id } = await approvedListing('Quạt đứng Senko');
  const edited = await api.put(`/listings/${id}`, { token: tokens.buyer, body: listingBody('Quạt đứng Senko gần như mới') });
  assert.equal(edited.status, 200, JSON.stringify(edited.body));
  const stale = await api.post(`/listings/admin/${id}/decision`, { token: tokens.admin,
    body: { decision: 'REJECTED', reason: 'Ảnh không khớp', updatedAt: new Date(0).toISOString() } });
  assert.equal(stale.status, 409);

  await decide(id, 'REJECTED', 'Tiêu đề phóng đại');
  const mine = await api.get(`/listings/mine/${id}`, { token: tokens.buyer });
  assert.deepEqual([mine.body.data.status, mine.body.data.title, mine.body.data.reviewReason], ['AVAILABLE', 'Quạt đứng Senko', null]);
  assert.deepEqual([mine.body.data.pendingEdit.status, mine.body.data.pendingEdit.reviewReason], ['REJECTED', 'Tiêu đề phóng đại']);
  const queue = await api.get('/listings/admin/pending', { token: tokens.admin });
  assert.ok(!queue.body.data.some((row: { id: string }) => row.id === id), 'bản sửa bị từ chối không còn trong hàng chờ');

  // Sửa lại thì chờ duyệt lần nữa
  const again = await api.put(`/listings/${id}`, { token: tokens.buyer, body: listingBody('Quạt đứng Senko 2024') });
  assert.deepEqual([again.body.data.pendingEdit.status, again.body.data.pendingEdit.reviewReason], ['PENDING', null]);

  const discarded = await api.delete(`/listings/${id}/edit`, { token: tokens.buyer });
  assert.equal(discarded.status, 200, JSON.stringify(discarded.body));
  assert.equal(discarded.body.data.pendingEdit, undefined);
  assert.equal((await api.delete(`/listings/${id}/edit`, { token: tokens.buyer })).body.code, 'EDIT_NOT_FOUND');
  await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'SOLD' } });
});

test('editing still needs edit content first; hidden listings stay hidden; sold drops the edit', async () => {
  const { api, tokens } = ctx;
  const { id } = await approvedListing('Bàn học trẻ em');
  const early = await api.post(`/listings/${id}/images`, { token: tokens.buyer, raw: PNG, contentType: 'image/png' });
  assert.deepEqual([early.status, early.body.code], [409, 'EDIT_NOT_STARTED']);

  await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'HIDDEN' } });
  await api.put(`/listings/${id}`, { token: tokens.buyer, body: listingBody('Bàn học trẻ em chống gù') });
  await decide(id, 'APPROVED');
  const hidden = await api.get(`/listings/mine/${id}`, { token: tokens.buyer });
  assert.deepEqual([hidden.body.data.status, hidden.body.data.title], ['HIDDEN', 'Bàn học trẻ em chống gù']);

  await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'AVAILABLE' } });
  await api.put(`/listings/${id}`, { token: tokens.buyer, body: listingBody('Bàn học trẻ em chống gù có đèn') });
  const sold = await api.patch(`/listings/${id}/status`, { token: tokens.buyer, body: { status: 'SOLD' } });
  assert.deepEqual([sold.status, sold.body.data.pendingEdit], [200, undefined]);
});

test('pending (not yet approved) listing is still edited in place', async () => {
  const { api, tokens } = ctx;
  const created = await api.post('/listings', { token: tokens.seller, body: listingBody('Ấm siêu tốc Philips') });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const id = created.body.data.id;
  const edited = await api.put(`/listings/${id}`, { token: tokens.seller, body: listingBody('Ấm siêu tốc Philips 1.7L') });
  assert.deepEqual([edited.status, edited.body.data.status, edited.body.data.title, edited.body.data.pendingEdit],
    [200, 'PENDING', 'Ấm siêu tốc Philips 1.7L', undefined]);
});
