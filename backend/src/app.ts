import cors from 'cors';
import express from 'express';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './config/swagger.js';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware.js';
import { apiLogger } from './middlewares/logger.middleware.js';
import { requestId } from './middlewares/request-id.middleware.js';
import { apiRouter } from './routes.js';

/** Chỉ cho phép web origin trong CORS_ORIGINS; app Flutter native không cần CORS. */
function corsOptions(): cors.CorsOptions {
  const allowedOrigins = process.env.CORS_ORIGINS?.split(',').map((origin) => origin.trim()).filter(Boolean);
  return {
    exposedHeaders: ['X-Request-Id'],
    // Web quản trị khác origin với API gửi cookie phiên (chỉ các origin được phép ở dưới)
    credentials: true,
    origin(origin, callback) {
      const isLocalDevelopmentOrigin =
        process.env.NODE_ENV !== 'production' && !!origin && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
      callback(null, !origin || isLocalDevelopmentOrigin || (allowedOrigins?.includes(origin) ?? false));
    },
  };
}

export function createApp() {
  const app = express();
  // Chạy sau proxy / load balancer: đặt TRUST_PROXY (VD 1 = tin một lớp proxy) để req.ip là IP thật
  // của người dùng, rate limit mới đếm đúng. Để trống khi gọi thẳng vào server.
  const trustProxy = process.env.TRUST_PROXY?.trim();
  if (trustProxy) app.set('trust proxy', /^\d+$/.test(trustProxy) ? Number(trustProxy) : trustProxy);

  app.use(requestId);
  app.use(cors(corsOptions()));
  // Giữ body gốc cho webhook cổng thanh toán (SePay ký HMAC trên đúng các byte nhận được)
  app.use(express.json({
    limit: '256kb',
    verify: (req, _res, buf) => {
      if (req.url?.startsWith('/api/v1/payments/')) (req as typeof req & { rawBody?: Buffer }).rawBody = buf;
    },
  }));
  app.use(apiLogger);

  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
  app.use('/api/v1', apiRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
