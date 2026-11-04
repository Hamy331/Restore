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
    origin(origin, callback) {
      const isLocalDevelopmentOrigin =
        process.env.NODE_ENV !== 'production' && !!origin && /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
      callback(null, !origin || isLocalDevelopmentOrigin || (allowedOrigins?.includes(origin) ?? false));
    },
  };
}

export function createApp() {
  const app = express();

  app.use(requestId);
  app.use(cors(corsOptions()));
  app.use(express.json({ limit: '256kb' }));
  app.use(apiLogger);

  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
  app.use('/api/v1', apiRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
