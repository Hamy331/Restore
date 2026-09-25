import { Request, Response, NextFunction } from 'express';

export const apiLogger = (req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  const timestamp = new Date().toISOString();

  let errorDetail = '';

  const originalJson = res.json;
  res.json = function (body) {
    if (res.statusCode >= 400 && body && body.error) {
      errorDetail = typeof body.error === 'string' ? body.error : JSON.stringify(body.error);
    }
    return originalJson.call(this, body);
  };

  res.on('finish', () => {
    const duration = Date.now() - start;
    const status = res.statusCode;
    
    // Lỗi 4xx, 5xx màu đỏ | Thành công 2xx màu xanh
    const color = status >= 400 ? '\x1b[31m' : '\x1b[32m';
    const reset = '\x1b[0m';

    let logMessage = `[${timestamp}] ${req.method} ${req.originalUrl} ${color}${status}${reset} - ${duration}ms`;
    
    if (errorDetail) {
      logMessage += `\n   ↳ ❌ Error: ${color}${errorDetail}${reset}`;
    }
    
    console.log(logMessage);
  });

  next();
};