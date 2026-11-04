import { Router } from 'express';
import { PERMISSION } from '../../common/auth/permissions.js';
import { requirePermission } from '../../middlewares/auth.middleware.js';
import * as usersController from './users.controller.js';

/** /api/v1/users */
const usersRouter = Router();

/**
 * Hồ sơ người đang đăng nhập (trang chủ dùng để chào và hiện avatar)
 *
 * Trả về: UserProfileDto
 */
usersRouter.get('/me', requirePermission(PERMISSION.PROFILE_READ), usersController.getMe);

export default usersRouter;
