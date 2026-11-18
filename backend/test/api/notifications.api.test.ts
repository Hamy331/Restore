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

/** 1.9 tin hết hạn bị ẩn; 1.10 tự gia hạn thành công (báo số xu) / thiếu xu (báo nạp, một lần mỗi lần hết hạn) */
test('notifications: expired and auto-extended listings', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const lifecycle = await import('../../src/modules/listings/services/listing-lifecycle.service.js');
  const hours = (h: number) => new Date(Date.now() + h * 3_600_000);
  const latest = async (type: string) => prisma.notification.findMany({ where: { userId: 'user-seller', type }, orderBy: { createdAt: 'asc' } });
  const listing = await prisma.listing.findFirstOrThrow({ where: { ownerId: 'user-seller', status: 'AVAILABLE' }, select: { id: true } });

  // 1.9: hết hạn → ẩn và báo; chạy lại không báo thêm
  await prisma.listing.update({ where: { id: listing.id }, data: { expiresAt: hours(-1), autoExtend: false } });
  assert.equal(await lifecycle.expireDueListings(), 1);
  assert.equal(await lifecycle.expireDueListings(), 0);
  const expired = await latest('LISTING_EXPIRED');
  assert.equal(expired.length, 1);
  assert.deepEqual([expired[0].link, (expired[0].data as { listingId: string }).listingId], ['/account', listing.id]);
  expect('list after expired', await api.get('/notifications?group=listing&limit=1', { token: tokens.seller }));

  // 1.10: gói bật tự gia hạn; ví trống → báo thiếu xu một lần dù job chạy lại
  await prisma.storePackage.update({ where: { id: 'personal' }, data: { autoExtend: true } });
  try {
    await prisma.creditTransaction.deleteMany({ where: { userId: 'user-seller' } });
    await prisma.listing.update({ where: { id: listing.id }, data: { status: 'AVAILABLE', expiresAt: hours(12), autoExtend: true } });
    assert.equal(await lifecycle.autoExtendDueListings(), 0);
    assert.equal(await lifecycle.autoExtendDueListings(), 0);
    const failed = await latest('LISTING_AUTO_EXTEND_FAILED');
    assert.equal(failed.length, 1);
    assert.equal(failed[0].link, '/credits/topup');

    // Nạp xu → lần chạy sau gia hạn được, báo số xu đã trừ
    await prisma.creditTransaction.create({ data: { userId: 'user-seller', type: 'TOPUP', bucket: 'PAID', amount: 50, note: 'test' } });
    assert.equal(await lifecycle.autoExtendDueListings(), 1);
    const extended = await latest('LISTING_AUTO_EXTENDED');
    assert.equal(extended.length, 1);
    const data = extended[0].data as { days: number; amount: number };
    assert.equal(data.days, 30);
    assert.ok(data.amount > 0);
    assert.equal(extended[0].link, '/credits/history');
    expect('list after auto extend', await api.get('/notifications?group=listing&limit=2', { token: tokens.seller }));
  } finally {
    await prisma.storePackage.update({ where: { id: 'personal' }, data: { autoExtend: false } });
  }
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

/**
 * Mục 2 (Ví Xu, đẩy tin, gói): nạp xu thành công / thất bại / hết hạn, hoàn xu gộp vào thông báo từ chối,
 * xu tặng sắp hết hạn, đẩy tin bắt đầu / kết thúc, đơn bị từ chối, gói kích hoạt / sắp hết / đã hết, poster duyệt / từ chối.
 * Các job chạy lại nhiều lần vẫn chỉ báo một lần.
 */
test('notifications: wallet, boost, plan and poster flows', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const credits = await import('../../src/modules/credits/credit.service.js');
  const commerce = await import('../../src/modules/commerce/index.js');
  const promotions = await import('../../src/modules/commerce/services/promotion.service.js');
  const store = await import('../../src/modules/commerce/services/store.service.js');
  const posters = await import('../../src/modules/shops/poster.service.js');
  const listings = await import('../../src/modules/listings/services/listing.service.js');
  const { notifyListingModerated } = await import('../../src/modules/notifications/notification.listeners.js');
  const DAY = 86_400_000;
  const of = (userId: string, type: string) => prisma.notification.findMany({ where: { userId, type }, orderBy: { createdAt: 'asc' } });
  const data = (row: { data: unknown }) => row.data as Record<string, unknown>;
  const pack = await prisma.creditPackage.findFirstOrThrow({ where: { bonusCredits: { gt: 0 } } });
  const order = (code: string, expiresAt: Date) => prisma.creditTopupOrder.create({ data: {
    code, userId: 'user-buyer', packageId: pack.id, method: 'VIETQR', amountVnd: pack.priceVnd,
    credits: pack.credits, bonusCredits: pack.bonusCredits, expiresAt } });

  // 2.1 nạp thành công: báo một lần dù cổng báo lại
  const paid = await order('RSPAID01', new Date(Date.now() + 10 * 60_000));
  await credits.markPaid(paid.id, { providerTxnId: 'TXN-1', amountVnd: pack.priceVnd });
  await credits.markPaid(paid.id, { providerTxnId: 'TXN-1', amountVnd: pack.priceVnd });
  const topup = await of('user-buyer', 'CREDIT_TOPUP_SUCCESS');
  assert.equal(topup.length, 1);
  assert.deepEqual([data(topup[0]).amount, data(topup[0]).bonus, topup[0].link], [pack.credits, pack.bonusCredits, '/credits/history']);
  assert.equal(topup[0].body, `Bạn đã nhận ${pack.credits} Xu (tặng thêm ${pack.bonusCredits} Xu).`);

  // 2.2 quá 15 phút chưa trả (job) và cổng báo thất bại (giả lập); người dùng tự huỷ thì không báo
  await order('RSLATE01', new Date(Date.now() - 60_000));
  assert.equal(await credits.expireStaleTopups(), 1);
  assert.equal(await credits.expireStaleTopups(), 0);
  const failing = await order('RSFAIL01', new Date(Date.now() + 10 * 60_000));
  await credits.simulateSandbox('user-buyer', failing.id, 'fail');
  const cancelled = await order('RSCANC01', new Date(Date.now() + 10 * 60_000));
  await credits.cancelTopup('user-buyer', cancelled.id);
  const failed = await of('user-buyer', 'CREDIT_TOPUP_FAILED');
  assert.deepEqual(failed.map((row) => [data(row).topupCode, data(row).status]), [['RSLATE01', 'EXPIRED'], ['RSFAIL01', 'FAILED']]);
  assert.equal(failed[0].link, '/credits/topup');

  // 2.3 hoàn xu gộp vào thông báo từ chối tin
  await prisma.$transaction((tx) => notifyListingModerated(tx, { listingId: 'listing-2', ownerId: 'user-buyer', title: 'Ghế xoay',
    image: null, action: 'REJECT', reason: 'Ảnh mờ', edit: false, scheduled: false, refunded: 4 }));
  const rejected = await of('user-buyer', 'LISTING_REJECTED');
  assert.equal(rejected[0].body, 'Tin "Ghế xoay" không được duyệt. Lý do: Ảnh mờ Đã hoàn 4 Xu vào ví.');
  assert.equal(data(rejected[0]).refunded, 4);
  assert.equal((await of('user-buyer', 'CREDIT_REFUNDED')).length, 0, 'không gửi thông báo hoàn xu riêng');

  // 2.4 xu tặng sắp hết hạn: chỉ phần còn trong ví và hết hạn trong 7 ngày; mỗi mốc một lần
  await prisma.creditTransaction.createMany({ data: [
    { userId: 'user-buyer', type: 'BONUS', bucket: 'BONUS', amount: 10, expiresAt: new Date(Date.now() + 3 * DAY - 60_000) },
    { userId: 'user-buyer', type: 'BONUS', bucket: 'BONUS', amount: 5, expiresAt: new Date(Date.now() + 60 * DAY) },
  ] });
  assert.equal(await credits.remindBonusExpiring(), 1);
  await credits.remindBonusExpiring();
  const bonus = await of('user-buyer', 'CREDIT_BONUS_EXPIRING');
  assert.equal(bonus.length, 1);
  assert.deepEqual([data(bonus[0]).amount, data(bonus[0]).days, bonus[0].link], [10, 3, '/credits']);

  // 2.5 / 2.6 đẩy tin bằng xu: báo bắt đầu, job báo hết một lần (tin còn lượt nối tiếp thì chưa báo)
  const listing = await prisma.listing.create({ data: {
    ownerId: 'user-buyer', categoryId: 'furniture', title: 'Tủ sách gỗ', description: 'Tủ sách gỗ dùng để kiểm thử thông báo.',
    price: 500_000, condition: 'USED_GOOD', status: 'AVAILABLE', images: ['/api/v1/listings/media/tu.jpg'],
    location: { provinceCode: '79', wardCode: '26740' }, publishedAt: new Date(), expiresAt: new Date(Date.now() + 30 * DAY) } });
  await prisma.creditTransaction.create({ data: { userId: 'user-buyer', type: 'TOPUP', bucket: 'PAID', amount: 5000, note: 'test' } });
  await listings.boostListing('user-buyer', listing.id);
  const started = await of('user-buyer', 'BOOST_STARTED');
  assert.equal(started.length, 1);
  assert.deepEqual([data(started[0]).kind, data(started[0]).days, started[0].imageUrl, started[0].link],
    ['BUMP', 1, '/api/v1/listings/media/tu.jpg', `/listings/${listing.id}`]);
  assert.equal(await commerce.notifyEndedPromotions(), 0, 'đang chạy thì chưa báo hết');
  await prisma.promotion.updateMany({ where: { listingId: listing.id }, data: { endsAt: new Date(Date.now() - 60_000) } });
  await commerce.notifyEndedPromotions();
  await commerce.notifyEndedPromotions();
  const ended = await of('user-buyer', 'BOOST_ENDED');
  assert.equal(ended.length, 1);
  assert.deepEqual([ended[0].body, ended[0].link], ['Tin "Tủ sách gỗ" đã hết thời gian đẩy.', `/boost/${listing.id}`]);

  // 2.7 admin từ chối đơn đẩy tin
  const promoOrder = await prisma.promotionOrder.create({ data: { userId: 'user-buyer', listingId: listing.id, packageId: 'featured-3', amount: 30_000 } });
  await promotions.rejectPromotionOrder('user-admin', promoOrder.id, 'Chưa nhận được thanh toán');
  const orderRejected = await of('user-buyer', 'ORDER_REJECTED');
  assert.equal(orderRejected.length, 1);
  assert.deepEqual([data(orderRejected[0]).orderKind, data(orderRejected[0]).reason, orderRejected[0].link],
    ['PROMOTION_ORDER', 'Chưa nhận được thanh toán', '/boost']);

  // 2.8 mua gói bằng xu; 2.9 gói sắp hết hạn, đã hết hạn (mỗi mốc một lần)
  const plan = await prisma.storePackage.findFirstOrThrow({ where: { tier: { not: 'PERSONAL' } }, orderBy: { monthlyPrice: 'asc' } });
  await store.subscribeWithCredits('user-buyer', { packageId: plan.id, categoryId: 'furniture' });
  const activated = await of('user-buyer', 'STORE_PLAN_ACTIVATED');
  assert.deepEqual([activated.length, data(activated[0]).planName, data(activated[0]).mode, activated[0].link], [1, plan.name, 'NEW', '/plans']);
  await prisma.storeSubscription.update({ where: { userId: 'user-buyer' }, data: { endsAt: new Date(Date.now() + 2 * DAY - 60_000) } });
  await commerce.remindStorePlans();
  await commerce.remindStorePlans();
  const expiring = await of('user-buyer', 'STORE_PLAN_EXPIRING');
  assert.deepEqual([expiring.length, data(expiring[0]).days], [1, 2]);
  await prisma.storeSubscription.update({ where: { userId: 'user-buyer' }, data: { endsAt: new Date(Date.now() - 60_000) } });
  await commerce.remindStorePlans();
  await commerce.remindStorePlans();
  assert.equal((await of('user-buyer', 'STORE_PLAN_EXPIRED')).length, 1);

  // 2.10 poster được duyệt / bị từ chối
  const shop = await prisma.shop.create({ data: { ownerId: 'user-buyer', name: 'Shop thử thông báo' } });
  const poster = (title: string) => prisma.shopBanner.create({ data: { shopId: shop.id, title, imageUrl: '/api/v1/media/posters/p.jpg',
    startsAt: new Date(Date.now() + DAY), endsAt: new Date(Date.now() + 8 * DAY) } });
  await posters.approvePoster('user-admin', (await poster('Sale cuối tuần')).id);
  await posters.rejectPoster('user-admin', (await poster('Xả kho')).id, { reason: 'TOO_MUCH_TEXT', note: 'Bớt chữ' });
  const posterApproved = await of('user-buyer', 'SHOP_POSTER_APPROVED');
  const posterRejected = await of('user-buyer', 'SHOP_POSTER_REJECTED');
  assert.deepEqual([posterApproved.length, posterApproved[0].link], [1, '/shop-posters']);
  assert.deepEqual([posterRejected[0].body, data(posterRejected[0]).reasonCode],
    ['Poster "Xả kho" không được duyệt. Lý do: Quá nhiều chữ trên ảnh: Bớt chữ', 'TOO_MUCH_TEXT']);

  // Tất cả nằm ở nhóm Ví Xu (trừ thông báo từ chối tin)
  const wallet = await api.get('/notifications?group=wallet&limit=50', { token: tokens.buyer });
  assert.equal(wallet.body.data.length, 12);
  assert.ok(wallet.body.data.every((item: { group: string }) => item.group === 'wallet'));
});
