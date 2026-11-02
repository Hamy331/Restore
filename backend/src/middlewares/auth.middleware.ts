import { NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../modules/auth/token.service.js';
import { Role } from '@prisma/client';
import { findAuthUserById } from '../modules/auth/auth.repository.js';
import { hasPermission, Permission } from '../common/auth/permissions.js';

export interface AuthRequest extends Request {
  user?: { userId: string; email: string; role: Role };
}

export const verifyToken = async (req: AuthRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'Vui lòng đăng nhập để tiếp tục.',
      code: 'AUTH_REQUIRED',
    });
  }

  let claims;
  try {
    claims = verifyAccessToken(authHeader.slice(7));
  } catch {
    return res.status(401).json({
      success: false,
      error: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.',
      code: 'INVALID_ACCESS_TOKEN',
    });
  }

  try {
    const user = await findAuthUserById(claims.userId);
    if (!user || user.status !== 'ACTIVE') {
      return res.status(401).json({
        success: false,
        error: 'Tài khoản không còn khả dụng.',
        code: 'ACCOUNT_UNAVAILABLE',
      });
    }
    if (claims.authVersion !== user.authVersion) {
      return res.status(401).json({
        success: false,
        error: 'Phiên đăng nhập đã bị thu hồi. Vui lòng đăng nhập lại.',
        code: 'SESSION_REVOKED',
      });
    }
    req.user = { userId: user.id, email: user.email, role: user.role };
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Cho phép cả khách lẫn người đã đăng nhập.
 * - Không gửi header Authorization: đi tiếp với req.user = undefined.
 * - Có gửi header: kiểm tra như verifyToken; token sai/hết hạn trả 401
 *   để app tự refresh token rồi gọi lại.
 */
export const optionalAuth = (req: AuthRequest, res: Response, next: NextFunction) =>
  req.headers.authorization ? verifyToken(req, res, next) : next();

/**
 * Chỉ kiểm tra quyền, dùng sau verifyToken (req.user đã có).
 * 401 AUTH_REQUIRED nếu chưa đăng nhập, 403 FORBIDDEN nếu vai trò thiếu quyền.
 */
export const authorizePermission = (...permissions: Permission[]) =>
  (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Vui lòng đăng nhập để tiếp tục.',
        code: 'AUTH_REQUIRED',
      });
    }
    if (!hasPermission(req.user.role, ...permissions)) {
      return res.status(403).json({
        success: false,
        error: 'Bạn không có quyền thực hiện thao tác này.',
        code: 'FORBIDDEN',
      });
    }
    next();
  };

/**
 * Bắt buộc đăng nhập và có đủ quyền. Gộp verifyToken + authorizePermission trong một middleware.
 * Dùng: router.post('/:id/favorite', requirePermission(PERMISSION.FAVORITE_WRITE), handler)
 */
export const requirePermission = (...permissions: Permission[]) => {
  const check = authorizePermission(...permissions);
  return (req: AuthRequest, res: Response, next: NextFunction) =>
    verifyToken(req, res, (error?: unknown) => (error ? next(error) : check(req, res, next)));
};
