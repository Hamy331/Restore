import { randomUUID } from 'node:crypto';
import { NextFunction, Request, Response } from 'express';

/**
 * Gắn mã định danh cho mỗi request để dò log.
 * Client có thể tự gửi header `X-Request-Id` (tối đa 64 ký tự chữ, số, gạch);
 * nếu không, server tự sinh. Mã được trả lại trong header phản hồi.
 */
const validId = /^[A-Za-z0-9_-]{1,64}$/;

export const requestId = (req: Request, res: Response, next: NextFunction) => {
  const incoming = req.header('x-request-id');
  const id = incoming && validId.test(incoming) ? incoming : randomUUID();
  res.locals.requestId = id;
  res.setHeader('X-Request-Id', id);
  next();
};
