import { NextFunction, Request, Response } from 'express';
import { Prisma } from '@prisma/client';
import { isAppError } from '../errors/app-error.js';

export const notFoundHandler = (_req: Request, res: Response) =>
  res.status(404).json({ success: false, error: 'Không tìm thấy API.', code: 'NOT_FOUND' });

export const errorHandler = (
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
) => {
  if (isAppError(error)) {
    return res.status(error.statusCode).json({
      success: false,
      error: error.message,
      code: error.code,
      ...(error.field ? { field: error.field } : {}),
    });
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
    return res.status(409).json({
      success: false,
      error: 'Email hoặc tên người dùng đã được sử dụng.',
      code: 'DUPLICATE_ACCOUNT',
    });
  }

  console.error('[API] Unhandled error:', error);
  return res.status(500).json({
    success: false,
    error: 'Hệ thống đang bận. Vui lòng thử lại sau.',
    code: 'INTERNAL_SERVER_ERROR',
  });
};
