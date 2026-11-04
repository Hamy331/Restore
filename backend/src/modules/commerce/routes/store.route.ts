import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { idParams, storeOrderBody } from '../commerce.validator.js';
import * as storeController from '../controllers/store.controller.js';

/** Gói cửa hàng và đơn mua gói, gắn tại /api/v1/stores */
const storeRouter = Router();
const purchase = requirePermission(PERMISSION.STORE_PURCHASE);
const manageOrders = requirePermission(PERMISSION.STORE_ORDER_MANAGE);

/**
 * Toàn bộ danh mục (kể cả đã tắt), để chọn danh mục cửa hàng
 */
storeRouter.get('/categories', storeController.listCategories);

/**
 * Gói cửa hàng đang bán (BASIC, PRO), ưu tiên thấp trước
 */
storeRouter.get('/packages', storeController.listPackages);

/**
 * Gói đang dùng, lượt đã dùng và còn lại, đơn đang chờ
 *
 * Trả về: { package, category, endsAt, pendingOrder, usage, remaining }
 */
storeRouter.get('/me', purchase, storeController.getMine);

/**
 * Đặt mua gói cửa hàng; mỗi người chỉ có một đơn chờ
 *
 * Body:
 *  - packageId: string - gói BASIC hoặc PRO
 *  - categoryId: string - danh mục cửa hàng
 *
 * Trả về: 201 StoreOrder (kèm package, category)
 */
storeRouter.post('/orders', purchase, validate({ body: storeOrderBody }), storeController.createOrder);

/**
 * Tối đa 100 đơn đang chờ, cũ trước
 */
storeRouter.get('/admin/orders', manageOrders, storeController.listPendingOrders);

/**
 * Xác nhận đơn: kích hoạt gói 30 ngày (mua lại đúng gói thì cộng dồn), ghi AdminAudit
 *
 * Path params:
 *  - id: string - mã đơn
 *
 * Body:
 *  - reason?: string (5-300) - mặc định "Đã đối soát thanh toán"
 *
 * Trả về: { orderId, subscription }
 */
storeRouter.post('/admin/orders/:id/confirm', manageOrders, validate({ params: idParams }), storeController.confirmOrder);

/**
 * Từ chối đơn, ghi AdminAudit. Trả { success: true }
 *
 * Path params:
 *  - id: string - mã đơn
 *
 * Body:
 *  - reason?: string (5-300)
 */
storeRouter.post('/admin/orders/:id/reject', manageOrders, validate({ params: idParams }), storeController.rejectOrder);

export default storeRouter;
