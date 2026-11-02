import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { requirePermission } from '../../middlewares/auth.middleware.js';
import { catalogAdminRouter } from '../catalog/index.js';
import { commerceAdminRouter } from '../commerce/index.js';
import { contentAdminRouter } from '../content/index.js';
import { listingsAdminRouter } from '../listings/index.js';
import auditRouter from './routes/audit.route.js';
import dashboardRouter from './routes/dashboard.route.js';
import userRouter from './routes/user.route.js';

/**
 * Toàn bộ API /api/v1/admin. Mọi đường dẫn (kể cả không tồn tại) đều cần đăng nhập và quyền ADMIN_ACCESS
 * trước, nên khách nhận 401 và thành viên nhận 403 thay vì 404, như API cũ.
 *
 * Module admin chỉ giữ hồ sơ admin, dashboard, thành viên, nhật ký. Phần còn lại do module sở hữu dữ liệu cung cấp:
 * listings (tin), commerce (gói, đơn), catalog (danh mục, tình trạng), content (bài viết, hỗ trợ, kiến thức, báo cáo).
 */
export const adminRouter = Router();
adminRouter.use(requirePermission(PERMISSION.ADMIN_ACCESS));
adminRouter.use(userRouter);
adminRouter.use(dashboardRouter);
adminRouter.use(listingsAdminRouter);
adminRouter.use(contentAdminRouter);
adminRouter.use(catalogAdminRouter);
adminRouter.use(auditRouter);
adminRouter.use(commerceAdminRouter);
