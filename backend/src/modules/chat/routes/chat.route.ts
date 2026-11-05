import { Router } from 'express';
import { verifyToken } from '../../../middlewares/auth.middleware.js';
import * as controller from '../controllers/chat.controller.js';

const router = Router();
router.use(verifyToken);
router.get('/unread-count', controller.unreadCount);
router.post('/heartbeat', controller.heartbeat);
router.get('/events', controller.events);
router.get('/', controller.listConversations);
router.post('/', controller.startConversation);
router.get('/:id', controller.getConversation);
router.get('/:id/messages', controller.listMessages);
router.post('/:id/messages', controller.sendMessage);
router.post('/:id/read', controller.markRead);
export default router;
