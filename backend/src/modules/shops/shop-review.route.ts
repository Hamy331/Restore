import { Response, Router } from 'express';
import { z } from 'zod';
import { PERMISSION } from '../../common/auth/permissions.js';
import { ok } from '../../common/http/response.js';
import { oneOf, str, strictBody } from '../../common/validation/schemas.js';
import { AuthRequest, authorizePermission } from '../../middlewares/auth.middleware.js';
import { requireJson } from '../../middlewares/require-json.middleware.js';
import { getInput, validate, ValidatedInput } from '../../middlewares/validate.middleware.js';
import * as shopReviewService from './shop-review.service.js';
import { shopIdParams, type ShopIdParams } from './shop.validator.js';

const listQuery = z.object({ status: oneOf('status', ['PENDING', 'APPROVED', 'REJECTED', 'ALL'] as const, 'PENDING') });
const rejectBody = strictBody({ note: str('note', { max: 300 }) });

/** Duyệt cửa hàng, gắn tại /api/v1/admin (adminRouter đã xác thực token) */
export const shopReviewAdminRouter = Router();
const moderate = authorizePermission(PERMISSION.LISTING_MODERATE);
const shopId = (res: Response) => getInput<ValidatedInput<undefined, ShopIdParams>>(res).params.id;

/**
 * Query: status? = PENDING (mặc định, gửi lâu nhất trước) | APPROVED | REJECTED | ALL.
 * Trả về: { pendingCount, items: [Shop + status, submittedAt, reviewedAt, rejectNote, verified,
 *   owner { id, email, fullName, status }, planTier, planEndsAt] }
 */
shopReviewAdminRouter.get('/shops', moderate, validate({ query: listQuery }), async (_req: AuthRequest, res: Response) => {
  const { query } = getInput<ValidatedInput<z.infer<typeof listQuery>>>(res);
  ok(res, await shopReviewService.adminListShops(query.status));
});

/** Duyệt: shop có trang công khai, tên bị khoá; ghi AdminAudit, báo chủ shop. Lỗi 404 SHOP_NOT_FOUND, 409 SHOP_NOT_PENDING */
shopReviewAdminRouter.post('/shops/:id/approve', moderate, validate({ params: shopIdParams }), async (req: AuthRequest, res: Response) => {
  ok(res, await shopReviewService.approveShop(req.user!.userId, shopId(res)));
});

/** Từ chối. Body: note (lý do gửi chủ shop, 1-300 ký tự). Chủ shop sửa rồi lưu là gửi duyệt lại */
shopReviewAdminRouter.post('/shops/:id/reject', moderate, requireJson, validate({ params: shopIdParams, body: rejectBody }),
  async (req: AuthRequest, res: Response) => {
    const { params, body } = getInput<ValidatedInput<undefined, ShopIdParams, z.infer<typeof rejectBody>>>(res);
    ok(res, await shopReviewService.rejectShop(req.user!.userId, params.id, body.note));
  });
