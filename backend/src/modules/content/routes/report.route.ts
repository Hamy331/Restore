import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { pageOnlyQuery, reportBody } from '../content.validator.js';
import * as reportController from '../controllers/report.controller.js';

/** Báo cáo vi phạm, gắn tại /api/v1/content */
const reportRouter = Router();
const submit = requirePermission(PERMISSION.REPORT_SUBMIT);

/**
 * Báo cáo tin đang hiển thị hoặc thành viên. Không tự báo cáo mình; mỗi đối tượng một báo cáo đang mở
 *
 * Body:
 *  - targetType: 'LISTING' | 'USER'
 *  - targetId: string
 *  - reason: string (5-300)
 *  - evidence: string (5-4000)
 *
 * Trả về: ViolationReport
 */
reportRouter.post('/reports', submit, validate({ body: reportBody }), reportController.create);

/**
 * Báo cáo của tôi, mới trước, 20 mỗi trang
 *
 * Query params:
 *  - page?: number (mặc định 1)
 */
reportRouter.get('/reports/mine', submit, validate({ query: pageOnlyQuery }), reportController.listMine);

export default reportRouter;
