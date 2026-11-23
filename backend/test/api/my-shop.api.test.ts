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
  // startsAt rõ ràng: mặc định của DB là giờ không múi giờ, so với giờ Node có lúc lệch
  await prisma.storeSubscription.create({ data: { userId: 'user-seller', packageId: 'pro', categoryId: 'furniture', startsAt: new Date(Date.now() - DAY), endsAt: new Date(Date.now() + 20 * DAY) } });
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

/** Duyệt cửa hàng: chờ duyệt thì chưa ai xem được, từ chối kèm lý do, sửa là gửi lại, duyệt xong mới công khai và khoá tên */
test('my shop: admin review flow', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const token = tokens.seller;
  const { id } = await prisma.shop.update({
    where: { ownerId: 'user-seller' }, data: { verificationType: null, verifiedAt: null, status: 'PENDING' }, select: { id: true },
  });

  assert.equal((await api.patch('/shops/me', { token, body: { name: 'Shop Gỗ 0901 234 567' } })).body.code, 'SHOP_NAME_NOT_ALLOWED');
  assert.equal((await api.patch('/shops/me', { token, body: { name: 'Nội thất tốt nhất' } })).body.code, 'SHOP_NAME_NOT_ALLOWED');
  const pending = await api.get('/shops/me', { token });
  assert.deepEqual([pending.body.data.review.status, pending.body.data.nameLocked], ['PENDING', false]);
  assert.equal((await api.get(`/shops/${id}`, { token: tokens.buyer })).status, 404, 'chờ duyệt thì chưa công khai');

  assert.equal((await api.get('/admin/shops', { token })).status, 403);
  const queue = await api.get('/admin/shops', { token: tokens.admin });
  assert.equal(queue.status, 200, JSON.stringify(queue.body));
  assert.ok(queue.body.data.pendingCount >= 1);
  assert.equal(queue.body.data.items.find((shop: { id: string }) => shop.id === id)?.owner.email, 'user-seller@restore.test');

  assert.equal((await api.post(`/admin/shops/${id}/reject`, { token: tokens.admin, body: {} })).status, 400, 'thiếu lý do');
  const rejected = await api.post(`/admin/shops/${id}/reject`, { token: tokens.admin, body: { note: 'Ảnh bìa có logo thương hiệu khác' } });
  assert.deepEqual([rejected.status, rejected.body.data.status], [200, 'REJECTED']);
  assert.equal((await api.post(`/admin/shops/${id}/approve`, { token: tokens.admin })).body.code, 'SHOP_NOT_PENDING');
  const mine = await api.get('/shops/me', { token });
  assert.deepEqual([mine.body.data.review.status, mine.body.data.review.rejectNote], ['REJECTED', 'Ảnh bìa có logo thương hiệu khác']);

  const resent = await api.patch('/shops/me', { token, body: { coverUrl: null } });
  assert.deepEqual([resent.body.data.review.status, resent.body.data.review.rejectNote], ['PENDING', null], 'sửa là gửi duyệt lại');

  const approved = await api.post(`/admin/shops/${id}/approve`, { token: tokens.admin });
  assert.deepEqual([approved.status, approved.body.data.status], [200, 'APPROVED']);
  assert.equal((await api.get(`/shops/${id}`, { token: tokens.buyer })).status, 200, 'đã duyệt thì công khai');
  assert.equal((await api.get('/shops/me', { token })).body.data.nameLocked, true);
  assert.equal((await api.patch('/shops/me', { token, body: { name: 'Tên khác' } })).body.code, 'SHOP_NAME_LOCKED');

  const types = (await prisma.notification.findMany({ where: { userId: 'user-seller', type: { startsWith: 'SHOP_' } } })).map((n) => n.type);
  assert.deepEqual(types.sort(), ['SHOP_APPROVED', 'SHOP_REJECTED']);
});

/** Giờ mở cửa và xác minh shop: giấy tờ ở khu riêng, từ chối kèm lý do, gửi lại, duyệt thì có nhãn và mã chứng nhận */
test('my shop: opening hours and verification', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const token = tokens.seller;
  const upload = async (purpose: string) => {
    const res = await api.post(`/media/images?purpose=${purpose}`, { token, raw: PNG, contentType: 'image/png' });
    assert.equal(res.status, 201, JSON.stringify(res.body));
    return res.body.data.imageUrl as string;
  };

  const hours = [{ day: 6, open: '09:00', close: '17:00' }, { day: 1, open: '08:00', close: '21:00' }];
  const saved = await api.patch('/shops/me', { token, body: { openingHours: hours } });
  assert.deepEqual(saved.body.data.shop.openingHours, [hours[1], hours[0]], 'xếp theo thứ');
  const { id } = saved.body.data.shop;
  assert.deepEqual((await api.get(`/shops/${id}`)).body.data.openingHours, [hours[1], hours[0]]);
  assert.equal((await api.patch('/shops/me', { token, body: { openingHours: [{ day: 1, open: '21:00', close: '08:00' }] } })).status, 400);
  assert.equal((await api.patch('/shops/me', { token, body: { openingHours: null } })).body.data.shop.openingHours, null);

  // giấy tờ: chủ ảnh và admin xem được, người khác và đường công khai thì không
  const doc = await upload('verification');
  const file = doc.replace('/api/v1', '');
  assert.equal((await api.get(file, { token })).status, 200);
  assert.equal((await api.get(file, { token: tokens.admin })).status, 200);
  assert.equal((await api.get(file, { token: tokens.buyer })).status, 404);
  assert.equal((await api.get(file)).status, 401);

  const body = { businessName: 'Hộ kinh doanh Gỗ Việt', taxCode: '0312345678', documentUrls: [doc] };
  assert.equal((await api.post('/shops/me/verification', { token, body: { ...body, documentUrls: [await upload('shop')] } })).body.code, 'INVALID_IMAGE_URL');
  assert.equal((await api.post('/shops/me/verification', { token, body: { ...body, taxCode: '123' } })).status, 400);
  const sent = await api.post('/shops/me/verification', { token, body });
  assert.equal(sent.status, 200, JSON.stringify(sent.body));
  assert.equal(sent.body.data.verification.status, 'PENDING');
  assert.equal((await api.post('/shops/me/verification', { token, body })).body.code, 'VERIFICATION_PENDING');

  assert.equal((await api.get('/admin/shop-verifications', { token })).status, 403);
  const queue = await api.get('/admin/shop-verifications', { token: tokens.admin });
  const item = queue.body.data.items.find((row: { shop: { id: string } }) => row.shop.id === id);
  assert.deepEqual([item?.taxCode, item?.documentUrls, item?.shop.owner.email], ['0312345678', [doc], 'user-seller@restore.test']);

  const rejected = await api.post(`/admin/shop-verifications/${item.id}/reject`, { token: tokens.admin, body: { note: 'Ảnh giấy phép bị mờ' } });
  assert.deepEqual([rejected.status, rejected.body.data.status], [200, 'REJECTED']);
  assert.equal((await api.post(`/admin/shop-verifications/${item.id}/approve`, { token: tokens.admin, body: {} })).body.code, 'VERIFICATION_NOT_PENDING');
  const mine = await api.get('/shops/me', { token });
  assert.deepEqual([mine.body.data.verification.status, mine.body.data.verification.rejectNote], ['REJECTED', 'Ảnh giấy phép bị mờ']);

  assert.equal((await api.post('/shops/me/verification', { token, body })).body.data.verification.status, 'PENDING', 'gửi lại');
  const approved = await api.post(`/admin/shop-verifications/${item.id}/approve`, { token: tokens.admin, body: { type: 'CERTIFIED' } });
  assert.deepEqual([approved.status, approved.body.data.status, approved.body.data.shop.verificationType], [200, 'APPROVED', 'CERTIFIED']);
  const verified = (await api.get('/shops/me', { token })).body.data.shop;
  assert.equal(verified.verificationType, 'CERTIFIED');
  assert.match(verified.certificateCode, /^RS-\d{4}-\d{5}$/);
  assert.equal((await api.post('/shops/me/verification', { token, body })).body.code, 'SHOP_ALREADY_VERIFIED');

  const types = (await prisma.notification.findMany({ where: { userId: 'user-seller', type: { startsWith: 'SHOP_VERIF' } } })).map((n) => n.type);
  assert.deepEqual(types.sort(), ['SHOP_VERIFICATION_REJECTED', 'SHOP_VERIFIED']);
});
