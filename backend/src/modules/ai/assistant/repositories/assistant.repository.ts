import { randomUUID } from 'node:crypto';
import type { Prisma } from '@prisma/client';
import { prisma } from '../../../../lib/prisma.js';
import { AppError } from '../../../../common/errors/app-error.js';
import { withQuotaTransaction } from '../../../commerce/index.js';
import type { AssistantReply, Content } from '../assistant.type.js';
import { redact, redactValue } from '../../../../common/security/redaction.js';

const json = (value: unknown) => JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;
const missing = () => new AppError(404, 'AI_CONVERSATION_NOT_FOUND', 'Không tìm thấy cuộc trò chuyện.');

export async function owned(userId: string, id: string) {
  const row = await prisma.aiConversation.findFirst({ where: { id, userId } });
  if (!row) throw missing();
  return row;
}

export async function begin(userId: string, id: string, requestId: string, input: string) {
  input = redact(input);
  return withQuotaTransaction(async (tx) => {
    const now = new Date();
    const conversation = await tx.aiConversation.upsert({ where: { id }, create: { id, userId }, update: {} });
    if (conversation.userId !== userId) throw missing();
    const previous = await tx.aiTurn.findUnique({ where: { conversationId_requestId: { conversationId: id, requestId } } });
    if (previous) {
      if (previous.input !== input) throw new AppError(409, 'AI_REQUEST_CHANGED', 'Mã yêu cầu đã được dùng cho nội dung khác.');
      return { cached: previous.response as unknown as AssistantReply, lease: null };
    }
    if (conversation.busyUntil && conversation.busyUntil > now) throw new AppError(409, 'AI_BUSY', 'Hội thoại đang xử lý. Vui lòng thử lại sau.');
    const rapidTurns = await tx.aiTurn.count({ where: { conversation: { userId }, createdAt: { gt: new Date(+now - 10_000) } } });
    if (rapidTurns >= 5) throw new AppError(429, 'AI_RATE_LIMIT', 'Bạn gửi hơi nhanh. Hãy đợi khoảng 10 giây rồi thử lại nhé.');
    const usage = await tx.aiUsage.findUnique({ where: { userId } });
    const windowStart = usage && +now - +usage.windowStart < 600_000 ? usage.windowStart : now;
    const dayStart = new Date(now.toISOString().slice(0, 10));
    const windowCount = usage && +windowStart === +usage.windowStart ? usage.windowCount + 1 : 1;
    const dayCount = usage && +dayStart === +usage.dayStart ? usage.dayCount + 1 : 1;
    if (windowCount > 20 || dayCount > 100) throw new AppError(429, 'AI_RATE_LIMIT', 'Bạn đã đạt giới hạn AI (20 lượt/10 phút, 100 lượt/ngày).');
    const data = { windowStart, windowCount, dayStart, dayCount };
    await tx.aiUsage.upsert({ where: { userId }, create: { userId, ...data }, update: data });
    const lease = randomUUID();
    await tx.aiConversation.update({ where: { id }, data: { lease, busyUntil: new Date(+now + 120_000) } });
    return { cached: null, lease };
  });
}

export const recentTurns = (id: string) => prisma.aiTurn.findMany({ where: { conversationId: id }, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: 10 });

export async function finish(id: string, lease: string, requestId: string, input: string, response: AssistantReply, contents: Content[]) {
  input = redact(input);
  response = redactValue(response);
  contents = redactValue(contents);
  return prisma.$transaction(async (tx) => {
    const changed = await tx.aiConversation.updateMany({ where: { id, lease, busyUntil: { gt: new Date() } }, data: { lease: null, busyUntil: null } });
    if (!changed.count) throw new AppError(409, 'AI_LEASE_EXPIRED', 'Yêu cầu đã hết thời gian xử lý. Vui lòng thử lại.');
    await tx.aiTurn.create({ data: { conversationId: id, requestId, input, response: json(response), contents: json(contents) } });
    return response;
  });
}

export const release = (id: string, lease: string) => prisma.aiConversation.updateMany({ where: { id, lease }, data: { lease: null, busyUntil: null } });

export async function listRecent(userId: string) {
  const rows = await prisma.aiConversation.findMany({
    where: { userId, turns: { some: {} } },
    orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
    take: 30,
    select: {
      id: true, turns: {
        take: 1, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }], select: { input: true },
      },
    },
  });
  return rows.map(row => ({ id: row.id, title: redact(row.turns[0].input).slice(0, 120) }));
}

export async function history(userId: string, id: string) {
  await owned(userId, id);
  const turns = (await recentTurns(id)).reverse();
  return redactValue(turns.map(row => ({ requestId: row.requestId, input: row.input, response: row.response })));
}

export async function remove(userId: string, id: string) {
  return withQuotaTransaction(async (tx) => {
    const row = await tx.aiConversation.findFirst({ where: { id, userId } });
    if (!row) throw missing();
    if (row.busyUntil && row.busyUntil > new Date()) throw new AppError(409, 'AI_BUSY', 'Đợi câu trả lời xong trước khi xóa hội thoại.');
    await tx.aiConversation.delete({ where: { id } });
  });
}
