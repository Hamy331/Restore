import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import swaggerUi from 'swagger-ui-express';
import { swaggerSpec } from './config/swagger.js';
import { apiLogger } from './middlewares/logger.middleware.js';
import authRouter from './modules/auth/auth.route.js';

const app = express();

app.use(cors());

app.use(express.json());
app.use(apiLogger);

// Swagger Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use('/api/v1/auth', authRouter);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Restore Backend đang chạy tại http://localhost:${PORT}`);
});