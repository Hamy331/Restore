import { CreditBucket, CreditHoldStatus, CreditTxnType } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import type { Db } from './credit.repository.js';
import { BONUS_TTL_MS, PAID_TTL_MS, summarizeWallet } from './credit.type.js';

/**
 * Giữ xu khi đăng tin vượt hạn mức. Xu bị trừ khỏi số dư ngay lúc gửi tin (bút toán SPEND),
 * admin duyệt thì tiêu hẳn (CAPTURED), từ chối thì hoàn đúng loại xu đã trừ (bút toán REFUND).
 * Mọi hàm chạy trong transaction của luồng đăng tin / kiểm duyệt.
 */

async function balance(tx: Db, userId: string) {
  const rows = await tx.creditTransaction.groupBy({ by: ['bucket'], where: { userId }, _sum: { amount: true } });
  return summarizeWallet(rows.map((row) => ({ bucket: row.bucket, amount: row._sum.amount ?? 0 })), null);
}

/** Số xu đang dùng được của người dùng (trong transaction) */
export const availableCredits = async (tx: Db, userId: string) => (await balance(tx, userId)).available;

/** Chia số xu cần trừ: xu tặng trước, xu nạp sau */
export function splitSpend(amount: number, bonus: number) {
  const bonusAmount = Math.min(Math.max(0, bonus), amount);
  return { bonusAmount, paidAmount: amount - bonusAmount };
}

/** Trừ [amount] xu cho tin [listingId]. Không đủ xu thì 409 NOT_ENOUGH_CREDITS. */
export async function holdForListing(tx: Db, { userId, listingId, amount, note }:
  { userId: string; listingId: string; amount: number; note: string }) {
  const wallet = await balance(tx, userId);
  if (wallet.available < amount) {
    throw new AppError(409, 'NOT_ENOUGH_CREDITS', `Cần ${amount} xu để đăng tin này, ví của bạn còn ${wallet.available} xu.`,
      undefined, { required: amount, available: wallet.available, missing: amount - wallet.available });
  }
  const { bonusAmount, paidAmount } = splitSpend(amount, wallet.bonus);
  const hold = await tx.creditHold.create({ data: { userId, listingId, amount, bonusAmount, paidAmount } });
  const base = { userId, holdId: hold.id, type: CreditTxnType.SPEND, note };
  await tx.creditTransaction.createMany({
    data: [
      ...(bonusAmount > 0 ? [{ ...base, bucket: CreditBucket.BONUS, amount: -bonusAmount }] : []),
      ...(paidAmount > 0 ? [{ ...base, bucket: CreditBucket.PAID, amount: -paidAmount }] : []),
    ],
  });
  return hold;
}

/**
 * Trừ hẳn [amount] xu cho dịch vụ không gắn với tin (mua / nâng cấp gói). Không đủ xu thì 409 NOT_ENOUGH_CREDITS.
 * Ghi một CreditHold đã CAPTURED để sổ cái giữ được phần xu tặng / xu nạp đã trừ.
 */
export async function spendCredits(tx: Db, { userId, amount, note }: { userId: string; amount: number; note: string }) {
  if (amount <= 0) return null;
  const wallet = await balance(tx, userId);
  if (wallet.available < amount) {
    throw new AppError(409, 'NOT_ENOUGH_CREDITS', `Cần ${amount} xu, ví của bạn còn ${wallet.available} xu.`,
      undefined, { required: amount, available: wallet.available, missing: amount - wallet.available });
  }
  const { bonusAmount, paidAmount } = splitSpend(amount, wallet.bonus);
  const hold = await tx.creditHold.create({
    data: { userId, amount, bonusAmount, paidAmount, status: CreditHoldStatus.CAPTURED },
  });
  const base = { userId, holdId: hold.id, type: CreditTxnType.SPEND, note: note.slice(0, 200) };
  await tx.creditTransaction.createMany({
    data: [
      ...(bonusAmount > 0 ? [{ ...base, bucket: CreditBucket.BONUS, amount: -bonusAmount }] : []),
      ...(paidAmount > 0 ? [{ ...base, bucket: CreditBucket.PAID, amount: -paidAmount }] : []),
    ],
  });
  return hold;
}

/** Tin được duyệt: xu đang giữ tiêu hẳn */
export const captureListingHold = (tx: Db, listingId: string) =>
  tx.creditHold.updateMany({ where: { listingId, status: CreditHoldStatus.HELD }, data: { status: CreditHoldStatus.CAPTURED } });

/** Tin bị từ chối: hoàn xu đang giữ về đúng loại. Trả về số xu đã hoàn (0 nếu không có gì giữ). */
export async function releaseListingHold(tx: Db, listingId: string, note: string, now: Date = new Date()) {
  const holds = await tx.creditHold.findMany({ where: { listingId, status: CreditHoldStatus.HELD } });
  let refunded = 0;
  for (const hold of holds) {
    const changed = await tx.creditHold.updateMany({ where: { id: hold.id, status: CreditHoldStatus.HELD }, data: { status: CreditHoldStatus.RELEASED } });
    if (!changed.count) continue;
    const base = { userId: hold.userId, holdId: hold.id, type: CreditTxnType.REFUND, note };
    await tx.creditTransaction.createMany({
      data: [
        ...(hold.bonusAmount > 0 ? [{ ...base, bucket: CreditBucket.BONUS, amount: hold.bonusAmount, expiresAt: new Date(now.getTime() + BONUS_TTL_MS) }] : []),
        ...(hold.paidAmount > 0 ? [{ ...base, bucket: CreditBucket.PAID, amount: hold.paidAmount, expiresAt: new Date(now.getTime() + PAID_TTL_MS) }] : []),
      ],
    });
    refunded += hold.amount;
  }
  return refunded;
}

/** Tổng xu đang giữ chờ duyệt tin */
export async function heldCredits(tx: Db, userId: string) {
  const sum = await tx.creditHold.aggregate({ where: { userId, status: CreditHoldStatus.HELD }, _sum: { amount: true } });
  return sum._sum.amount ?? 0;
}
