import { CreditBucket, CreditTxnType, Prisma, SepayEventStatus, TopupStatus } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';

export type Db = Prisma.TransactionClient;

export const findActivePackages = () =>
  prisma.creditPackage.findMany({ where: { active: true }, orderBy: [{ sortOrder: 'asc' }, { priceVnd: 'asc' }] });

export const findActivePackage = (tx: Db, id: string) => tx.creditPackage.findFirst({ where: { id, active: true } });

/** Tổng xu theo loại (nạp / tặng) của một người */
export async function sumByBucket(userId: string) {
  const rows = await prisma.creditTransaction.groupBy({ by: ['bucket'], where: { userId }, _sum: { amount: true } });
  return rows.map((row) => ({ bucket: row.bucket, amount: row._sum.amount ?? 0 }));
}

/** Tổng xu đang giữ cho tin chờ duyệt */
export async function sumHeld(userId: string) {
  const sum = await prisma.creditHold.aggregate({ where: { userId, status: 'HELD' }, _sum: { amount: true } });
  return sum._sum.amount ?? 0;
}

/** Hạn gần nhất của các lần được tặng xu còn hiệu lực */
export const findNextBonusExpiry = (userId: string, now: Date) =>
  prisma.creditTransaction.findFirst({
    where: { userId, bucket: CreditBucket.BONUS, amount: { gt: 0 }, expiresAt: { gt: now } },
    orderBy: { expiresAt: 'asc' },
    select: { expiresAt: true },
  });

export const countTransactions = (userId: string, types?: CreditTxnType[]) =>
  prisma.creditTransaction.count({ where: { userId, ...(types && { type: { in: types } }) } });

export const findTransactions = (userId: string, types: CreditTxnType[] | undefined, skip: number, take: number) =>
  prisma.creditTransaction.findMany({
    where: { userId, ...(types && { type: { in: types } }) },
    orderBy: { createdAt: 'desc' },
    skip,
    take,
    include: { topupOrder: { select: { code: true, method: true, amountVnd: true } } },
  });

/** Đơn chờ trả đã quá hạn của người dùng → EXPIRED */
export const expireStalePending = (tx: Db, userId: string, now: Date) =>
  tx.creditTopupOrder.updateMany({ where: { userId, status: TopupStatus.PENDING, expiresAt: { lte: now } }, data: { status: TopupStatus.EXPIRED } });

export const countPending = (tx: Db, userId: string) =>
  tx.creditTopupOrder.count({ where: { userId, status: TopupStatus.PENDING } });

export const createOrder = (tx: Db, data: Prisma.CreditTopupOrderUncheckedCreateInput) => tx.creditTopupOrder.create({ data });

export const findOrder = (tx: Db, id: string) => tx.creditTopupOrder.findUnique({ where: { id } });

export const findOrderByCode = (tx: Db, code: string) => tx.creditTopupOrder.findUnique({ where: { code } });

export const findOrderByProviderRef = (tx: Db, providerRef: string) => tx.creditTopupOrder.findUnique({ where: { providerRef } });

/** Gắn mã đơn và trang thanh toán của cổng vào đơn vừa tạo */
export const attachGateway = (tx: Db, id: string, data: { providerRef: string; payUrl: string }) =>
  tx.creditTopupOrder.update({ where: { id }, data });

/**
 * Cổng đã nhận tiền: đổi sang PAID nếu đơn chưa PAID/REFUNDED. Đơn đã hết hạn hoặc bị huỷ
 * trên app mà khách vẫn trả xong trên cổng thì vẫn ghi nhận, vì tiền đã bị trừ.
 */
export const markOrderPaid = async (tx: Db, id: string, data: { providerTxnId: string; paidAt: Date }) =>
  (await tx.creditTopupOrder.updateMany({
    where: { id, status: { in: [TopupStatus.PENDING, TopupStatus.EXPIRED, TopupStatus.FAILED] } },
    data: { ...data, status: TopupStatus.PAID },
  })).count;

/** Đổi trạng thái chỉ khi đơn còn PENDING; trả về số dòng đã đổi (0 = người khác đã xử lý) */
export const decidePending = async (tx: Db, id: string, data: Prisma.CreditTopupOrderUncheckedUpdateInput) =>
  (await tx.creditTopupOrder.updateMany({ where: { id, status: TopupStatus.PENDING }, data })).count;

/**
 * Ghi nhận một lần SePay báo giao dịch, theo id của SePay. Đã có (SePay gửi lại) thì giữ nguyên bản cũ.
 * Trả về bản ghi hiện có trong DB.
 */
export async function recordSepayEvent(data: Prisma.SepayWebhookEventUncheckedCreateInput) {
  try {
    return await prisma.sepayWebhookEvent.create({ data });
  } catch (error) {
    if (!(error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002')) throw error;
    return prisma.sepayWebhookEvent.findUniqueOrThrow({ where: { id: data.id } });
  }
}

/** Chốt kết quả xử lý một giao dịch SePay */
export const decideSepayEvent = (id: string, data: { status: SepayEventStatus; success: boolean; reason?: string; topupOrderId?: string | null }) =>
  prisma.sepayWebhookEvent.update({ where: { id }, data });

const fingerprint = { id: true, amountVnd: true, transactionDate: true, referenceCode: true, accountNumber: true } as const;

/** Giao dịch đã trả đơn nạp này (để biết một giao dịch mới có phải chính nó không) */
export const findPayingEvents = (topupOrderId: string) =>
  prisma.sepayWebhookEvent.findMany({ where: { topupOrderId, status: SepayEventStatus.PAID }, select: fingerprint });

/** Job đối soát đã xử lý giao dịch API này chưa */
export const findEventByApiTransaction = (apiTransactionId: string) =>
  prisma.sepayWebhookEvent.findUnique({ where: { apiTransactionId }, select: { id: true } });

/** Các bản ghi webhook có thể là cùng giao dịch với một dòng API (lọc sơ bằng số tiền, thời điểm, mã tham chiếu) */
export const findWebhookTwins = (where: { amountVnd: number; transactionDate: string; referenceCode: string | null }) =>
  prisma.sepayWebhookEvent.findMany({
    where: { source: 'webhook', apiTransactionId: null, amountVnd: where.amountVnd, transactionDate: where.transactionDate,
      ...(where.referenceCode ? { referenceCode: where.referenceCode } : {}) },
    select: fingerprint,
    take: 5,
  });

/** Ghi nhớ dòng API ứng với bản ghi webhook đã có, để lần sau bỏ qua */
export async function linkApiTransaction(eventId: string, apiTransactionId: string) {
  try {
    await prisma.sepayWebhookEvent.update({ where: { id: eventId }, data: { apiTransactionId } });
  } catch (error) {
    if (!(error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002')) throw error;
  }
}

/** Giao dịch ghi nhận rồi nhưng chưa xử lý xong (lỗi giữa chừng) quá một khoảng thời gian */
export const findStuckSepayEvents = (before: Date, take = 50) =>
  prisma.sepayWebhookEvent.findMany({ where: { status: SepayEventStatus.RECEIVED, createdAt: { lt: before } }, orderBy: { createdAt: 'asc' }, take });

export const getSepaySyncCursor = async (id: string) => (await prisma.sepaySyncState.findUnique({ where: { id } }))?.cursor ?? null;

export const saveSepaySyncCursor = (id: string, cursor: string) =>
  prisma.sepaySyncState.upsert({ where: { id }, create: { id, cursor }, update: { cursor } });

export const createTransactions = (tx: Db, data: Prisma.CreditTransactionUncheckedCreateInput[]) =>
  tx.creditTransaction.createMany({ data });
