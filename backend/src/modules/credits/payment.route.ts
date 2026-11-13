import { Router } from 'express';
import * as creditController from './credit.controller.js';

/** Cổng thanh toán gọi vào (không cần đăng nhập). Gắn tại /api/v1/payments */
const paymentRouter = Router();

/**
 * Callback ZaloPay: body { data, mac, type }. Chỉ cộng xu khi mac = HMAC-SHA256(key2, data) đúng.
 * Trả về { return_code, return_message } (1 = đã ghi nhận).
 */
paymentRouter.post('/zalopay/callback', creditController.zaloPayCallback);

/** Trang khách được chuyển về sau khi trả trên ZaloPay */
paymentRouter.get('/zalopay/return', creditController.zaloPayReturn);

export default paymentRouter;
