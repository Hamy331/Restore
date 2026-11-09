import { CreditBucket, CreditPayMethod, CreditTxnType, Prisma, TopupStatus } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import { serializableTransaction } from '../commerce/repositories/quota.repository.js';
import * as repo from './credit.repository.js';
import type { HistoryQuery, TopupInput } from './credit.validator.js';
import {
  BONUS_TTL_MS, HISTORY_FILTERS, MAX_PENDING_TOPUPS, PAID_TTL_MS, TOPUP_TTL_MS,
  sandboxEnabled, summarizeWallet, topupCode, vietQrAccount, vietQrImageUrl,
} from './credit.type.js';

/**
 * Xu ReStore (tên trong code: credit). Số dư luôn tính từ sổ cái CreditTransaction,
 * xu chỉ được cộng trong markPaid(), nơi duy nhất đổi đơn nạp sang PAID.
 */

export const listPackages = () => repo.findActivePackages();

export async function getWallet(userId: string) {
  const now = new Date();
  const [sums, next] = await Promise.all([repo.sumByBucket(userId), repo.findNextBonusExpiry(userId, now)]);
  return summarizeWallet(sums, next?.expiresAt ?? null);
}

export async function listTransactions(userId: string, { page, limit, type }: HistoryQuery) {
  const types = type ? HISTORY_FILTERS[type] : undefined;
  const [items, totalItems] = await Promise.all([
    repo.findTransactions(userId, types, (page - 1) * limit, limit),
    repo.countTransactions(userId, types),
  ]);
  return { items, page, limit, totalItems };
}

type Order = NonNullable<Awaited<ReturnType<typeof repo.findOrder>>>;

/** Đơn nạp kèm cách trả: VietQR (ảnh mã + tài khoản) hoặc cổng; sandbox = được giả lập kết quả */
function withPayment(order: Order) {
  const account = order.method === CreditPayMethod.VIETQR ? vietQrAccount() : null;
  return {
    ...order,
    payment: {
      sandbox: sandboxEnabled(),
      // Chưa nối VNPay thật: khi có khoá sandbox sẽ trả URL cổng ở đây
      payUrl: null as string | null,
      vietQr: account && {
        bankBin: account.bankBin,
        accountNo: account.accountNo,
        accountName: account.accountName,
        content: order.code,
        imageUrl: vietQrImageUrl(account, order.amountVnd, order.code),
      },
    },
  };
}

async function inTransaction<T>(work: (tx: repo.Db) => Promise<T>) {
  const result = await serializableTransaction(work);
  if (!result) throw new AppError(409, 'CREDIT_BUSY', 'Hệ thống đang bận, vui lòng thử lại.');
  return result.value;
}

/** Tạo đơn nạp PENDING (15 phút). Tối đa 3 đơn đang chờ. */
export async function createTopup(userId: string, { packageId, method }: TopupInput) {
  const now = new Date();
  const order = await inTransaction(async (tx) => {
    const pack = await repo.findActivePackage(tx, packageId);
    if (!pack) throw new AppError(404, 'CREDIT_PACKAGE_NOT_FOUND', 'Gói nạp không tồn tại hoặc đã ngừng bán.');
    await repo.expireStalePending(tx, userId, now);
    if (await repo.countPending(tx, userId) >= MAX_PENDING_TOPUPS) {
      throw new AppError(409, 'TOPUP_TOO_MANY_PENDING', 'Bạn đang có quá nhiều đơn nạp chưa thanh toán.');
    }
    return repo.createOrder(tx, {
      code: topupCode(),
      userId,
      packageId: pack.id,
      method,
      amountVnd: pack.priceVnd,
      credits: pack.credits,
      bonusCredits: pack.bonusCredits,
      expiresAt: new Date(now.getTime() + TOPUP_TTL_MS),
    });
  });
  return withPayment(order);
}

async function ownOrder(tx: repo.Db, userId: string, id: string) {
  const order = await repo.findOrder(tx, id);
  if (!order || order.userId !== userId) throw new AppError(404, 'TOPUP_NOT_FOUND', 'Không tìm thấy đơn nạp.');
  return order;
}

/** Trạng thái đơn để app hỏi lại sau khi quay về từ cổng; đơn quá hạn chuyển EXPIRED */
export async function getTopup(userId: string, id: string) {
  const now = new Date();
  const order = await inTransaction(async (tx) => {
    const order = await ownOrder(tx, userId, id);
    if (order.status === TopupStatus.PENDING && order.expiresAt <= now) {
      await repo.decidePending(tx, id, { status: TopupStatus.EXPIRED });
      return { ...order, status: TopupStatus.EXPIRED };
    }
    return order;
  });
  return withPayment(order);
}

/** Người dùng huỷ đơn chưa trả */
export async function cancelTopup(userId: string, id: string) {
  return inTransaction(async (tx) => {
    await ownOrder(tx, userId, id);
    if (!await repo.decidePending(tx, id, { status: TopupStatus.FAILED })) {
      throw new AppError(409, 'TOPUP_NOT_PENDING', 'Đơn không còn chờ thanh toán.');
    }
    return { id, status: TopupStatus.FAILED };
  });
}

/**
 * Cổng đã xác nhận nhận tiền: đổi đơn sang PAID và cộng xu (nạp + tặng) trong cùng transaction.
 * Gọi lại nhiều lần với cùng đơn hoặc cùng mã giao dịch của cổng vẫn chỉ cộng một lần.
 * Chỉ gọi từ IPN/webhook đã kiểm chữ ký, hoặc cổng thử.
 */
export async function markPaid(orderId: string, { providerTxnId, amountVnd }: { providerTxnId: string; amountVnd: number }) {
  const now = new Date();
  try {
    return await inTransaction(async (tx) => {
      const order = await repo.findOrder(tx, orderId);
      if (!order) throw new AppError(404, 'TOPUP_NOT_FOUND', 'Không tìm thấy đơn nạp.');
      if (order.status === TopupStatus.PAID) return { order, credited: false };
      if (order.amountVnd !== amountVnd) throw new AppError(409, 'TOPUP_AMOUNT_MISMATCH', 'Số tiền không khớp đơn nạp.');
      if (!await repo.decidePending(tx, orderId, { status: TopupStatus.PAID, providerTxnId, paidAt: now })) {
        throw new AppError(409, 'TOPUP_NOT_PENDING', 'Đơn không còn chờ thanh toán.');
      }
      const base = { userId: order.userId, topupOrderId: order.id };
      await repo.createTransactions(tx, [
        { ...base, type: CreditTxnType.TOPUP, bucket: CreditBucket.PAID, amount: order.credits,
          expiresAt: new Date(now.getTime() + PAID_TTL_MS) },
        ...(order.bonusCredits > 0 ? [{ ...base, type: CreditTxnType.BONUS, bucket: CreditBucket.BONUS, amount: order.bonusCredits,
          expiresAt: new Date(now.getTime() + BONUS_TTL_MS) }] : []),
      ]);
      return { order: { ...order, status: TopupStatus.PAID, providerTxnId, paidAt: now }, credited: true };
    });
  } catch (error) {
    // Mã giao dịch của cổng đã dùng cho đơn khác, hoặc đơn đã được cộng: không cộng lần nữa
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      throw new AppError(409, 'TOPUP_ALREADY_PROCESSED', 'Giao dịch đã được xử lý.');
    }
    throw error;
  }
}

/** Cổng thử: giả lập cổng trả kết quả cho đơn của chính mình. Tắt khi production hoặc PAYMENT_MODE=live. */
export async function simulateSandbox(userId: string, id: string, result: 'success' | 'fail') {
  if (!sandboxEnabled()) throw new AppError(404, 'NOT_FOUND', 'Không tìm thấy.');
  const order = await inTransaction((tx) => ownOrder(tx, userId, id));
  if (result === 'fail') return cancelTopup(userId, id);
  const { order: paid } = await markPaid(order.id, { providerTxnId: `SANDBOX-${order.code}`, amountVnd: order.amountVnd });
  return withPayment(paid);
}
