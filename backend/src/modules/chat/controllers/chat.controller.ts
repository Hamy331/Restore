import { parseConversationId } from '../chat.validator.js';
import { Response, NextFunction } from 'express';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import * as chat from '../services/chat.service.js';
import { publish, subscribe } from '../services/chat.events.js';

const handle = (action: (req: AuthRequest) => Promise<unknown>, status = 200) =>
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try { res.status(status).json({ success: true, data: await action(req) }); }
    catch (error) { next(error); }
  };

export const unreadCount = handle((req) => chat.unreadCount(req.user!.userId));

export const heartbeat = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await chat.heartbeat(req.user!.userId);
    const presence = { userId: req.user!.userId, isOnline: true, lastActiveAt: result.lastActiveAt };
    publish(result.peers, 'presence', presence);
    res.json({ success: true, data: presence });
  } catch (error) { next(error); }
};

export const events = (req: AuthRequest, res: Response) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();
  res.write(': connected\n\n');
  subscribe(req.user!.userId, res);
};

export const listConversations = handle((req) => chat.listConversations(req.user!.userId));

export const startConversation = handle((req) => chat.startConversation(req.user!.userId, req.body), 201);

export const getConversation = handle((req) => chat.getConversation(req.user!.userId, parseConversationId(req.params.id)));

export const listMessages = handle((req) => chat.listMessages(
  req.user!.userId, parseConversationId(req.params.id), req.query,
));

export const sendMessage = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = parseConversationId(req.params.id);
    const result = await chat.sendMessage(req.user!.userId, id, req.body);
    if (result.created) {
      const members = await chat.conversationMembers(id);
      publish(members.map((member) => member.userId), 'message', result.message);
    }
    res.status(result.created ? 201 : 200).json({ success: true, data: result.message });
  } catch (error) { next(error); }
};

export const markRead = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = parseConversationId(req.params.id);
    const result = await chat.markRead(req.user!.userId, id);
    publish([req.user!.userId], 'read', { conversationId: id, ...result });
    res.json({ success: true, data: result });
  } catch (error) { next(error); }
};
