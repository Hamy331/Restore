import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx } = useApi('shop-verification');

/** Admin xác minh shop mới mở (lên trang shop công khai), thu hồi thì shop ẩn lại; mọi lần đều vào nhật ký */
test('shop verification: list, verify, unverify, audit', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  await prisma.shop.create({ data: { id: 'shop-new', ownerId: 'user-seller', name: 'Nội Thất Mới', categoryIds: [] } });
  await prisma.shop.create({ data: {
    id: 'shop-old', ownerId: 'user-buyer', name: 'Shop Đã Xác Minh', categoryIds: [],
    verificationType: 'CERTIFIED', verifiedAt: new Date(), certificateCode: `RS-${new Date().getUTCFullYear()}-00041`,
  } });
  const admin = { token: tokens.admin };

  assert.equal((await api.get('/admin/shops', { token: tokens.seller })).status, 403);
  const pending = await api.get('/admin/shops', admin);
  assert.equal(pending.status, 200, JSON.stringify(pending.body));
  assert.deepEqual(pending.body.data.items.map((shop: { id: string }) => shop.id), ['shop-new']);
  assert.equal(pending.body.data.pending, 1);
  assert.deepEqual(pending.body.data.items[0].owner, { id: 'user-seller', fullName: 'user-seller', email: 'user-seller@restore.test', status: 'ACTIVE' });
  assert.deepEqual(pending.body.data.items[0].plan, { tier: 'PERSONAL', endsAt: null });
  const verified = await api.get('/admin/shops?status=VERIFIED', admin);
  assert.deepEqual(verified.body.data.items.map((shop: { id: string }) => shop.id), ['shop-old']);
  assert.equal((await api.get('/admin/shops?status=ALL&q=user-buyer%40', admin)).body.data.total, 1, 'tìm theo email chủ shop');
  assert.equal((await api.get('/admin/shops?status=nope', admin)).status, 400);

  assert.equal((await api.get('/shops/shop-new')).status, 404, 'chưa xác minh thì chưa có trang công khai');
  assert.equal((await api.post('/admin/shops/shop-new/verify', { ...admin, body: { type: 'GOLD' } })).status, 400);
  assert.equal((await api.post('/admin/shops/missing/verify', { ...admin, body: { type: 'CERTIFIED' } })).body.code, 'SHOP_NOT_FOUND');
  const verify = await api.post('/admin/shops/shop-new/verify', { ...admin, body: { type: 'OFFICIAL_BRAND' } });
  assert.equal(verify.status, 200, JSON.stringify(verify.body));
  assert.equal(verify.body.data.verificationType, 'OFFICIAL_BRAND');
  assert.equal(verify.body.data.certificateCode, `RS-${new Date().getUTCFullYear()}-00042`, 'số kế tiếp trong năm');
  assert.equal((await api.post('/admin/shops/shop-new/verify', { ...admin, body: { type: 'CERTIFIED' } })).body.code, 'SHOP_ALREADY_VERIFIED');
  assert.equal((await api.get('/shops/shop-new')).status, 200);

  assert.equal((await api.post('/admin/shops/shop-new/unverify', { ...admin, body: { reason: 'abc' } })).status, 400, 'lý do quá ngắn');
  const unverify = await api.post('/admin/shops/shop-new/unverify', { ...admin, body: { reason: 'Giấy phép kinh doanh hết hạn' } });
  assert.equal(unverify.status, 200, JSON.stringify(unverify.body));
  assert.deepEqual([unverify.body.data.verificationType, unverify.body.data.certificateCode], [null, null]);
  assert.equal((await api.post('/admin/shops/shop-new/unverify', { ...admin, body: { reason: 'Thu hồi lần hai' } })).body.code, 'SHOP_NOT_VERIFIED');
  assert.equal((await api.get('/shops/shop-new')).status, 404);

  const history = await api.get('/admin/audit?targetType=SHOP&targetId=shop-new', admin);
  assert.deepEqual(history.body.data.items.map((log: { action: string; reason: string }) => [log.action, log.reason]), [
    ['SHOP_UNVERIFY', 'Giấy phép kinh doanh hết hạn'],
    ['SHOP_VERIFY', 'Đã kiểm tra hồ sơ shop'],
  ]);
});
