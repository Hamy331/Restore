import { parseConversationId } from '../chat.validator.js';
import { Response, NextFunction } from 'express';
import { AuthRequest } from '../../../middlewares/auth.middleware.js';
import * as chat from '../services/chat.service.js';
import { emit } from '../../../common/events/domain-events.js';

import { respondOffer, submitReview } from '../services/trade.service.js';
import { parseId } from '../chat.validator.js';

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
  const root = await chat.threadFor(id, req.user!.userId);
  const members = await chat.conversationMembers(root);
  for (const member of members) {
    chat.publishChange([member.userId], 'conversation.updated', root,
      member.userId === req.user!.userId ? data : {});
  }
  return data;
});

/** Người bán chấp nhận / từ chối, người mua thu hồi một đề nghị: { action: accept | reject | cancel } */
export const offerAction = handle((req) =>
  respondOffer(req.user!.userId, parseId(req.params.offerId, 'offerId'), req.body?.action),
);
export const review = handle((req) =>
  submitReview(req.user!.userId, parseConversationId(req.params.id), req.body),
);

export const unreadCount = handle((req) => chat.unreadCount(req.user!.userId));

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
      const root = await chat.threadFor(id, req.user!.userId);
      const members = await chat.conversationMembers(root);
      chat.publishChange(members.map(m => m.userId), 'message.created', root, { message: result.message });
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
    const root = await chat.threadFor(id, req.user!.userId);
    chat.publishChange([req.user!.userId], 'read', root, result);
    // Người còn lại thấy tin của họ chuyển sang "Đã xem"
    const peers = (await chat.conversationMembers(root)).map((m) => m.userId).filter((userId) => userId !== req.user!.userId);
    if (peers.length) chat.publishChange(peers, 'seen', root, result);
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};
