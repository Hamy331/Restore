import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { requirePermission } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import * as creditController from './credit.controller.js';
import { historyQuery, idParams, sandboxBody, topupBody } from './credit.validator.js';

/** Xu ReStore (credit): ví, gói nạp, đơn nạp. Gắn tại /api/v1/credits */
const creditRouter = Router();
const buyer = requirePermission(PERMISSION.CREDIT_PURCHASE);

/**
 * Gói nạp đang bán, rẻ trước
 *
 * Trả về: [{ id, priceVnd, credits, bonusCredits, popular }]
 */
creditRouter.get('/packages', creditController.listPackages);

/**
 * Số dư ví
 *
 * Trả về: { available, paid, bonus, held, nextBonusExpiry }
 */
creditRouter.get('/wallet', buyer, creditController.getWallet);

/**
 * Lịch sử xu, mới trước. Query: page, limit (≤50), type? topup | spend | refund
 */
creditRouter.get('/transactions', buyer, validate({ query: historyQuery }), creditController.listTransactions);

/**
 * Tạo đơn nạp PENDING (hết hạn sau 15 phút)
 *
 * Body:
 *  - packageId: string
 *  - method: VNPAY | VIETQR
 *
 * Trả về: 201 { id, code, status, amountVnd, credits, bonusCredits, expiresAt, payment: { sandbox, payUrl, vietQr } }
 */
creditRouter.post('/topups', buyer, validate({ body: topupBody }), creditController.createTopup);

/**
 * Trạng thái đơn nạp của mình (app hỏi lại sau khi quay về từ cổng)
 */
creditRouter.get('/topups/:id', buyer, validate({ params: idParams }), creditController.getTopup);

/**
 * Huỷ đơn chưa trả
 */
creditRouter.post('/topups/:id/cancel', buyer, validate({ params: idParams }), creditController.cancelTopup);

/**
 * Cổng thử: giả lập kết quả trả tiền. Chỉ có khi không phải production và PAYMENT_MODE khác "live".
 *
 * Body:
 *  - result: success | fail
 */
creditRouter.post('/topups/:id/sandbox', buyer, validate({ params: idParams, body: sandboxBody }), creditController.simulateSandbox);

export default creditRouter;
