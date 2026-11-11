import assert from 'node:assert/strict';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { useApi } from './support/context.js';

process.env.STORAGE_DISK_ROOT = mkdtempSync(path.join(tmpdir(), 'restore-posters-'));

const { ctx } = useApi('shop-posters');
const DAY = 86_400_000;
const PNG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 0]);

/** Poster shop: chỉ gói Cửa hàng, hạn mức cùng lúc và theo tháng, admin duyệt / từ chối, dừng, khóa khi bị từ chối nhiều */
test('shop posters: quota, review, stop, cooldown, plan expiry', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  // ảnh /media đặt tên theo id người dùng dạng UUID, nên chủ shop là một tài khoản mới có id UUID
  const ownerId = '11111111-2222-4333-8444-555555555555';
  const base = await prisma.user.findUniqueOrThrow({ where: { id: 'user-seller' } });
  await prisma.user.create({ data: { id: ownerId, email: 'poster-owner@restore.test', fullName: 'Chủ shop', username: 'poster_owner', password: base.password, status: 'ACTIVE', role: 'USER' } });
  await prisma.listing.update({ where: { id: 'listing-1' }, data: { ownerId } });
  const login = await api.post('/auth/login', { body: { email: 'poster-owner@restore.test', password: 'Password@123' } });
  assert.equal(login.status, 200, JSON.stringify(login.body));
  const seller = login.body.data.accessToken as string;
  const otherId = '99999999-2222-4333-8444-555555555555';
  await prisma.user.create({ data: { id: otherId, email: 'poster-other@restore.test', fullName: 'Người khác', username: 'poster_other', password: base.password, status: 'ACTIVE', role: 'USER' } });
  const other = (await api.post('/auth/login', { body: { email: 'poster-other@restore.test', password: 'Password@123' } })).body.data.accessToken as string;
  const upload = async (token: string) => {
    const res = await api.post('/media/images?purpose=poster', { token, raw: PNG, contentType: 'image/png' });
    assert.equal(res.status, 201, JSON.stringify(res.body));
    return res.body.data.imageUrl as string;
  };
  // tài khoản seed có id không phải UUID (VD shop-samsung, user-seller) vẫn tải ảnh được
  assert.ok((await upload(tokens.seller)).startsWith('/api/v1/media/posters/user-seller_'));
  const imageUrl = await upload(seller);
  assert.ok(imageUrl.startsWith(`/api/v1/media/posters/${ownerId}_`), imageUrl);
  const body = (extra: Record<string, unknown> = {}) => ({ title: 'Sale cuối tuần', imageUrl, days: 7, ...extra });
  const send = (extra: Record<string, unknown> = {}) => api.post('/shops/me/posters', { token: seller, body: body(extra) });
  const later = (days: number) => new Date(Date.now() + days * DAY).toISOString();

  const empty = await api.get('/shops/me/posters', { token: seller });
  assert.equal(empty.status, 200, JSON.stringify(empty.body));
  assert.equal(empty.body.data.shop, null);
  assert.equal((await send()).body.code, 'SHOP_REQUIRED');

  await prisma.shop.create({ data: {
    id: 'shop-seller', ownerId, name: 'Nội Thất Test', verificationType: 'CERTIFIED', verifiedAt: new Date(), categoryIds: ['furniture'],
  } });
  const personal = await send();
  assert.deepEqual([personal.status, personal.body.code], [403, 'POSTER_PLAN_REQUIRED']);

  await prisma.storeSubscription.create({ data: { userId: ownerId, packageId: 'pro', categoryId: 'furniture', endsAt: new Date(Date.now() + 20 * DAY) } });

  assert.equal((await send({ imageUrl: await upload(other) })).body.code, 'INVALID_IMAGE_URL', 'ảnh của người khác');
  assert.equal((await send({ listingId: 'nope' })).body.code, 'POSTER_LISTING_INVALID');
  assert.equal((await send({ startsAt: later(20) })).body.code, 'POSTER_START_TOO_LATE');
  assert.equal((await send({ days: 2 })).status, 400);

  const a = await send();
  assert.equal(a.status, 201, JSON.stringify(a.body));
  assert.deepEqual([a.body.data.status, a.body.data.state, a.body.data.days, a.body.data.listing], ['PENDING', 'PENDING', 7, null]);
  const b = await send({ title: 'Ghế gỗ giảm 30%', listingId: 'listing-1' });
  assert.equal(b.body.data.listing.id, 'listing-1');
  const full = await send();
  assert.deepEqual([full.status, full.body.code, full.body.details?.activeLimit ?? full.body.activeLimit], [409, 'POSTER_SLOT_FULL', 2]);
  const c = await send({ startsAt: later(10), days: 3 });
  assert.equal(c.status, 201, 'khung giờ sau khi A, B kết thúc thì còn suất');

  const pendingBanners = await api.get('/shops/shop-seller/banners');
  assert.deepEqual(pendingBanners.body.data, [], 'chưa duyệt thì chưa hiện');

  // admin duyệt
  assert.equal((await api.get('/admin/shop-posters', { token: seller })).status, 403);
  const queue = await api.get('/admin/shop-posters', { token: tokens.admin });
  assert.equal(queue.status, 200, JSON.stringify(queue.body));
  assert.equal(queue.body.data.pendingCount, 3);
  assert.deepEqual(queue.body.data.items.map((item: { id: string }) => item.id), [a.body.data.id, b.body.data.id, c.body.data.id]);
  assert.deepEqual([queue.body.data.items[0].shop.name, queue.body.data.items[0].shop.planTier], ['Nội Thất Test', 'PRO']);

  const approved = await api.post(`/admin/shop-posters/${a.body.data.id}/approve`, { token: tokens.admin });
  assert.deepEqual([approved.status, approved.body.data.state], [200, 'RUNNING']);
  assert.equal((await api.post(`/admin/shop-posters/${a.body.data.id}/approve`, { token: tokens.admin })).body.code, 'POSTER_NOT_PENDING');
  const live = await api.get('/shops/shop-seller/banners');
  assert.deepEqual(live.body.data.map((item: { id: string }) => item.id), [a.body.data.id]);
  assert.equal(live.body.data[0].rejectNote, undefined, 'không lộ cột duyệt ra ngoài');

  // gói hết hạn thì poster tạm ẩn
  await prisma.storeSubscription.update({ where: { userId: ownerId }, data: { endsAt: new Date(Date.now() - DAY) } });
  assert.deepEqual((await api.get('/shops/shop-seller/banners')).body.data, []);
  await prisma.storeSubscription.update({ where: { userId: ownerId }, data: { endsAt: new Date(Date.now() + 20 * DAY) } });

  const reject = (id: string, payload: Record<string, unknown>) => api.post(`/admin/shop-posters/${id}/reject`, { token: tokens.admin, body: payload });
  assert.equal((await reject(b.body.data.id, { reason: 'OTHER' })).body.code, 'REJECT_NOTE_REQUIRED');
  const rejected = await reject(b.body.data.id, { reason: 'WRONG_SIZE' });
  assert.deepEqual([rejected.body.data.state, rejected.body.data.rejectReason], ['REJECTED', 'WRONG_SIZE']);

  // sửa poster bị từ chối: quay về chờ duyệt, không tính thêm lượt trong tháng
  const edited = await api.patch(`/shops/me/posters/${b.body.data.id}`, { token: seller, body: { title: 'Ghế gỗ giảm 30% (ảnh mới)', listingId: null } });
  assert.equal(edited.status, 200, JSON.stringify(edited.body));
  assert.deepEqual([edited.body.data.state, edited.body.data.rejectReason, edited.body.data.listing], ['PENDING', null, null]);

  const d = await send({ startsAt: later(10), days: 4 });
  assert.equal(d.status, 201, JSON.stringify(d.body));
  const monthly = await send({ startsAt: later(12), days: 3 });
  assert.deepEqual([monthly.status, monthly.body.code], [409, 'POSTER_MONTHLY_LIMIT']);

  const mine = await api.get('/shops/me/posters', { token: seller });
  assert.deepEqual(mine.body.data.limits, {
    activeLimit: 2, monthlyLimit: 4, usedThisMonth: 4, slotsInUse: 4, minDays: 3, maxDays: 14, maxLeadDays: 14, cooldownUntil: null,
  });
  assert.equal(mine.body.data.shop.verified, true);

  // dừng poster đang chạy
  const stopped = await api.post(`/shops/me/posters/${a.body.data.id}/stop`, { token: seller });
  assert.deepEqual([stopped.status, stopped.body.data.state], [200, 'STOPPED']);
  assert.deepEqual((await api.get('/shops/shop-seller/banners')).body.data, []);
  assert.equal((await api.post(`/shops/me/posters/${a.body.data.id}/stop`, { token: seller })).body.code, 'POSTER_NOT_STOPPABLE');
  assert.equal((await api.patch(`/shops/me/posters/${a.body.data.id}`, { token: seller, body: { title: 'x' } })).body.code, 'POSTER_NOT_EDITABLE');

  // bị từ chối 3 lần trong 30 ngày thì khóa gửi
  for (const id of [b.body.data.id, c.body.data.id]) assert.equal((await reject(id, { reason: 'TOO_MUCH_TEXT' })).status, 200);
  const locked = await api.patch(`/shops/me/posters/${c.body.data.id}`, { token: seller, body: { days: 5 } });
  assert.equal(locked.body.code, 'POSTER_COOLDOWN');
  assert.ok((await api.get('/shops/me/posters', { token: seller })).body.data.limits.cooldownUntil);
});
