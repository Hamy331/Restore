import { NextFunction, Request, Response } from 'express';
import { verifyAccessToken } from '../modules/auth/token.service.js';
import { Role } from '@prisma/client';
import { findAuthUserById } from '../modules/auth/auth.repository.js';

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

export const authorizeRoles = (...allowedRoles: Role[]) =>
  (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Vui lòng đăng nhập để tiếp tục.',
        code: 'AUTH_REQUIRED',
      });
    }
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: 'Bạn không có quyền thực hiện thao tác này.',
        code: 'FORBIDDEN',
      });
    }
    next();
  };
