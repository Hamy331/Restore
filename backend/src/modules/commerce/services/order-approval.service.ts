import { Role } from '@prisma/client';
import { audit } from '../../../common/audit/admin-audit.js';
import { text as adminText } from '../../../common/validation/admin-input.js';
import { AppError } from '../../../common/errors/app-error.js';
import { emit } from '../../../common/events/domain-events.js';
import * as promotionRepository from '../repositories/promotion.repository.js';
import type { Db } from '../repositories/quota.repository.js';
import * as storeRepository from '../repositories/store.repository.js';
import { withQuotaTransaction } from './quota.service.js';

/**
 * Quy trình duyệt đơn dùng chung cho đơn gói cửa hàng và đơn đẩy tin:
 * chỉ đơn PENDING mới được xử lý, đổi trạng thái có điều kiện để hai admin không duyệt trùng,
 * và mỗi quyết định ghi một dòng AdminAudit.
 */
export type OrderKind = 'STORE_ORDER' | 'PROMOTION_ORDER';

const ORDERS = {
  STORE_ORDER: { decide: storeRepository.decidePendingOrder, notPending: 'STORE_ORDER_NOT_PENDING', userUnavailable: 'STORE_USER_UNAVAILABLE',
    userMessage: 'Tài khoản mua gói không còn hoạt động.' },
  PROMOTION_ORDER: { decide: promotionRepository.decidePendingOrder, notPending: 'PROMOTION_ORDER_NOT_PENDING', userUnavailable: 'PROMOTION_USER_UNAVAILABLE',
    userMessage: 'Tài khoản mua quảng cáo không còn hoạt động.' },
} as const;

const DEFAULT_REASON = { CONFIRM: 'Đã đối soát thanh toán', REJECT: 'Đơn không đủ điều kiện xác nhận' } as const;

/** Đơn phải còn PENDING (đọc ra trước khi xử lý) */
export function assertPending(kind: OrderKind, order: { status: string } | null): asserts order {
  if (!order || order.status !== 'PENDING') throw new AppError(409, ORDERS[kind].notPending, 'Đơn không còn ở trạng thái chờ.');
}

/** Người mua phải là USER đang hoạt động */
export function assertBuyerActive(kind: OrderKind, user: { role: Role; status: string }) {
  if (user.role !== Role.USER || user.status !== 'ACTIVE') throw new AppError(409, ORDERS[kind].userUnavailable, ORDERS[kind].userMessage);
}

/** Đổi đơn sang CONFIRMED; đơn đã bị người khác xử lý thì 409 */
export async function markConfirmed(tx: Db, kind: OrderKind, id: string, now: Date) {
  if (!await ORDERS[kind].decide(tx, id, 'CONFIRMED', now)) throw new AppError(409, ORDERS[kind].notPending, 'Đơn đã được xử lý.');
}

/** Ghi AdminAudit cho quyết định; reason (5-300 ký tự) mặc định theo loại quyết định */
export function auditDecision(tx: Db, kind: OrderKind, actorId: string, id: string, action: 'CONFIRM' | 'REJECT', reason: unknown,
  before?: unknown, after?: unknown) {
  return audit(tx, actorId, action, kind, id, adminText(reason ?? DEFAULT_REASON[action], 'reason', 5, 300), before, after);
}

/** Người mua, tên gói và tin của đơn (để báo khi bị từ chối) */
async function orderSummary(tx: Db, kind: OrderKind, id: string) {
  if (kind === 'STORE_ORDER') {
    const order = await storeRepository.findOrderSummary(tx, id);
    return order && { userId: order.userId, packageName: order.package.name, listingId: null, listingTitle: null };
  }
  const order = await promotionRepository.findOrderSummary(tx, id);
  return order && { userId: order.userId, packageName: order.package.name, listingId: order.listing.id, listingTitle: order.listing.title };
}

/** Từ chối đơn đang chờ, rồi báo người mua kèm lý do (2.7) */
export async function rejectOrder(kind: OrderKind, actorId: string, id: string, reason: unknown) {
  const event = await withQuotaTransaction(async (tx) => {
    if (!await ORDERS[kind].decide(tx, id, 'REJECTED', new Date())) {
      throw new AppError(409, ORDERS[kind].notPending, 'Đơn không còn ở trạng thái chờ.');
    }
    const audited = await auditDecision(tx, kind, actorId, id, 'REJECT', reason);
    const summary = await orderSummary(tx, kind, id);
    return summary && { ...summary, orderId: id, kind, reason: audited.reason ?? '' };
  });
  if (event) await emit('order.rejected', event);
}
