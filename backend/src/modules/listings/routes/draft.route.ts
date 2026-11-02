import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import * as draftController from '../controllers/draft.controller.js';
import { draftBody, listingIdParams } from '../listing.validator.js';

/** Bản nháp tin, gắn tại /api/v1/listings/drafts */
const draftRouter = Router();
const manageOwn = requirePermission(PERMISSION.LISTING_MANAGE_OWN);

/**
 * Lưu nháp mới; mọi trường đều có thể trống
 *
 * Body: như khi đăng tin, không trường nào bắt buộc
 *
 * Trả về: 201 Listing (status DRAFT)
 */
draftRouter.post('/drafts', manageOwn, validate({ body: draftBody }), draftController.create);

/**
 * Sửa nháp, hoặc đưa tin đã đăng về nháp để sửa tiếp
 *
 * Path params:
 *  - id: string - mã tin
 */
draftRouter.put('/drafts/:id', manageOwn, validate({ params: listingIdParams, body: draftBody }), draftController.update);

/**
 * Đăng nháp: cần đủ nội dung và ít nhất một ảnh, trừ lượt đăng. Gọi lại khi đã PENDING vẫn trả tin
 *
 * Path params:
 *  - id: string - mã tin
 */
draftRouter.post('/drafts/:id/publish', manageOwn, validate({ params: listingIdParams }), draftController.publish);

/**
 * Xóa nháp và ảnh của nó. Trả 204
 *
 * Path params:
 *  - id: string - mã tin
 */
draftRouter.delete('/drafts/:id', manageOwn, validate({ params: listingIdParams }), draftController.remove);

export default draftRouter;
