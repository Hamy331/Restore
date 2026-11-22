import { Response, Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { ok } from '../../common/http/response.js';
import { AuthRequest, authorizePermission } from '../../middlewares/auth.middleware.js';
import { requireJson } from '../../middlewares/require-json.middleware.js';
import { getInput, validate, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as verification from './shop-verification.service.js';
import {
  shopUnverifyBody, shopVerificationQuery, shopVerifyBody,
  type ShopVerificationBody, type ShopVerificationQuery,
} from './shop-verification.validator.js';
import { shopIdParams, type ShopIdParams } from './shop.validator.js';

/** Xác minh shop ("Shop uy tín" chỉ hiện shop đã xác minh), gắn tại /api/v1/admin (adminRouter đã xác thực token) */
export const shopVerificationRouter = Router();
const manageStores = authorizePermission(PERMISSION.STORE_ORDER_MANAGE);

const decide = async (req: AuthRequest, res: Response) => {
  const { params, body } = getInput<ValidatedInput<undefined, ShopIdParams, ShopVerificationBody>>(res);
  ok(res, await verification.setVerification(req.user!.userId, params.id, body));
};

/**
 * Query: status? = PENDING (chưa xác minh, cũ trước; mặc định) | VERIFIED | ALL, q? (tên shop, tên/email chủ), page?
 * Trả về: { items: [Shop + owner { id, fullName, email, status } + plan { tier, endsAt }], total, page, pending }
 */
shopVerificationRouter.get('/shops', manageStores, validate({ query: shopVerificationQuery }), async (_req, res) => {
  ok(res, await verification.listShops(getInput<ValidatedInput<ShopVerificationQuery>>(res).query));
});

/** Xác minh. Body: type (OFFICIAL_BRAND | CERTIFIED), reason?. Cấp mã chứng nhận RS-YYYY-NNNNN; ghi AdminAudit.
 *  Lỗi 404 SHOP_NOT_FOUND, 409 SHOP_ALREADY_VERIFIED */
shopVerificationRouter.post('/shops/:id/verify', manageStores, requireJson,
  validate({ params: shopIdParams, body: shopVerifyBody }), decide);

/** Thu hồi xác minh (shop rời "Shop uy tín"). Body: reason (5-300). Lỗi 404 SHOP_NOT_FOUND, 409 SHOP_NOT_VERIFIED */
shopVerificationRouter.post('/shops/:id/unverify', manageStores, requireJson,
  validate({ params: shopIdParams, body: shopUnverifyBody }), decide);
