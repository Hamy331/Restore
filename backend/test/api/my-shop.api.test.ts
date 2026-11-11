import assert from 'node:assert/strict';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { useApi } from './support/context.js';

process.env.STORAGE_DISK_ROOT = mkdtempSync(path.join(tmpdir(), 'restore-my-shop-'));

const { ctx } = useApi('my-shop');
const DAY = 86_400_000;
const PNG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 0]);

/** Quản lý shop: mở shop (gói Cửa hàng), sửa thông tin, logo / ảnh bìa, khoá tên khi đã xác minh */
test('my shop: create with store plan, edit, images, name lock', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const token = tokens.seller;
  const upload = async (t: string) => {
    const res = await api.post('/media/images?purpose=shop', { token: t, raw: PNG, contentType: 'image/png' });
    assert.equal(res.status, 201, JSON.stringify(res.body));
    return res.body.data.imageUrl as string;
  };

  const none = await api.get('/shops/me', { token });
  assert.equal(none.status, 200, JSON.stringify(none.body));
  assert.deepEqual([none.body.data.shop, none.body.data.storePlan, none.body.data.canCreate], [null, false, false]);
  assert.equal((await api.get('/shops/me')).status, 401);

  const personal = await api.post('/shops/me', { token, body: { name: 'Nội Thất Test' } });
  assert.deepEqual([personal.status, personal.body.code], [403, 'SHOP_PLAN_REQUIRED']);
  assert.equal((await api.patch('/shops/me', { token, body: { tagline: 'x' } })).body.code, 'SHOP_REQUIRED');

  await prisma.storeSubscription.deleteMany({ where: { userId: 'user-seller' } });
  await prisma.storeSubscription.create({ data: { userId: 'user-seller', packageId: 'pro', categoryId: 'furniture', endsAt: new Date(Date.now() + 20 * DAY) } });
  const before = await api.get('/shops/me', { token });
  assert.deepEqual([before.body.data.storePlan, before.body.data.canCreate], [true, true]);

  assert.equal((await api.post('/shops/me', { token, body: { name: 'A' } })).status, 400, 'tên quá ngắn');
  const created = await api.post('/shops/me', { token, body: { name: '  Nội Thất Test ', tagline: 'Gỗ thật', address: 'Quận 1, TP.HCM' } });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const shop = created.body.data.shop;
  assert.deepEqual([shop.name, shop.tagline, shop.address, shop.verificationType, created.body.data.nameLocked], ['Nội Thất Test', 'Gỗ thật', 'Quận 1, TP.HCM', null, false]);
  assert.deepEqual(created.body.data.stats, { followerCount: 0, listingCount: created.body.data.stats.listingCount, runningPosters: 0, pendingPosters: 0 });
  assert.equal((await api.post('/shops/me', { token, body: { name: 'Shop thứ hai' } })).body.code, 'SHOP_EXISTS');

  // ảnh của người khác hoặc sai khu thì từ chối
  const other = await upload(tokens.admin);
  assert.equal((await api.patch('/shops/me', { token, body: { logoUrl: other } })).body.code, 'INVALID_IMAGE_URL');
  assert.equal((await api.patch('/shops/me', { token, body: { accentColor: 'red' } })).status, 400);
  assert.equal((await api.patch('/shops/me', { token, body: { slug: 'x' } })).status, 400, 'trường lạ');

  const logoUrl = await upload(token);
  const coverUrl = await upload(token);
  const edited = await api.patch('/shops/me', { token, body: {
    name: 'Nội Thất Gỗ Việt', logoUrl, coverUrl, accentColor: '#1428A0', description: 'Bàn ghế gỗ tự nhiên', tagline: null,
  } });
  assert.equal(edited.status, 200, JSON.stringify(edited.body));
  const after = edited.body.data.shop;
  assert.deepEqual([after.name, after.logoUrl, after.coverUrl, after.accentColor, after.description, after.tagline],
    ['Nội Thất Gỗ Việt', logoUrl, coverUrl, '#1428A0', 'Bàn ghế gỗ tự nhiên', '']);
  const cleared = await api.patch('/shops/me', { token, body: { logoUrl: null, address: '' } });
  assert.deepEqual([cleared.body.data.shop.logoUrl, cleared.body.data.shop.address, cleared.body.data.shop.coverUrl], [null, null, coverUrl]);

  // đã xác minh thì không tự đổi tên, các trường khác vẫn sửa được
  await prisma.shop.update({ where: { ownerId: 'user-seller' }, data: { verificationType: 'CERTIFIED', verifiedAt: new Date() } });
  const locked = await api.get('/shops/me', { token });
  assert.equal(locked.body.data.nameLocked, true);
  assert.equal((await api.patch('/shops/me', { token, body: { name: 'Tên mới' } })).body.code, 'SHOP_NAME_LOCKED');
  assert.equal((await api.patch('/shops/me', { token, body: { name: 'Nội Thất Gỗ Việt', tagline: 'Mới' } })).status, 200, 'gửi lại tên cũ vẫn được');
});
