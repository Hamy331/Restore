import { parseConversationId } from '../chat.validator.js';
import { Response, NextFunction } from 'express';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import * as chat from '../services/chat.service.js';
import { publish, subscribe } from '../services/chat.events.js';
import { emit } from '../../../common/events/domain-events.js';

import { changeTrade, submitReview } from '../services/trade.service.js';

const handle =
  (action: (req: AuthRequest) => Promise<unknown>, status = 200) =>
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    try {
      res.status(status).json({ success: true, data: await action(req) });
    } catch (error) {
      next(error);
    }
  };

export const products = handle((req) => chat.discussed(req.user!.userId, parseConversationId(req.params.id)));
export const preferences = handle(async (req) => {
  const id = parseConversationId(req.params.id);
  const data = await chat.setPreference(req.user!.userId, id, req.body ?? {});
  const members = await chat.conversationMembers(id);
  publish(
    members.map((m) => m.userId),
    'message',
    { conversationId: id },
  );
  return data;
});

export const tradeAction = handle((req) =>
  changeTrade(req.user!.userId, parseConversationId(req.params.id), req.body?.action),
);
export const review = handle((req) =>
  submitReview(req.user!.userId, parseConversationId(req.params.id), req.body),
);

export const unreadCount = handle((req) => chat.unreadCount(req.user!.userId));

export const heartbeat = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const result = await chat.heartbeat(req.user!.userId);
    const presence = { userId: req.user!.userId, isOnline: true, lastActiveAt: result.lastActiveAt };
    publish(result.peers, 'presence', presence);
    res.json({ success: true, data: presence });
  } catch (error) {
    next(error);
  }
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

export const getConversation = handle((req) =>
  chat.getConversation(req.user!.userId, parseConversationId(req.params.id)),
);

export const listMessages = handle((req) =>
  chat.listMessages(req.user!.userId, parseConversationId(req.params.id), req.query),
);

export const sendMessage = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = parseConversationId(req.params.id);
    const result = await chat.sendMessage(req.user!.userId, id, req.body);
    if (result.created) {
      const members = await chat.conversationMembers(id);
      publish(
        members.map((member) => member.userId),
        'message',
        result.message,
      );
    }
    res.status(result.created ? 201 : 200).json({ success: true, data: result.message });
    // 3.2: push cho người còn lại (sau khi đã trả lời, lỗi push không ảnh hưởng tin nhắn)
    if (result.created) {
      const { message } = result;
      void emit('chat.messageSent', { conversationId: id, messageId: message.id, senderId: message.senderId, text: message.text });
    }
  } catch (error) {
    next(error);
  }
};

export const markRead = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = parseConversationId(req.params.id);
    const through = req.body?.through;
    const result = await chat.markRead(
      req.user!.userId,
      id,
      Number.isSafeInteger(through) && through >= 0 ? through : undefined,
    );
    publish([req.user!.userId], 'read', { conversationId: id, ...result });
    // Người còn lại thấy tin của họ chuyển sang "Đã xem"
    const peers = (await chat.conversationMembers(id)).map((m) => m.userId).filter((userId) => userId !== req.user!.userId);
    if (peers.length) publish(peers, 'seen', { conversationId: id, ...result });
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};
