import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './config/swagger.js';
import { apiLogger } from './middlewares/logger.middleware.js';
import authRouter from './modules/auth/auth.route.js';
import { validateEnvironment } from './config/env.js';
import { errorHandler, notFoundHandler } from './middlewares/error.middleware.js';

validateEnvironment();

const app = express();

const allowedOrigins = process.env.CORS_ORIGINS
  ?.split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  cors({
    origin(origin, callback) {
      const isLocalDevelopmentOrigin =
        process.env.NODE_ENV !== 'production' &&
        !!origin &&
        /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
      const isAllowed =
        !origin ||
        isLocalDevelopmentOrigin ||
        (allowedOrigins?.includes(origin) ?? false);
      callback(null, isAllowed);
    },
  }),
);

app.use(express.json());
app.use(apiLogger);

// Swagger Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use('/api/v1/auth', authRouter);
app.use(notFoundHandler);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Restore Backend đang chạy tại http://localhost:${PORT}`);
});
