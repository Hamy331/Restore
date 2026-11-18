import assert from 'node:assert/strict';
import { test } from 'node:test';
import { useApi } from './support/context.js';

const { ctx } = useApi('credit-expiry');
const DAY = 86_400_000;

/** Xu tặng hết hạn bị trừ (bút toán EXPIRE): chỉ phần chưa tiêu của lần tặng đã hết hạn, chạy lại không trừ thêm */
test('credits: expired bonus points are deducted once, oldest first', async () => {
  const { api, tokens } = ctx;
  const { prisma } = await import('../../src/lib/prisma.js');
  const { expireBonusCredits } = await import('../../src/modules/credits/credit.service.js');
  const token = tokens.buyer;
  const wallet = async () => (await api.get('/credits/wallet', { token })).body.data;
  const grant = (amount: number, expiresInDays: number) => ({ userId: 'user-buyer', type: 'BONUS' as const, bucket: 'BONUS' as const,
    amount, expiresAt: new Date(Date.now() + expiresInDays * DAY) });

  // Tặng 10 (đã hết hạn 1 ngày), tặng 8 (còn 60 ngày), nạp 20; đã tiêu 6 xu tặng (lấy từ lần tặng cũ)
  await prisma.creditTransaction.createMany({ data: [
    grant(10, -1), grant(8, 60),
    { userId: 'user-buyer', type: 'TOPUP', bucket: 'PAID', amount: 20 },
    { userId: 'user-buyer', type: 'SPEND', bucket: 'BONUS', amount: -6, note: 'Đẩy tin' },
  ] });
  assert.deepEqual([(await wallet()).bonus, (await wallet()).available], [12, 32]);

  assert.equal(await expireBonusCredits(), 4, 'lần tặng cũ còn 4 xu chưa tiêu');
  assert.equal(await expireBonusCredits(), 0, 'chạy lại không trừ thêm');
  const after = await wallet();
  assert.deepEqual([after.bonus, after.paid, after.available], [8, 20, 28]);
  const expired = await prisma.creditTransaction.findMany({ where: { userId: 'user-buyer', type: 'EXPIRE' } });
  assert.deepEqual(expired.map((row) => [row.bucket, row.amount, row.note]), [['BONUS', -4, 'Xu tặng hết hạn']]);
  const history = await api.get('/credits/transactions?type=spend', { token });
  assert.ok(history.body.data.some((row: { type: string; amount: number }) => row.type === 'EXPIRE' && row.amount === -4));

  // Đã tiêu hết lần tặng cũ thì khi hết hạn không trừ gì; xu nạp không bao giờ bị trừ ở đây
  await prisma.creditTransaction.createMany({ data: [grant(5, -2), { userId: 'user-buyer', type: 'SPEND', bucket: 'BONUS', amount: -5 }] });
  assert.equal(await expireBonusCredits(), 0);
  assert.deepEqual([(await wallet()).bonus, (await wallet()).paid], [8, 20]);

  // Bấm "Xu tặng": từng lần tặng còn xu, gần hết hạn trước
  await prisma.creditTransaction.create({ data: grant(3, 5) });
  const batches = (await api.get('/credits/bonus', { token })).body.data as { amount: number; expiresAt: string }[];
  assert.deepEqual(batches.map((b) => b.amount), [3, 8]);
  assert.ok(new Date(batches[0].expiresAt) < new Date(batches[1].expiresAt));
  assert.equal((await api.get('/credits/bonus')).status, 401);
});
