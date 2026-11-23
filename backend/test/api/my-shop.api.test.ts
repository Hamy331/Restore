import assert from 'node:assert/strict';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { useApi } from './support/context.js';

process.env.STORAGE_DISK_ROOT = mkdtempSync(path.join(tmpdir(), 'restore-my-shop-'));

const { ctx } = useApi('my-shop');
const PNG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 0]);

/** Quản lý shop: đăng ký lên cửa hàng (hợp đồng + phí xu, không cần gói), sửa thông tin, logo / ảnh bìa, khoá tên khi đã xác minh */
test('my shop: register as a shop, edit, images, name lock', async () => {
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
  const { registration } = none.body.data;
  assert.deepEqual([none.body.data.shop, none.body.data.canCreate, registration.fee], [null, true, 199], 'gói Cá nhân vẫn đăng ký được');
  assert.equal((await api.get('/shops/me')).status, 401);
  assert.equal((await api.patch('/shops/me', { token, body: { tagline: 'x' } })).body.code, 'SHOP_REQUIRED');

  const terms = registration.termsVersion as string;
  assert.equal((await api.post('/shops/me', { token, body: { name: 'Nội Thất Test' } })).status, 400, 'chưa đồng ý hợp đồng');
  assert.equal((await api.post('/shops/me', { token, body: { name: 'Nội Thất Test', termsVersion: '2020-01' } })).status, 400, 'hợp đồng cũ');
  assert.equal((await api.post('/shops/me', { token, body: { name: 'A', termsVersion: terms } })).status, 400, 'tên quá ngắn');
  await prisma.creditTransaction.deleteMany({ where: { userId: 'user-seller' } });
  const broke = await api.post('/shops/me', { token, body: { name: 'Nội Thất Test', termsVersion: terms } });
  assert.deepEqual([broke.status, broke.body.code, broke.body.details?.required], [409, 'NOT_ENOUGH_CREDITS', 199]);
  assert.equal(await prisma.shop.count({ where: { ownerId: 'user-seller' } }), 0, 'thiếu xu thì không tạo shop');

  await prisma.creditTransaction.create({ data: { userId: 'user-seller', type: 'TOPUP', bucket: 'PAID', amount: 250, note: 'test' } });
  const created = await api.post('/shops/me', { token, body: { name: '  Nội Thất Test ', tagline: 'Gỗ thật', address: 'Quận 1, TP.HCM', termsVersion: terms } });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  const row = await prisma.shop.findUniqueOrThrow({ where: { ownerId: 'user-seller' } });
  assert.deepEqual([row.termsVersion, !!row.termsAcceptedAt, row.registrationCredits], [terms, true, 199]);
  const spent = await prisma.creditTransaction.aggregate({ where: { userId: 'user-seller' }, _sum: { amount: true } });
  assert.equal(spent._sum.amount, 51, 'trừ 199 xu');
  const shop = created.body.data.shop;
  assert.deepEqual([shop.name, shop.tagline, shop.address, shop.verificationType, created.body.data.nameLocked], ['Nội Thất Test', 'Gỗ thật', 'Quận 1, TP.HCM', null, false]);
  assert.deepEqual(created.body.data.stats, { followerCount: 0, listingCount: created.body.data.stats.listingCount, runningPosters: 0, pendingPosters: 0 });
  assert.equal((await api.post('/shops/me', { token, body: { name: 'Shop thứ hai', termsVersion: terms } })).body.code, 'SHOP_EXISTS');

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

  // Bảng tin: shop chờ duyệt chưa phải Đối tác nên chưa đăng bài được
  const me = async (t: string) => (await api.get('/users/me', { token: t })).body.data;
  assert.deepEqual([(await me(token)).shopStatus, (await me(token)).canPost], ['PENDING', false]);
  assert.equal((await api.post('/feeds', { token, body: { text: 'Hàng mới về' } })).body.code, 'FEED_POST_FORBIDDEN');

  const approved = await api.post(`/admin/shops/${id}/approve`, { token: tokens.admin });
  assert.deepEqual([approved.status, approved.body.data.status], [200, 'APPROVED']);
  assert.equal((await api.get(`/shops/${id}`, { token: tokens.buyer })).status, 200, 'đã duyệt thì công khai');
  assert.equal((await api.get('/shops/me', { token })).body.data.nameLocked, true);
  assert.equal((await api.patch('/shops/me', { token, body: { name: 'Tên khác' } })).body.code, 'SHOP_NAME_LOCKED');

  // Đối tác và admin đăng bài; người dùng thường chỉ xem, thả tim, bình luận
  assert.deepEqual([(await me(token)).isPartner, (await me(token)).canPost], [true, true]);
  const posted = await api.post('/feeds', { token, body: { text: 'Hàng mới về' } });
  assert.equal(posted.status, 201, JSON.stringify(posted.body));
  assert.equal((await api.post('/feeds', { token: tokens.admin, body: { text: 'Thông báo' } })).status, 201);
  assert.equal((await api.post('/feeds', { token: tokens.buyer, body: { text: 'Bán xe' } })).body.code, 'FEED_POST_FORBIDDEN');
  const postId = posted.body.data.id;
  assert.equal((await api.put(`/feeds/${postId}/like`, { token: tokens.buyer })).status, 200);
  assert.equal((await api.post(`/feeds/${postId}/comments`, { token: tokens.buyer, body: { text: 'Còn hàng không?' } })).status, 201);
  await prisma.feedPost.deleteMany({ where: { authorId: { in: ['user-seller', 'user-admin'] } } });

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
