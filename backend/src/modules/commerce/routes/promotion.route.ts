import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { idParams, promotionPackageBody, purchaseBody } from '../commerce.validator.js';
import * as promotionController from '../controllers/promotion.controller.js';

/** Gói đẩy tin, đẩy tin và đơn mua đẩy tin, gắn tại /api/v1/promotions */
const promotionRouter = Router();
const purchase = requirePermission(PERMISSION.PROMOTION_PURCHASE);
const manage = requirePermission(PERMISSION.PROMOTION_MANAGE);

/**
 * Toàn bộ gói đẩy tin (kể cả đã ngừng bán)
 */
promotionRouter.get('/packages', promotionController.listPackages);

/**
 * Tạo gói đẩy tin, ghi AdminAudit
 *
 * Body:
 *  - name: string (3-80)
 *  - kind: 'BUMP' | 'FEATURED'
 *  - durationDays: number (1-30)
 *  - priority: number - BUMP là 0, FEATURED 1-10
 *  - price: string - giá VND
 *  - active: boolean
 */
promotionRouter.post('/packages', manage, validate({ body: promotionPackageBody }), promotionController.createPackage);

/**
 * Sửa gói đẩy tin; gói đã có giao dịch chỉ đổi được tên, giá và trạng thái bán. Ghi AdminAudit
 *
 * Path params:
 *  - id: string - mã gói
 *
 * Body: như khi tạo
 */
promotionRouter.put('/packages/:id', manage, validate({ params: idParams, body: promotionPackageBody }), promotionController.updatePackage);

/**
 * 50 lượt đẩy tin gần nhất của tôi
 */
promotionRouter.get('/my', purchase, promotionController.listMine);

/**
 * Dùng lượt đẩy tin kèm gói cửa hàng (tin phải thuộc danh mục cửa hàng)
 *
 * Body:
 *  - listingId: string - tin đang hiển thị của tôi
 *  - packageId: string - gói đẩy tin đang bán
 *
 * Trả về: 201 Promotion (kèm package)
 */
promotionRouter.post('/redeem', purchase, validate({ body: purchaseBody }), promotionController.redeem);

/**
 * Đặt mua gói đẩy tin cho một tin; mỗi tin chỉ có một đơn chờ
 *
 * Body: như redeem
 *
 * Trả về: 201 PromotionOrder (kèm package, listing)
 */
promotionRouter.post('/orders', purchase, validate({ body: purchaseBody }), promotionController.createOrder);

/**
 * Tối đa 100 đơn đẩy tin đang chờ, cũ trước
 */
promotionRouter.get('/admin/orders', manage, promotionController.listPendingOrders);

/**
 * Xác nhận đơn: tạo quảng cáo, nối tiếp sau quảng cáo cùng loại đang chạy. Ghi AdminAudit
 *
 * Path params:
 *  - id: string - mã đơn
 *
 * Body:
 *  - reason?: string (5-300) - mặc định "Đã đối soát thanh toán"
 *
 * Trả về: Promotion (kèm package)
 */
promotionRouter.post('/admin/orders/:id/confirm', manage, validate({ params: idParams }), promotionController.confirmOrder);

/**
 * Từ chối đơn, ghi AdminAudit. Trả { success: true }
 *
 * Path params:
 *  - id: string - mã đơn
 *
 * Body:
 *  - reason?: string (5-300)
 */
promotionRouter.post('/admin/orders/:id/reject', manage, validate({ params: idParams }), promotionController.rejectOrder);

export default promotionRouter;
