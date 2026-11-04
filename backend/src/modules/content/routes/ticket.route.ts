import { Router } from 'express';
import { PERMISSION } from '../../../common/auth/permissions.js';
import { requirePermission } from '../../../middlewares/auth.middleware.js';
import { validate } from '../../../middlewares/validate.middleware.js';
import { idParams, pageOnlyQuery, ticketBody, ticketReplyBody } from '../content.validator.js';
import * as ticketController from '../controllers/ticket.controller.js';

/** Yêu cầu hỗ trợ của người dùng, gắn tại /api/v1/content */
const ticketRouter = Router();
const support = requirePermission(PERMISSION.SUPPORT_TICKET);

/**
 * Yêu cầu hỗ trợ của tôi kèm tin nhắn, cập nhật gần nhất trước, 20 mỗi trang
 *
 * Query params:
 *  - page?: number (mặc định 1)
 */
ticketRouter.get('/tickets', support, validate({ query: pageOnlyQuery }), ticketController.listMine);

/**
 * Gửi yêu cầu hỗ trợ mới
 *
 * Body:
 *  - subject: string (5-160)
 *  - content: string (5-4000) - tin nhắn đầu tiên
 */
ticketRouter.post('/tickets', support, validate({ body: ticketBody }), ticketController.create);

/**
 * Trả lời yêu cầu đang mở của tôi
 *
 * Path params:
 *  - id: string - mã yêu cầu
 *
 * Body:
 *  - content: string (1-4000)
 */
ticketRouter.post('/tickets/:id/reply', support, validate({ params: idParams, body: ticketReplyBody }), ticketController.reply);

export default ticketRouter;
