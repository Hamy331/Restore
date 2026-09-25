import express from 'express';
import { apiLogger } from './middlewares/logger.middleware.js';
import authRouter from './modules/auth/auth.route.js';

const app = express();

app.use(express.json());
app.use(apiLogger); 

app.use('/api/v1/auth', authRouter);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Restore Backend đang chạy tại http://localhost:${PORT}`);
});