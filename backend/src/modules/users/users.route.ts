import { Router } from 'express';
import { requireAuth } from '../../middlewares/auth.middleware.js';
import * as usersController from './users.controller.js';

/**
 * Module users, gắn tại /api/v1/users
 */
const router = Router();

/**
 * GET /api/v1/users/me
 * Mô tả:    Hồ sơ người dùng đang đăng nhập (trang chủ dùng để chào và hiện avatar).
 * Quyền:    Bắt buộc đăng nhập, vai trò USER hoặc ADMIN.
 * Header:   Authorization: Bearer <accessToken>
 * Tham số:  Không có.
 * Trả về:   200 { success, data: { id, email, fullName, username, phone, avatarUrl, role, status,
 *                                  ratingAverage, ratingCount, createdAt, updatedAt } }
 * Lỗi:      401 AUTH_REQUIRED | INVALID_ACCESS_TOKEN | SESSION_REVOKED | ACCOUNT_UNAVAILABLE
 */
router.get('/me', ...requireAuth(), usersController.getMe);

export default router;
