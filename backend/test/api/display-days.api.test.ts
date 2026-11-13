import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';
import { listingBody, PNG } from './support/fixtures.js';

const { ctx } = useApi('display-days');
const DAY = 86_400_000;

/** Chọn số ngày hiển thị và ngày hẹn bắt đầu khi đăng; ngày thêm trả xu (giữ khi gửi, trừ khi duyệt); tự gia hạn gói Cửa hàng */
test('display days: choose days and start, pay for extra days, scheduled start, auto-extend', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const { autoExtendDueListings, publishScheduledListings } = await import('../../src/modules/listings/services/listing-lifecycle.service.js');
  const token = tokens.buyer;
  const wallet = async () => (await api.get('/credits/wallet', { token })).body.data;
  const approve = async (id: string) => {
    await api.post(`/listings/${id}/images`, { token, raw: PNG, contentType: 'image/png' });
    const pending = await api.get('/listings/admin/pending', { token: tokens.admin });
    const updatedAt = pending.body.data.find((item: { id: string }) => item.id === id).updatedAt;
    return api.post(`/listings/admin/${id}/decision`, { token: tokens.admin, body: { decision: 'APPROVED', updatedAt } });
  };

  const quota = (await api.get('/listings/posting-quota', { token })).body.data;
  const other = quota.categories.find((item: { categoryId: string }) => item.categoryId === 'other');
  assert.deepEqual([other.displayDays, other.maxDisplayDays, other.dayPackCredits, other.extendCredits], [45, 120, 4, 4]);
  assert.deepEqual(quota.display.packs.map((p: { days: number }) => p.days), [30, 60, 90]);
  assert.equal(quota.display.autoExtend, false);

  const tooMany = await api.post('/listings', { token, body: { ...listingBody('Đèn ngủ gốm'), displayDays: 121 } });
  assert.deepEqual([tooMany.status, tooMany.body.field], [400, 'displayDays']);
  const tooFar = await api.post('/listings', { token, body: { ...listingBody('Đèn ngủ gốm'), startsAt: new Date(Date.now() + 15 * DAY).toISOString() } });
  assert.deepEqual([tooFar.status, tooFar.body.field], [400, 'startsAt']);

  const poor = await api.post('/listings', { token, body: { ...listingBody('Đèn ngủ gốm'), displayDays: 75 } });
  assert.equal(poor.body.code, 'NOT_ENOUGH_CREDITS');
  await prisma.creditTransaction.create({ data: { userId: 'user-buyer', type: 'TOPUP', bucket: 'PAID', amount: 20, note: 'test' } });

  // 75 ngày = 45 miễn phí + mốc 30 ngày (4 xu), hẹn bắt đầu sau 3 ngày
  const startsAt = new Date(Date.now() + 3 * DAY);
  const created = await api.post('/listings', { token, body: { ...listingBody('Đèn ngủ gốm'), displayDays: 75, startsAt: startsAt.toISOString() } });
  assert.equal(created.status, 201, JSON.stringify(created.body));
  assert.deepEqual([created.body.data.displayDays, created.body.data.paidDays, created.body.data.paidCredits], [75, 30, 0]);
  assert.deepEqual([(await wallet()).available, (await wallet()).held], [16, 4]);

  assert.equal((await approve(created.body.data.id)).status, 200);
  const waiting = (await api.get(`/listings/mine/${created.body.data.id}`, { token })).body.data;
  assert.equal(waiting.status, 'HIDDEN', 'chưa tới ngày hẹn thì chờ');
  assert.equal(new Date(waiting.expiresAt).getTime(), startsAt.getTime() + 75 * DAY);
  assert.deepEqual([(await wallet()).available, (await wallet()).held], [16, 0]);

  assert.equal(await publishScheduledListings(new Date(startsAt.getTime() + 1000)), 1);
  const shown = (await api.get(`/listings/mine/${created.body.data.id}`, { token })).body.data;
  assert.deepEqual([shown.status, shown.startsAt], ['AVAILABLE', null]);

  // Tự gia hạn: gói Cá nhân không bật được; gói Cửa hàng bật được, sắp hết hạn thì trừ mốc 30 ngày (giảm 10% rồi 30%)
  const id = created.body.data.id;
  const denied = await api.patch(`/listings/${id}/auto-extend`, { token, body: { enabled: true } });
  assert.equal(denied.body.code, 'AUTO_EXTEND_NOT_AVAILABLE');
  await prisma.storePackage.update({ where: { id: 'personal' }, data: { autoExtend: true, extendDiscountPercent: 30 } });
  try {
    const on = await api.patch(`/listings/${id}/auto-extend`, { token, body: { enabled: true } });
    assert.equal(on.body.data.autoExtend, true);
    const soon = new Date(Date.now() + 12 * 3_600_000);
    await prisma.listing.update({ where: { id }, data: { expiresAt: soon } });
    assert.equal(await autoExtendDueListings(), 1);
    const after = (await api.get(`/listings/mine/${id}`, { token })).body.data;
    assert.equal(new Date(after.expiresAt).getTime(), soon.getTime() + 30 * DAY);
    assert.equal((await wallet()).available, 13);
    assert.equal(await autoExtendDueListings(), 0, 'đã gia hạn thì không gia hạn lần nữa');
  } finally {
    await prisma.storePackage.update({ where: { id: 'personal' }, data: { autoExtend: false, extendDiscountPercent: 0 } });
  }
});
