import { CreditBucket, CreditPayMethod, CreditTxnType, Prisma, TopupStatus } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import { emit } from '../../common/events/domain-events.js';
import { prisma } from '../../lib/prisma.js';
import { serializableTransaction } from '../commerce/repositories/quota.repository.js';
import * as repo from './credit.repository.js';
import type { HistoryQuery, TopupInput } from './credit.validator.js';
import {
  BONUS_REMINDER_DAYS, BONUS_TTL_MS, DAY_MS, HISTORY_FILTERS, MAX_PENDING_TOPUPS, PAID_TTL_MS, TOPUP_TTL_MS,
  gatewaySkipped, sandboxEnabled, summarizeWallet, topupCode, vietQrAccount, vietQrImageUrl,
} from './credit.type.js';
import * as sepay from './credit.sepay.js';
import * as zalopay from './credit.zalopay.js';

/**
 * Xu ReStore (tên trong code: credit). Số dư luôn tính từ sổ cái CreditTransaction,
 * xu chỉ được cộng trong markPaid(), nơi duy nhất đổi đơn nạp sang PAID.
 */

export const listPackages = () => repo.findActivePackages();

export async function getWallet(userId: string) {
  const now = new Date();
  const [sums, next, held] = await Promise.all([
    repo.sumByBucket(userId), repo.findNextBonusExpiry(userId, now), repo.sumHeld(userId),
  ]);
  return summarizeWallet(sums, next?.expiresAt ?? null, held);
}

/**
 * Xu tặng còn trong ví, tách theo từng lần được tặng kèm hạn dùng (gần hết hạn trước):
 * [{ id, type: BONUS | REFUND, note, amount, grantedAt, expiresAt }].
 * Xu tặng được tiêu theo hạn gần nhất trước, nên phần còn lại nằm ở các lần tặng hạn xa nhất;
 * số còn lại của mỗi lần = phần số dư xu tặng rơi vào lần đó khi chia từ lần hạn xa nhất về.
 */
export async function getBonusBatches(userId: string) {
  const now = new Date();
  const [balance, grants] = await Promise.all([
    prisma.creditTransaction.aggregate({ where: { userId, bucket: CreditBucket.BONUS }, _sum: { amount: true } }),
    prisma.creditTransaction.findMany({
      where: { userId, bucket: CreditBucket.BONUS, amount: { gt: 0 }, OR: [{ expiresAt: null }, { expiresAt: { gt: now } }] },
      select: { id: true, type: true, note: true, amount: true, createdAt: true, expiresAt: true },
    }),
  ]);
  // Hạn xa nhất (hoặc không hết hạn) nhận số dư trước
  grants.sort((a, b) => (b.expiresAt?.getTime() ?? Infinity) - (a.expiresAt?.getTime() ?? Infinity));
  let left = Math.max(0, balance._sum.amount ?? 0);
  const batches = [];
  for (const grant of grants) {
    if (left <= 0) break;
    const amount = Math.min(grant.amount, left);
    left -= amount;
    batches.push({ id: grant.id, type: grant.type, note: grant.note, amount, grantedAt: grant.createdAt, expiresAt: grant.expiresAt });
  }
  return batches.reverse();
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
      // Trang thanh toán của cổng (ZaloPay); VietQR không có
      payUrl: order.payUrl ?? null,
      // Mở thẳng app ZaloPay (app-to-app); chỉ khi đơn còn chờ trả
      zaloPay: order.status === TopupStatus.PENDING ? zalopay.appToApp(order.payUrl) : null,
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

/** Tạo đơn nạp PENDING (15 phút). Tối đa 3 đơn đang chờ. ZaloPay: tạo luôn đơn bên cổng. */
export async function createTopup(userId: string, { packageId, method }: TopupInput) {
  const now = new Date();
  const gateway = method === CreditPayMethod.ZALOPAY && !gatewaySkipped() ? zalopay.zaloPayConfig() : null;
  // Chế độ thử chưa có khoá ZaloPay: vẫn tạo đơn (không có trang cổng) để dùng nút giả lập
  if (method === CreditPayMethod.ZALOPAY && !gateway && !sandboxEnabled()) {
    throw new AppError(503, 'PAYMENT_METHOD_UNAVAILABLE', 'Cổng ZaloPay chưa được cấu hình.', 'method');
  }
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
  if (!gateway) return withPayment(order);
  try {
    const { appTransId, orderUrl } = await zalopay.createOrder(gateway, {
      code: order.code, userId, amountVnd: order.amountVnd, expireSeconds: TOPUP_TTL_MS / 1000, now,
    });
    const linked = await inTransaction((tx) => repo.attachGateway(tx, order.id, { providerRef: appTransId, payUrl: orderUrl }));
    return withPayment(linked);
  } catch (error) {
    console.error('[credits] ZaloPay create order failed', error);
    await inTransaction((tx) => repo.decidePending(tx, order.id, { status: TopupStatus.FAILED }));
    throw new AppError(502, 'PAYMENT_GATEWAY_ERROR', 'Không tạo được đơn trên cổng thanh toán, vui lòng thử lại.');
  }
}

/**
 * Hỏi ZaloPay đơn đã trả chưa (máy chủ tự hỏi, không tin kết quả từ app).
 * Dùng khi callback không tới được, VD chạy backend ở localhost. Lỗi mạng thì bỏ qua, lần sau hỏi lại.
 */
async function syncZaloPay(order: Order) {
  const config = gatewaySkipped() ? null : zalopay.zaloPayConfig();
  if (!config || !order.providerRef || order.method !== CreditPayMethod.ZALOPAY) return;
  try {
    const result = await zalopay.queryOrder(config, order.providerRef);
    if (result.status === 'paid') {
      await markPaid(order.id, { providerTxnId: `ZLP-${result.zpTransId}`, amountVnd: result.amount });
    } else if (result.status === 'failed') {
      await closePending(order, TopupStatus.FAILED);
    }
  } catch (error) {
    console.warn('[credits] ZaloPay query failed', order.code, error instanceof Error ? error.message : error);
  }
}

async function ownOrder(tx: repo.Db, userId: string, id: string) {
  const order = await repo.findOrder(tx, id);
  if (!order || order.userId !== userId) throw new AppError(404, 'TOPUP_NOT_FOUND', 'Không tìm thấy đơn nạp.');
  return order;
}

/** Trạng thái đơn để app hỏi lại sau khi quay về từ cổng; đơn quá hạn chuyển EXPIRED */
export async function getTopup(userId: string, id: string) {
  // App hỏi mỗi 5 giây: chỉ đọc thường, không mở transaction SERIALIZABLE (pool Supabase
  // ít kết nối, mạng chậm thì transaction hết giờ và app chờ mãi). Đổi trạng thái vẫn an toàn
  // vì decidePending chỉ cập nhật khi đơn còn PENDING; cộng xu vẫn qua markPaid (có transaction).
  const current = await ownOrder(prisma, userId, id);
  // Hỏi cổng trước khi xét hết hạn: khách có thể vừa trả xong sát giờ
  if (current.status === TopupStatus.PENDING) await syncZaloPay(current);
  const order = await ownOrder(prisma, userId, id);
  if (order.status === TopupStatus.PENDING && order.expiresAt <= new Date()) {
    if (await closePending(order, TopupStatus.EXPIRED)) {
      return withPayment({ ...order, status: TopupStatus.EXPIRED });
    }
    return withPayment(await ownOrder(prisma, userId, id));
  }
  return withPayment(order);
}

/**
 * Đóng đơn còn chờ trả: cổng báo thất bại (FAILED) hoặc quá 15 phút (EXPIRED), rồi báo người nạp (2.2).
 * Đơn đã được xử lý trước đó thì không làm gì; trả về true nếu đã đóng.
 */
async function closePending(order: { id: string; userId: string; code: string }, status: 'FAILED' | 'EXPIRED') {
  if (!await repo.decidePending(prisma, order.id, { status })) return false;
  await emit('credit.topupFailed', { userId: order.userId, orderId: order.id, code: order.code, status });
  return true;
}

/** Job: đơn chờ trả đã quá hạn → EXPIRED và báo người nạp. Trả về số đơn đã đóng */
export async function expireStaleTopups(now = new Date()) {
  const due = await prisma.creditTopupOrder.findMany({
    where: { status: TopupStatus.PENDING, expiresAt: { lte: now } },
    select: { id: true, userId: true, code: true },
    orderBy: { expiresAt: 'asc' },
    take: 200,
  });
  let closed = 0;
  for (const order of due) if (await closePending(order, TopupStatus.EXPIRED)) closed++;
  return closed;
}

/**
 * Job nhắc xu tặng sắp hết hạn (2.4): người có xu tặng hết hạn trong BONUS_REMINDER_DAYS ngày tới
 * mà vẫn còn trong ví. Xu tặng được tiêu trước theo hạn gần nhất, nên phần còn lại nằm ở các lần tặng
 * hạn xa nhất; số xu sắp hết = số xu tặng còn lại trừ phần thuộc các lần tặng hết hạn sau khoảng nhắc.
 * Mỗi mốc hết hạn nhắc một lần (dedupeKey trong thông báo).
 */
export async function remindBonusExpiring(now = new Date()) {
  const windowEnd = new Date(now.getTime() + BONUS_REMINDER_DAYS * DAY_MS);
  const soon = await prisma.creditTransaction.groupBy({
    by: ['userId'],
    where: { bucket: CreditBucket.BONUS, amount: { gt: 0 }, expiresAt: { gt: now, lte: windowEnd } },
    _min: { expiresAt: true },
    _sum: { amount: true },
  });
  let reminded = 0;
  for (const row of soon) {
    const [balance, later] = await Promise.all([
      prisma.creditTransaction.aggregate({ where: { userId: row.userId, bucket: CreditBucket.BONUS }, _sum: { amount: true } }),
      prisma.creditTransaction.aggregate({
        where: { userId: row.userId, bucket: CreditBucket.BONUS, amount: { gt: 0 }, expiresAt: { gt: windowEnd } },
        _sum: { amount: true },
      }),
    ]);
    const amount = Math.min(row._sum.amount ?? 0, (balance._sum.amount ?? 0) - (later._sum.amount ?? 0));
    const expiresAt = row._min.expiresAt;
    if (amount <= 0 || !expiresAt) continue;
    const daysLeft = Math.max(1, Math.ceil((expiresAt.getTime() - now.getTime()) / DAY_MS));
    await emit('credit.bonusExpiring', { userId: row.userId, amount, expiresAt, daysLeft });
    reminded++;
  }
  return reminded;
}

/** Job chỉ xét các lần tặng hết hạn trong chừng này ngày gần nhất (lần trước đã trừ xong) */
const BONUS_EXPIRY_LOOKBACK_DAYS = 30;

/**
 * Job trừ xu tặng đã hết hạn (bút toán EXPIRE, loại BONUS). Xu tặng tiêu theo hạn gần nhất trước
 * (mọi lần tặng cùng hạn 90 ngày, nên hạn gần nhất cũng là lần tặng cũ nhất), vậy phần đã tiêu / đã trừ
 * luôn lấy từ các lần tặng cũ trước. Số cần trừ = tổng các lần tặng đã hết hạn − tổng xu tặng đã ra
 * (tiêu + trừ trước đó), không vượt số xu tặng còn lại. Chạy lại nhiều lần không trừ thêm.
 * Trả về tổng số xu đã trừ.
 */
export async function expireBonusCredits(now = new Date()) {
  const users = await prisma.creditTransaction.groupBy({
    by: ['userId'],
    where: {
      bucket: CreditBucket.BONUS, amount: { gt: 0 },
      expiresAt: { lte: now, gt: new Date(now.getTime() - BONUS_EXPIRY_LOOKBACK_DAYS * DAY_MS) },
    },
  });
  let total = 0;
  for (const { userId } of users) {
    total += await inTransaction(async (tx) => {
      const bonus = { userId, bucket: CreditBucket.BONUS };
      const [expired, outflow, balance] = await Promise.all([
        tx.creditTransaction.aggregate({ where: { ...bonus, amount: { gt: 0 }, expiresAt: { lte: now } }, _sum: { amount: true } }),
        tx.creditTransaction.aggregate({ where: { ...bonus, amount: { lt: 0 } }, _sum: { amount: true } }),
        tx.creditTransaction.aggregate({ where: bonus, _sum: { amount: true } }),
      ]);
      const due = Math.min(balance._sum.amount ?? 0, (expired._sum.amount ?? 0) + (outflow._sum.amount ?? 0));
      if (due <= 0) return 0;
      await repo.createTransactions(tx, [{ ...bonus, type: CreditTxnType.EXPIRE, amount: -due, note: 'Xu tặng hết hạn' }]);
      return due;
    });
  }
  return total;
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
  let result: { order: Order; credited: boolean };
  try {
    result = await inTransaction(async (tx) => {
      const order = await repo.findOrder(tx, orderId);
      if (!order) throw new AppError(404, 'TOPUP_NOT_FOUND', 'Không tìm thấy đơn nạp.');
      if (order.status === TopupStatus.PAID) return { order, credited: false };
      if (order.amountVnd !== amountVnd) throw new AppError(409, 'TOPUP_AMOUNT_MISMATCH', 'Số tiền không khớp đơn nạp.');
      if (!await repo.markOrderPaid(tx, orderId, { providerTxnId, paidAt: now })) {
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
  // Sau khi commit: báo người nạp (2.1); lỗi ghi thông báo chỉ ghi log, xu vẫn đã cộng
  if (result.credited) {
    const { order } = result;
    await emit('credit.topupPaid', { userId: order.userId, orderId: order.id, code: order.code,
      credits: order.credits, bonus: order.bonusCredits });
  }
  return result;
}

/**
 * Callback ZaloPay gửi tới máy chủ khi khách trả xong. Chỉ cộng xu khi chữ ký đúng (key2).
 * Trả return_code: 1 = đã ghi nhận, -1 = sai chữ ký, 0 = lỗi tạm (ZaloPay gửi lại).
 */
export async function zaloPayCallback(body: { data?: unknown; mac?: unknown }) {
  const config = zalopay.zaloPayConfig();
  if (!config) return { return_code: 0, return_message: 'not configured' };
  const data = zalopay.verifyCallback(config, body.data, body.mac);
  if (!data) return { return_code: -1, return_message: 'mac not equal' };
  try {
    const order = await inTransaction((tx) => repo.findOrderByProviderRef(tx, data.app_trans_id));
    if (!order) return { return_code: 2, return_message: 'order not found' };
    await markPaid(order.id, { providerTxnId: `ZLP-${data.zp_trans_id}`, amountVnd: data.amount });
    return { return_code: 1, return_message: 'success' };
  } catch (error) {
    if (error instanceof AppError && error.code === 'TOPUP_ALREADY_PROCESSED') return { return_code: 1, return_message: 'success' };
    console.error('[credits] ZaloPay callback failed', data.app_trans_id, error);
    return { return_code: 0, return_message: error instanceof Error ? error.message : 'error' };
  }
}

/**
 * Webhook SePay khi tài khoản nhận VietQR có tiền vào. Chỉ cộng xu khi đúng API key,
 * nội dung có mã đơn VietQR và số tiền khớp đơn. SePay coi là nhận khi trả 200 + { success: true };
 * lỗi tạm trả 500 để SePay gửi lại. Mỗi giao dịch SePay (id) chỉ cộng một lần.
 */
export type SepayRequest = { authorization: unknown; signature: unknown; timestamp: unknown; rawBody: Buffer | undefined; body: unknown };

export async function sepayWebhook({ authorization, signature, timestamp, rawBody, body }: SepayRequest) {
  // Có Secret Key thì kiểm chữ ký HMAC (khuyến nghị, chạy được qua SePay CLI), không thì kiểm API Key
  const secret = sepay.sepayWebhookSecret();
  const key = sepay.sepayWebhookKey();
  if (!secret && !key) return { status: 503, body: { success: false, message: 'not configured' } };
  const authorized = secret
    ? sepay.verifySignature({ signature, timestamp, rawBody, secret })
    : sepay.verifyApiKey(authorization, key!);
  if (!authorized) {
    // Không ghi key ra log, chỉ ghi lý do để dò cấu hình
    console.warn('[credits] SePay webhook unauthorized:', secret
      ? `HMAC signature ${signature ? 'mismatch or expired' : 'header missing'}`
      : sepay.describeAuthHeader(authorization));
    return { status: 401, body: { success: false, message: 'unauthorized' } };
  }
  const transfer = sepay.parseWebhook(body);
  if (!transfer) return { status: 400, body: { success: false, message: 'invalid payload' } };
  // Tiền ra, hoặc chuyển khoản không phải để nạp xu: ghi nhận để SePay không gửi lại
  const ignore = (reason: string) => {
    console.info('[credits] SePay ignored', transfer.id, reason);
    return { status: 200, body: { success: true, message: reason } };
  };
  if (transfer.transferType !== 'in') return ignore('not incoming');
  const code = sepay.extractTopupCode(transfer);
  if (!code) return ignore('no topup code');
  try {
    const order = await inTransaction((tx) => repo.findOrderByCode(tx, code));
    if (!order || order.method !== CreditPayMethod.VIETQR) return ignore(`order not found ${code}`);
    // Chuyển thiếu/thừa: không tự cộng, cần đối soát tay
    if (transfer.amount !== order.amountVnd) {
      console.warn('[credits] SePay amount mismatch', code, transfer.amount, order.amountVnd);
      return ignore('amount mismatch');
    }
    await markPaid(order.id, { providerTxnId: `SEPAY-${transfer.id}`, amountVnd: transfer.amount });
    return { status: 200, body: { success: true } };
  } catch (error) {
    if (error instanceof AppError && ['TOPUP_ALREADY_PROCESSED', 'TOPUP_NOT_PENDING'].includes(error.code)) {
      return ignore(error.code);
    }
    console.error('[credits] SePay webhook failed', transfer.id, error);
    return { status: 500, body: { success: false } };
  }
}

/** Cổng thử: giả lập cổng trả kết quả cho đơn của chính mình. Tắt khi production hoặc PAYMENT_MODE=live. */
export async function simulateSandbox(userId: string, id: string, result: 'success' | 'fail') {
  if (!sandboxEnabled()) throw new AppError(404, 'NOT_FOUND', 'Không tìm thấy.');
  const order = await inTransaction((tx) => ownOrder(tx, userId, id));
  if (order.status !== TopupStatus.PENDING) throw new AppError(409, 'TOPUP_NOT_PENDING', 'Đơn không còn chờ thanh toán.');
  // Giả lập cổng báo thất bại: như cổng thật, có thông báo (2.2)
  if (result === 'fail') {
    if (!await closePending(order, TopupStatus.FAILED)) throw new AppError(409, 'TOPUP_NOT_PENDING', 'Đơn không còn chờ thanh toán.');
    return { id, status: TopupStatus.FAILED };
  }
  const { order: paid } = await markPaid(order.id, { providerTxnId: `SANDBOX-${order.code}`, amountVnd: order.amountVnd });
  return withPayment(paid);
}
