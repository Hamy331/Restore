import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody, PNG } from './support/fixtures.js';

const { ctx, expect } = useApi('notifications');

/** Người bán gửi một tin có ảnh, trả về id tin và updatedAt để admin ra quyết định */
async function submitListing(title: string) {
  const { api, tokens } = ctx;
  const listing = await api.post('/listings', { token: tokens.seller, body: listingBody(title) });
  const id = listing.body.data.id;
  await api.post(`/listings/${id}/images`, { token: tokens.seller, raw: PNG, contentType: 'image/png' });
  const pending = await api.get('/listings/admin/pending', { token: tokens.admin });
  const updatedAt = pending.body.data.find((item: { id: string }) => item.id === id).updatedAt;
  return { id, updatedAt };
}

test('notifications: access and validation', async () => {
  const { api, tokens } = ctx;
  expect('list as guest', await api.get('/notifications'));
  expect('list as admin', await api.get('/notifications', { token: tokens.admin }));
  expect('list empty', await api.get('/notifications', { token: tokens.seller }));
  expect('unread count empty', await api.get('/notifications/unread-count', { token: tokens.seller }));
  expect('list invalid group', await api.get('/notifications?group=nope', { token: tokens.seller }));
  expect('list invalid limit', await api.get('/notifications?limit=500', { token: tokens.seller }));
  expect('read unknown', await api.post('/notifications/nope/read', { token: tokens.seller }));
  expect('delete unknown', await api.delete('/notifications/nope', { token: tokens.seller }));
});

test('notifications: moderation decisions notify the seller', async () => {
  const { api, tokens } = ctx;
  const approved = await submitListing('Ghế xoay văn phòng thông báo');
  await api.post(`/listings/admin/${approved.id}/decision`, { token: tokens.admin, body: { decision: 'APPROVED', updatedAt: approved.updatedAt } });
  const rejected = await submitListing('Bàn gỗ thông báo');
  await api.post(`/listings/admin/${rejected.id}/decision`,
    { token: tokens.admin, body: { decision: 'REJECTED', reason: 'Ảnh không rõ sản phẩm', updatedAt: rejected.updatedAt } });

  const list = expect('list after decisions', await api.get('/notifications', { token: tokens.seller }));
  expect('buyer gets nothing', await api.get('/notifications', { token: tokens.buyer }));
  expect('unread count', await api.get('/notifications/unread-count', { token: tokens.seller }));
  expect('list group listing', await api.get('/notifications?group=listing&limit=1', { token: tokens.seller }));
  expect('list group wallet', await api.get('/notifications?group=wallet', { token: tokens.seller }));

  const [latest, older] = list.body.data as { id: string }[];
  expect('read of other user', await api.post(`/notifications/${latest.id}/read`, { token: tokens.buyer }));
  expect('read', await api.post(`/notifications/${latest.id}/read`, { token: tokens.seller }));
  expect('read again', await api.post(`/notifications/${latest.id}/read`, { token: tokens.seller }));
  expect('unread only', await api.get('/notifications?unread=true', { token: tokens.seller }));
  expect('read all', await api.post('/notifications/read-all', { token: tokens.seller }));
  expect('unread count after read all', await api.get('/notifications/unread-count', { token: tokens.seller }));
  expect('delete of other user', await api.delete(`/notifications/${older.id}`, { token: tokens.buyer }));
  expect('delete', await api.delete(`/notifications/${older.id}`, { token: tokens.seller }));
  expect('list after delete', await api.get('/notifications', { token: tokens.seller }));
});

/** 1.7: tin hẹn ngày đăng tới ngày thì job hiện tin và báo người bán, chạy lại không báo lần nữa */
test('notifications: scheduled listing published by the job', async () => {
  const { api, tokens } = ctx;
  const { publishScheduledListings } = await import('../../src/modules/listings/services/listing-lifecycle.service.js');
  const startsAt = new Date(Date.now() + 2 * 86_400_000);
  const created = await api.post('/listings', { token: tokens.seller,
    body: { ...listingBody('Kệ sách hẹn ngày đăng'), startsAt: startsAt.toISOString() } });
  const id = created.body.data.id;
  await api.post(`/listings/${id}/images`, { token: tokens.seller, raw: PNG, contentType: 'image/png' });
  const pending = await api.get('/listings/admin/pending', { token: tokens.admin });
  const updatedAt = pending.body.data.find((item: { id: string }) => item.id === id).updatedAt;
  await api.post(`/listings/admin/${id}/decision`, { token: tokens.admin, body: { decision: 'APPROVED', updatedAt } });

  const later = new Date(startsAt.getTime() + 1000);
  assert.equal(await publishScheduledListings(later), 1);
  assert.equal(await publishScheduledListings(later), 0);
  const list = expect('list after scheduled publish', await api.get('/notifications?limit=2', { token: tokens.seller }));
  const types = list.body.data.map((item: { type: string }) => item.type);
  assert.deepEqual(types, ['LISTING_PUBLISHED', 'LISTING_APPROVED']);
  assert.equal(list.body.data[0].link, `/listings/${id}`);
});

/** 1.8: tin còn dưới 2 ngày được nhắc một lần mỗi lần hết hạn; tin bật tự gia hạn không nhắc */
test('notifications: expiring listings are reminded once per expiry', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const { remindExpiringListings } = await import('../../src/modules/listings/services/listing-lifecycle.service.js');
  const now = new Date();
  const hours = (h: number) => new Date(now.getTime() + h * 3_600_000);
  const listing = await prisma.listing.findFirstOrThrow({ where: { ownerId: 'user-seller', status: 'AVAILABLE' }, select: { id: true, title: true } });
  // Các tin khác của người bán còn hạn xa để không lẫn vào
  await prisma.listing.updateMany({ where: { status: 'AVAILABLE', id: { not: listing.id } }, data: { expiresAt: hours(24 * 30) } });
  await prisma.listing.update({ where: { id: listing.id }, data: { expiresAt: hours(36), autoExtend: false } });
  const reminders = () => prisma.notification.findMany({ where: { userId: 'user-seller', type: 'LISTING_EXPIRING' }, orderBy: { createdAt: 'asc' } });

  assert.equal(await remindExpiringListings(now), 1);
  assert.equal(await remindExpiringListings(now), 1, 'job chạy lại vẫn thấy tin');
  assert.equal((await reminders()).length, 1, 'nhưng chỉ nhắc một lần');
  const list = expect('list after expiring reminder', await api.get('/notifications?group=listing&limit=1', { token: tokens.seller }));
  assert.equal(list.body.data[0].type, 'LISTING_EXPIRING');
  assert.deepEqual([list.body.data[0].data.days, list.body.data[0].data.listingId, list.body.data[0].link], [2, listing.id, '/account']);

  // Còn 10 tiếng: cùng lần hết hạn, không nhắc thêm
  assert.equal(await remindExpiringListings(hours(26)), 1);
  assert.equal((await reminders()).length, 1);

  // Gia hạn rồi lại sắp hết: nhắc lần mới
  await prisma.listing.update({ where: { id: listing.id }, data: { expiresAt: hours(24 * 10) } });
  assert.equal(await remindExpiringListings(hours(24 * 9)), 1);
  const after = await reminders();
  assert.equal(after.length, 2);
  assert.equal((after[1].data as { days: number }).days, 1);

  // Bật tự gia hạn: không nhắc; hết hạn rồi: không nhắc
  await prisma.listing.update({ where: { id: listing.id }, data: { expiresAt: hours(24 * 20), autoExtend: true } });
  assert.equal(await remindExpiringListings(hours(24 * 19)), 0);
  await prisma.listing.update({ where: { id: listing.id }, data: { autoExtend: false } });
  assert.equal(await remindExpiringListings(hours(24 * 21)), 0);
});

/** Push FCM: lưu / gỡ token thiết bị; thông báo ghi xong được gửi tới mọi máy của người nhận, token hỏng bị xoá */
test('notifications: push devices and FCM dispatch', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const push = await import('../../src/modules/notifications/notification.push.js');

  expect('device invalid platform', await api.post('/notifications/devices', { token: tokens.seller, body: { token: 'web-1', platform: 'tv' } }));
  expect('device missing token', await api.post('/notifications/devices', { token: tokens.seller, body: { platform: 'web' } }));
  expect('device as admin', await api.post('/notifications/devices', { token: tokens.admin, body: { token: 'admin-1', platform: 'web' } }));
  expect('device register', await api.post('/notifications/devices', { token: tokens.seller, body: { token: 'seller-web', platform: 'web' } }));
  await api.post('/notifications/devices', { token: tokens.seller, body: { token: 'seller-old-phone', platform: 'android' } });
  // Cùng máy, đăng nhập tài khoản khác: token chuyển chủ
  await api.post('/notifications/devices', { token: tokens.buyer, body: { token: 'shared-phone', platform: 'android' } });
  await api.post('/notifications/devices', { token: tokens.seller, body: { token: 'shared-phone', platform: 'android' } });
  const owners = await prisma.pushDevice.findMany({ orderBy: { token: 'asc' }, select: { token: true, userId: true } });
  assert.deepEqual(owners, [
    { token: 'seller-old-phone', userId: 'user-seller' },
    { token: 'seller-web', userId: 'user-seller' },
    { token: 'shared-phone', userId: 'user-seller' },
  ]);

  // Thông báo cũ (của các test trước) coi như đã gửi
  await prisma.notification.updateMany({ data: { pushedAt: new Date() } });
  const sent: { token: string; title: string; data: Record<string, string> }[] = [];
  push.setPushSenderForTest(async (token, message) => {
    sent.push({ token, title: message.title, data: message.data });
    return token === 'seller-old-phone' ? 'invalid' : 'ok';
  });
  try {
    const { notify } = await import('../../src/modules/notifications/notification.service.js');
    const listing = { id: 'listing-push-test' };
    await prisma.$transaction((tx) => notify({ userId: 'user-seller', type: 'LISTING_APPROVED', title: 'Tin đã được duyệt',
      body: 'Tin "Đèn bàn" đã hiển thị với người mua.', link: `/listings/${listing.id}` }, tx));
    assert.equal(await push.dispatchPendingPushes(), 2);
    assert.equal(await push.dispatchPendingPushes(), 0, 'đã gửi thì không gửi lại');
    assert.deepEqual(sent.map((item) => item.token).sort(), ['seller-old-phone', 'seller-web', 'shared-phone']);
    const data = sent[0].data;
    assert.equal(sent[0].title, 'Tin đã được duyệt');
    assert.deepEqual([data.kind, data.type, data.group, data.link], ['notification', 'LISTING_APPROVED', 'listing', `/listings/${listing.id}`]);
    assert.ok(Number(data.unreadCount) >= 1);
    assert.equal(await prisma.pushDevice.count({ where: { token: 'seller-old-phone' } }), 0, 'token hỏng bị xoá');

    // Thông báo quá 15 phút chưa gửi thì bỏ
    await prisma.notification.updateMany({ where: { userId: 'user-seller' }, data: { pushedAt: null, createdAt: new Date(Date.now() - 16 * 60_000) } });
    assert.equal(await push.dispatchPendingPushes(), 0);
  } finally {
    push.setPushSenderForTest(null);
  }

  expect('device unregister', await api.delete('/notifications/devices', { token: tokens.seller, body: { token: 'seller-web' } }));
  expect('device unregister other user', await api.delete('/notifications/devices', { token: tokens.buyer, body: { token: 'shared-phone' } }));
  assert.deepEqual((await prisma.pushDevice.findMany({ select: { token: true } })).map((d) => d.token), ['shared-phone']);
});
