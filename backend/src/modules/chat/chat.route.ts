import { Router, Response, NextFunction } from 'express';
import { AuthRequest, verifyToken } from '../../middlewares/auth.middleware.js';
import * as chat from './chat.service.js';
import { publish, subscribe } from './chat.events.js';

const router = Router();
router.use(verifyToken);
const handle = (action: (req: AuthRequest) => Promise<unknown>, status = 200) =>
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try { res.status(status).json({ success: true, data: await action(req) }); }
    catch (error) { next(error); }
  };

router.get('/unread-count', handle((req) => chat.unreadCount(req.user!.userId)));
router.post('/heartbeat', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await chat.heartbeat(req.user!.userId);
    const presence = { userId: req.user!.userId, isOnline: true, lastActiveAt: result.lastActiveAt };
    publish(result.peers, 'presence', presence);
    res.json({ success: true, data: presence });
  } catch (error) { next(error); }
});
router.get('/events', (req: AuthRequest, res: Response) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();
  res.write(': connected\n\n');
  subscribe(req.user!.userId, res);
});
router.get('/', handle((req) => chat.listConversations(req.user!.userId)));
router.post('/', handle((req) => chat.startConversation(req.user!.userId, req.body), 201));
router.get('/:id', handle((req) => chat.getConversation(req.user!.userId, chat.parseConversationId(req.params.id))));
router.get('/:id/messages', handle((req) => chat.listMessages(
  req.user!.userId, chat.parseConversationId(req.params.id), req.query,
)));
router.post('/:id/messages', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = chat.parseConversationId(req.params.id);
    const result = await chat.sendMessage(req.user!.userId, id, req.body);
    if (result.created) {
      const members = await chat.conversationMembers(id);
      publish(members.map((member) => member.userId), 'message', result.message);
    }
    res.status(result.created ? 201 : 200).json({ success: true, data: result.message });
  } catch (error) { next(error); }
});
router.post('/:id/read', async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = chat.parseConversationId(req.params.id);
    const result = await chat.markRead(req.user!.userId, id);
    publish([req.user!.userId], 'read', { conversationId: id, ...result });
    res.json({ success: true, data: result });
  } catch (error) { next(error); }
});

export default router;
