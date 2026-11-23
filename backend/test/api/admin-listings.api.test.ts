import assert from 'node:assert/strict';
import { test } from 'node:test';
import { SAIGON } from './support/database.js';
import { useApi } from './support/context.js';

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
    shop: { name: 'Nội Thất Test', status: 'APPROVED', verified: true },
  });
  assert.deepEqual(queue.body.data.items[1].owner.planTier, 'PERSONAL');
  assert.equal(queue.body.data.items[1].owner.shop, null);

  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&tier=PRO', admin)), ['pending-old']);
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&tier=PERSONAL', admin)), ['pending-new']);
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&tier=BASIC', admin)), []);
  assert.equal((await api.get('/admin/listings?tier=VIP', admin)).status, 400);
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&q=user-buyer%40restore', admin)), ['pending-new'], 'tìm theo email');
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&q=k%E1%BB%87%20s%C3%A1ch', admin)), ['pending-old'], 'vẫn tìm theo tiêu đề');

  // Gói hết hạn thì người đăng tính là Cá nhân
  await prisma.storeSubscription.update({ where: { userId: 'user-seller' }, data: { endsAt: new Date(now - 1000) } });
  assert.deepEqual(ids(await api.get('/admin/listings?status=PENDING&tier=PERSONAL', admin)), ['pending-old', 'pending-new']);
});
