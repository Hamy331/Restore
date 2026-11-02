import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { authorizePermission } from '../../middlewares/auth.middleware.js';
import { validate } from '../../middlewares/validate.middleware.js';
import * as catalogAdminController from './catalog-admin.controller.js';
import { categoryIdParams, conditionBody, conditionParams, createCategoryBody, updateCategoryBody } from './catalog.validator.js';

/** Quản trị danh mục và tình trạng, gắn tại /api/v1/admin (adminRouter đã xác thực token) */
const catalogAdminRouter = Router();
const manage = authorizePermission(PERMISSION.CATALOG_MANAGE);

/**
 * Mọi danh mục và tình trạng, kể cả đã tắt
 *
 * Trả về: { categories: Category[], conditions: ConditionPolicy[] }
 */
catalogAdminRouter.get('/catalog', manage, catalogAdminController.getCatalog);

/**
 * Tạo danh mục, ghi AdminAudit
 *
 * Body:
 *  - id: string (2-80, a-z 0-9 -)
 *  - name: string (2-100) - không trùng tên danh mục khác
 *  - description: string (0-500)
 *  - active: boolean
 */
catalogAdminRouter.post('/categories', manage, validate({ body: createCategoryBody }), catalogAdminController.createCategory);

/**
 * Sửa danh mục, ghi AdminAudit
 *
 * Path params:
 *  - id: string - mã danh mục
 *
 * Body:
 *  - name: string (2-100), description: string (0-500), active: boolean
 */
catalogAdminRouter.put('/categories/:id', manage, validate({ params: categoryIdParams, body: updateCategoryBody }), catalogAdminController.updateCategory);

/**
 * Đặt tên hiển thị và bật/tắt tình trạng, ghi AdminAudit
 *
 * Path params:
 *  - condition: ListingCondition
 *
 * Body:
 *  - name: string (2-100), active: boolean
 */
catalogAdminRouter.put('/conditions/:condition', manage, validate({ params: conditionParams, body: conditionBody }), catalogAdminController.updateCondition);

export default catalogAdminRouter;
