import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { authorizePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { auditQuery } from '../admin.validator.js';
import * as auditController from '../controllers/audit.controller.js';

/** Nhật ký quản trị, gắn tại /api/v1/admin */
const auditRouter = Router();

/**
 * Nhật ký quản trị (AdminAudit), mới trước, 25 dòng mỗi trang
 *
 * Query params:
 *  - page?: number (mặc định 1)
 *
 * Trả về: { items, total, page }
 */
auditRouter.get('/audit', authorizePermission(PERMISSION.ADMIN_ACCESS), validate({ query: auditQuery }), auditController.listLogs);

export default auditRouter;
