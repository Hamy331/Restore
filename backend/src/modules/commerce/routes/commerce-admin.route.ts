import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { authorizePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { adminOrderQuery, idParams, storePackageBody } from '../commerce.validator.js';
import * as promotionController from '../controllers/promotion.controller.js';
import * as storeController from '../controllers/store.controller.js';

/** Quản trị gói cửa hàng và đơn, gắn tại /api/v1/admin (adminRouter đã xác thực token) */
const commerceAdminRouter = Router();
const manageStores = authorizePermission(PERMISSION.STORE_ORDER_MANAGE);
const managePromotions = authorizePermission(PERMISSION.PROMOTION_MANAGE);

/**
 * Mọi gói cửa hàng (kể cả PERSONAL), ưu tiên thấp trước
 */
commerceAdminRouter.get('/store-packages', manageStores, storeController.listAllPackages);

/**
 * Đơn mua gói cửa hàng, mới trước, 25 đơn mỗi trang
 *
 * Query params:
 *  - page?: number (mặc định 1)
 *  - status?: 'PENDING' | 'CONFIRMED' | 'REJECTED'
 *
 * Trả về: { items: [StoreOrder kèm user, package, category], total, page }
 */
commerceAdminRouter.get('/store-orders', manageStores, validate({ query: adminOrderQuery }), storeController.listOrders);

/**
 * Đơn đẩy tin, mới trước, 25 đơn mỗi trang
 *
 * Query params:
 *  - page?: number (mặc định 1)
 *  - status?: 'PENDING' | 'CONFIRMED' | 'REJECTED'
 *
 * Trả về: { items: [PromotionOrder kèm user, package, listing], total, page }
 */
commerceAdminRouter.get('/promotion-orders', managePromotions, validate({ query: adminOrderQuery }), promotionController.listOrders);

/**
 * Sửa gói cửa hàng, ghi AdminAudit. Gói PERSONAL phải miễn phí, priorityLevel 0, monthlyPromotionQuota 0.
 *
 * Path params:
 *  - id: string - mã gói
 *
 * Body:
 *  - name: string (3-80)
 *  - monthlyPrice: string - số nguyên VND, tối đa 12 chữ số
 *  - dailyListingLimit: number (1-10000)
 *  - activeListingLimit: number (1-100000)
 *  - draftLimit?: number (1-1000) - số tin nháp giữ cùng lúc, bỏ trống thì giữ nguyên
 *  - monthlyPromotionQuota: number (0-10000)
 *  - priorityLevel: number (0-10)
 *
 * Trả về: StorePackage sau khi sửa
 */
commerceAdminRouter.put('/store-packages/:id', manageStores, validate({ params: idParams, body: storePackageBody }), storeController.updatePackage);

export default commerceAdminRouter;
