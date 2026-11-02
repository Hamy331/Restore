import { Router } from 'express';
import knowledgeRouter from './routes/knowledge.route.js';
import mediaRouter from './routes/media.route.js';
import postRouter from './routes/post.route.js';
import reportRouter from './routes/report.route.js';
import ticketRouter from './routes/ticket.route.js';

/** Toàn bộ API /api/v1/content dành cho người dùng (quản trị nội dung vẫn ở /admin) */
export const contentRouter = Router();
contentRouter.use(mediaRouter);
contentRouter.use(postRouter);
contentRouter.use(knowledgeRouter);
contentRouter.use(reportRouter);
contentRouter.use(ticketRouter);
