import assert from 'node:assert/strict';
import { test } from 'node:test';
import { SAIGON } from './support/database.js';
import { useApi } from './support/context.js';
import { listingBody } from './support/fixtures.js';

const { ctx } = useApi('admin-listings');

/** Hàng chờ duyệt tin: cũ trước, lọc theo gói người đăng, tìm theo người đăng, kèm gói và shop của người đăng */
test('admin listings: oldest pending first, seller plan filter and search', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const DAY = 86_400_000, now = Date.now();
  const pending = (id: string, ownerId: string, title: string, daysAgo: number) => prisma.listing.create({ data: {
    id, ownerId, categoryId: 'furniture', title, description: 'Mô tả sản phẩm dùng để kiểm thử API.', price: 500_000,
    condition: 'USED_GOOD', status: 'PENDING', images: [], location: SAIGON, updatedAt: new Date(now - daysAgo * DAY),
  } });
  await pending('pending-new', 'user-buyer', 'Tủ quần áo mới gửi', 1);
  await pending('pending-old', 'user-seller', 'Kệ sách gửi từ lâu', 3);
  await prisma.storeSubscription.create({ data: { userId: 'user-seller', packageId: 'pro', categoryId: 'furniture',
    startsAt: new Date(now - DAY), endsAt: new Date(now + 20 * DAY) } });
  await prisma.shop.create({ data: { id: 'shop-seller', ownerId: 'user-seller', name: 'Nội Thất Test', categoryIds: [],
    status: 'APPROVED', verificationType: 'CERTIFIED', verifiedAt: new Date() } });
  const admin = { token: tokens.admin };
  const ids = (res: { body: { data: { items: { id: string }[] } } }) => res.body.data.items.map((item) => item.id);

  const queue = await api.get('/admin/listings?status=PENDING', admin);
  assert.equal(queue.status, 200, JSON.stringify(queue.body));
  assert.deepEqual(ids(queue), ['pending-old', 'pending-new'], 'gửi sớm lên trước');
  assert.deepEqual(queue.body.data.items[0].owner, {
    id: 'user-seller', fullName: 'user-seller', email: 'user-seller@restore.test', planTier: 'PRO',
    shop: { name: 'Nội Thất Test', status: 'APPROVED', verified: true }, history: { rejected: 0, changesRequested: 0, removed: 0, recentStrikes: 0 },
  });
  assert.deepEqual(queue.body.data.items[1].owner.planTier, 'PERSONAL');
  assert.equal(queue.body.data.items[1].owner.shop, null);

  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&tier=PRO', admin)), ['pending-old']);
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&tier=PERSONAL', admin)), ['pending-new']);
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&tier=BASIC', admin)), []);
  assert.equal((await api.get('/admin/listings?tier=VIP', admin)).status, 400);
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&q=user-buyer%40restore', admin)), ['pending-new'], 'tìm theo email');
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&q=k%E1%BB%87%20s%C3%A1ch', admin)), ['pending-old'], 'vẫn tìm theo tiêu đề');

  // Cờ nội dung tự động: tin có số điện thoại; tin đã duyệt có bản sửa chứa link (flagged: lưu lúc gửi duyệt)
  await prisma.listing.update({ where: { id: 'pending-new' }, data: { description: 'Liên hệ 0912 345 678 để xem hàng.', flagged: true } });
  await prisma.listingRevision.create({ data: {
    listingId: 'listing-1', status: 'PENDING', submittedAt: new Date(), title: 'Bàn gỗ sồi thật', description: 'Xem thêm ở banghe.vn', flagged: true,
    price: 1_200_000, condition: 'USED_GOOD', isNegotiable: false, allowSale: true, allowExchange: false, exchangeWish: '',
    images: [], location: SAIGON,
  } });
  const flaggedQueue = await api.get('/admin/listings?status=PENDING', admin);
  assert.deepEqual(flaggedQueue.body.data.items.find((item: { id: string }) => item.id === 'pending-new').flags,
    [{ code: 'CONTACT', match: '0912 345 678' }]);
  assert.deepEqual(flaggedQueue.body.data.items.find((item: { id: string }) => item.id === 'pending-old').flags, []);
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&flagged=1', admin)), ['pending-new']);
  const edits = await api.get('/admin/listings?edit=PENDING&flagged=1', admin);
  assert.deepEqual(ids(edits), ['listing-1'], 'bản sửa chờ duyệt bị gắn cờ cũng được lọc');
  assert.deepEqual(edits.body.data.items[0].pendingEdit.flags, [{ code: 'LINK', match: 'banghe.vn' }]);
  assert.equal(edits.body.data.items[0].pendingEdit.flagged, true);
  assert.deepEqual(edits.body.data.items[0].flags, [], 'nội dung đang hiển thị không có cờ');

  // Gói hết hạn thì người đăng tính là Cá nhân
  await prisma.storeSubscription.update({ where: { userId: 'user-seller' }, data: { endsAt: new Date(now - 1000) } });
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&tier=PERSONAL', admin)), ['pending-old', 'pending-new']);
});

/** Đăng tin có SĐT: cảnh báo trước, vẫn gửi được; admin thấy số lần tin của người đăng bị từ chối / gỡ */
test('posting warns about flagged content, admin sees seller history', async () => {
  const { api, tokens } = ctx;
  const token = tokens.buyer, admin = { token: tokens.admin };
  const { prisma } = await import('../../src/lib/prisma.js');
  const body = { ...listingBody('Ghế gỗ cũ còn tốt'), description: 'Ghế còn chắc, liên hệ zalo 0987 654 321 nhé.' };

  const warned = await api.post('/listings', { token, body });
  assert.deepEqual([warned.status, warned.body.code], [409, 'CONTENT_FLAGGED']);
  assert.deepEqual(warned.body.details.flags, [{ code: 'CONTACT', match: '0987 654 321' }]);
  assert.equal((await api.post('/listings', { token, body: { ...body, acceptFlags: 'yes' } })).status, 400);
  const sent = await api.post('/listings', { token, body: { ...body, acceptFlags: true } });
  assert.equal(sent.status, 201, JSON.stringify(sent.body));
  const id = sent.body.data.id;
  const stored = async () => (await prisma.listing.findUniqueOrThrow({ where: { id } })).flagged;
  assert.equal(await stored(), true, 'lưu lại là người đăng đã được cảnh báo và vẫn gửi');
  const flaggedIds = async () => (await api.get('/admin/listings?status=PENDING&flagged=1', admin)).body.data.items.map((item: { id: string }) => item.id);
  assert.ok((await flaggedIds()).includes(id), 'bộ lọc dùng dấu đã lưu');
  assert.equal((await api.put(`/listings/${id}`, { token, body })).body.code, 'CONTENT_FLAGGED', 'sửa tin cũng cảnh báo');
  assert.equal((await api.put(`/listings/${id}`, { token, body: { ...body, description: 'Ghế còn chắc, nhắn tin trong ứng dụng.' } })).status, 200);
  assert.equal(await stored(), false, 'sửa hết nội dung bị gắn cờ thì bỏ dấu');
  assert.ok(!(await flaggedIds()).includes(id));

  const history = async () => (await api.get(`/admin/listings/${id}/seller-history`, admin)).body.data;
  assert.deepEqual(await history(), { rejected: 0, changesRequested: 0, removed: 0, recentStrikes: 0, recent: [] });
  const pending = (await api.get('/admin/listings?status=PENDING&q=Gh%E1%BA%BF%20g%E1%BB%97', admin)).body.data.items[0];
  assert.deepEqual(pending.owner.history, { rejected: 0, changesRequested: 0, removed: 0, recentStrikes: 0 });
  const rejected = await api.post(`/admin/listings/${id}/decision`, { ...admin,
    body: { action: 'REJECT', reason: 'Ghi số điện thoại trong tin', updatedAt: pending.updatedAt } });
  assert.equal(rejected.status, 200, JSON.stringify(rejected.body));

  const after = await history();
  assert.deepEqual([after.rejected, after.changesRequested, after.removed], [1, 0, 0]);
  assert.deepEqual(after.recent.map((r: { listingId: string; action: string; reason: string }) => [r.listingId, r.action, r.reason]),
    [[id, 'REJECT', 'Ghi số điện thoại trong tin']]);
  const listed = (await api.get('/admin/listings?status=REJECTED', admin)).body.data.items.find((item: { id: string }) => item.id === id);
  assert.deepEqual(listed.owner.history, { rejected: 1, changesRequested: 0, removed: 0, recentStrikes: 1 });

  // Tái phạm: từ 3 lần bị từ chối / gỡ trong 30 ngày; lần cũ hơn 30 ngày không tính
  const offenders = async () => (await api.get('/admin/listings?status=REJECTED&offender=1', admin)).body.data.items.map((item: { id: string }) => item.id);
  const strike = (daysAgo: number) => prisma.adminAudit.create({ data: { actorId: 'user-admin', action: 'REMOVE', targetType: 'LISTING',
    targetId: id, reason: 'Vi phạm', createdAt: new Date(Date.now() - daysAgo * 86_400_000) } });
  await strike(40);
  await strike(2);
  assert.deepEqual(await offenders(), [], 'mới 2 lần trong 30 ngày');
  await strike(1);
  assert.deepEqual(await offenders(), [id]);
  assert.equal((await history()).recentStrikes, 3);
  assert.equal((await api.get('/admin/listings/missing/seller-history', admin)).status, 404);
  assert.equal((await api.get(`/admin/listings/${id}/seller-history`, { token })).status, 403);
});
