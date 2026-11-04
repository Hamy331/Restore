import { NextFunction, Request, Response } from 'express';
import { AppError } from '../common/errors/app-error.js';

/**
 * Bắt buộc header `Content-Type: application/json` cho API nhận body JSON.
 * Thiếu header thì express.json() bỏ qua body, nên chặn sớm với lỗi 415 rõ ràng.
 */
export const requireJson = (req: Request, _res: Response, next: NextFunction) => {
  if (!req.is('application/json')) {
    return next(new AppError(415, 'UNSUPPORTED_MEDIA_TYPE', 'Header Content-Type phải là application/json.'));
  }
  next();
};
