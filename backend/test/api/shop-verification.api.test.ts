import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx } = useApi('shop-verification');

/** Shop đã duyệt mới xác minh được; xác minh thì lên "Shop uy tín" kèm mã chứng nhận, thu hồi thì rời; mọi lần vào nhật ký */
test('shop verification: verify approved shops, unverify, audit', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const year = new Date().getUTCFullYear();
  await prisma.shop.create({ data: { id: 'shop-new', ownerId: 'user-seller', name: 'Nội Thất Mới', categoryIds: [] } });
  await prisma.shop.create({ data: {
    id: 'shop-old', ownerId: 'user-buyer', name: 'Shop Đã Xác Minh', categoryIds: [], status: 'APPROVED',
    verificationType: 'CERTIFIED', verifiedAt: new Date(), certificateCode: `RS-${year}-00041`,
  } });
  const admin = { token: tokens.admin };
  const trustedCount = async () => (await api.get('/shops/trusted/overview')).body.data.stats.shopCount as number;
  assert.equal(await trustedCount(), 1);

  assert.equal((await api.post('/admin/shops/shop-new/verify', { token: tokens.seller, body: { type: 'CERTIFIED' } })).status, 403);
  assert.equal((await api.post('/admin/shops/shop-new/verify', { ...admin, body: { type: 'GOLD' } })).status, 400);
  assert.equal((await api.post('/admin/shops/missing/verify', { ...admin, body: { type: 'CERTIFIED' } })).body.code, 'SHOP_NOT_FOUND');
  assert.equal((await api.post('/admin/shops/shop-new/verify', { ...admin, body: { type: 'CERTIFIED' } })).body.code,
    'SHOP_NOT_APPROVED', 'shop chờ duyệt chưa xác minh được');

  const pendingShops = async () => (await api.get('/admin/dashboard', admin)).body.data.pendingShops as number;
  assert.equal(await pendingShops(), 1, 'tổng quan đếm shop chờ duyệt');
  assert.equal((await api.post('/admin/shops/shop-new/approve', admin)).status, 200);
  assert.equal(await pendingShops(), 0);
  const verify = await api.post('/admin/shops/shop-new/verify', { ...admin, body: { type: 'OFFICIAL_BRAND' } });
  assert.equal(verify.status, 200, JSON.stringify(verify.body));
  assert.equal(verify.body.data.verified, true);
  assert.equal(verify.body.data.verificationType, 'OFFICIAL_BRAND');
  assert.equal(verify.body.data.certificateCode, `RS-${year}-00042`, 'số kế tiếp trong năm');
  assert.equal((await api.post('/admin/shops/shop-new/verify', { ...admin, body: { type: 'CERTIFIED' } })).body.code, 'SHOP_ALREADY_VERIFIED');
  assert.equal(await trustedCount(), 2);
  const approved = await api.get('/admin/shops?status=APPROVED', admin);
  assert.equal(approved.body.data.items.find((shop: { id: string }) => shop.id === 'shop-new').certificateCode, `RS-${year}-00042`);

  assert.equal((await api.post('/admin/shops/shop-new/unverify', { ...admin, body: { reason: 'abc' } })).status, 400, 'lý do quá ngắn');
  const unverify = await api.post('/admin/shops/shop-new/unverify', { ...admin, body: { reason: 'Giấy phép kinh doanh hết hạn' } });
  assert.equal(unverify.status, 200, JSON.stringify(unverify.body));
  assert.deepEqual([unverify.body.data.verified, unverify.body.data.certificateCode], [false, null]);
  assert.equal((await api.post('/admin/shops/shop-new/unverify', { ...admin, body: { reason: 'Thu hồi lần hai' } })).body.code, 'SHOP_NOT_VERIFIED');
  assert.equal(await trustedCount(), 1);

  const history = await api.get('/admin/audit?targetType=Shop&targetId=shop-new', admin);
  assert.deepEqual(history.body.data.items.map((log: { action: string; reason: string }) => [log.action, log.reason]), [
    ['SHOP_UNVERIFY', 'Giấy phép kinh doanh hết hạn'],
    ['SHOP_VERIFY', 'Đã kiểm tra hồ sơ shop'],
    ['SHOP_APPROVE', 'approve'],
  ]);
});
