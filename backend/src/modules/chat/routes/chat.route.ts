import * as media from '../controllers/chat-media.controller.js';
import { Router, raw } from 'express';
import { rateLimit, authRateLimits } from '../../../middlewares/rate-limit.middleware.js';
import { type AuthRequest, verifyToken } from '../../../middlewares/auth.middleware.js';
import * as controller from '../controllers/chat.controller.js';

const router = Router();
const limitSends = rateLimit([{
  name: 'chat-send', limit: 30, windowMs: 60_000,
  key: (req: AuthRequest) => req.user?.userId,
  message: 'Bạn gửi tin quá nhanh.',
}], authRateLimits.store);
router.get('/media/file', media.readMedia);
router.use(verifyToken);
router.get('/:id/products', controller.products);
router.patch('/:id/preferences', controller.preferences);
router.post('/:id/media', limitSends, raw({ type: 'application/octet-stream', limit: '25mb' }), media.sendMedia);
router.get('/:id/media/:messageId/link', media.mediaLink);
router.get('/unread-count', controller.unreadCount);
router.get('/', controller.listConversations);
router.post('/', controller.startConversation);
router.get('/:id', controller.getConversation);
router.get('/:id/messages', controller.listMessages);
router.post('/:id/messages', limitSends, controller.sendMessage);
router.post('/:id/offers/:offerId', controller.offerAction);
router.post('/:id/review', controller.review);
router.post('/:id/read', controller.markRead);
export default router;
