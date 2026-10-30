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

  if (typeof error === 'object' && error !== null && 'type' in error && error.type === 'entity.too.large') {
    const image = _req.headers['content-type']?.startsWith('image/');
    return res.status(413).json({success:false,error:image?'Ảnh phải có dung lượng tối đa 5 MB.':'Nội dung vượt quá dung lượng cho phép.',code:image?'IMAGE_TOO_LARGE':'PAYLOAD_TOO_LARGE'});
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
    return res.status(409).json({
      success: false,
      error: _req.path.includes('auth') ? 'Email hoặc tên người dùng đã được sử dụng.' : 'Mã hoặc đường dẫn đã được sử dụng.',
      code: _req.path.includes('auth') ? 'DUPLICATE_ACCOUNT' : 'DUPLICATE_RESOURCE',
    });
  }

  if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025') {
    return res.status(404).json({success:false,error:'Dữ liệu không còn tồn tại. Vui lòng tải lại.',code:'RESOURCE_NOT_FOUND'});
  }
  if (error instanceof Prisma.PrismaClientKnownRequestError && ['P2021','P2022'].includes(error.code)) {
    return res.status(503).json({success:false,error:'Database chưa được cập nhật. Cần chạy prisma migrate deploy.',code:'MIGRATION_REQUIRED'});
  }
  if (typeof error==='object' && error!==null && 'type' in error && error.type==='entity.parse.failed') {
    return res.status(400).json({success:false,error:'JSON không hợp lệ.',code:'INVALID_JSON'});
  }
  console.error('[API] Unhandled error:', error);
  return res.status(500).json({
    success: false,
    error: 'Hệ thống đang bận. Vui lòng thử lại sau.',
    code: 'INTERNAL_SERVER_ERROR',
  });
};
