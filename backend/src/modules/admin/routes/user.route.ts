import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { authorizePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { userActionBody, userIdParams, userListQuery } from '../admin.validator.js';
import * as userController from '../controllers/user.controller.js';

/** Hồ sơ admin và quản lý thành viên, gắn tại /api/v1/admin */
const userRouter = Router();
const manageUsers = authorizePermission(PERMISSION.USER_MANAGE);

/**
 * Hồ sơ của admin đang đăng nhập
 *
 * Trả về: { id, email, fullName, username, role, status, suspendedUntil, updatedAt, createdAt }
 */
userRouter.get('/me', authorizePermission(PERMISSION.ADMIN_ACCESS), userController.getSelf);

/**
 * Thành viên (role USER), mới đăng ký trước, 25 mỗi trang
 *
 * Query params:
 *  - q?: string (1-100) - tìm trong họ tên hoặc email
 *  - page?: number (mặc định 1)
 *
 * Trả về: { items, total, page }
 */
userRouter.get('/users', manageUsers, validate({ query: userListQuery }), userController.listMembers);

/**
 * Cảnh cáo, tạm khóa, cấm hoặc mở lại tài khoản; khóa/cấm/mở lại thu hồi mọi phiên. Ghi AdminAudit.
 *
 * Path params:
 *  - id: string - mã thành viên
 *
 * Body:
 *  - action: 'WARN' | 'SUSPEND' | 'BAN' | 'RESTORE'
 *  - reason: string (5-300)
 *  - days?: number (1-365, mặc định 7) - số ngày tạm khóa
 *  - updatedAt: ISO 8601 - updatedAt của thành viên lúc admin mở
 *
 * Trả về: { updated: true }
 */
userRouter.post('/users/:id/action', manageUsers, validate({ params: userIdParams, body: userActionBody }), userController.act);

export default userRouter;
