import { AppError } from '../../../common/errors/app-error.js';
import { audit } from '../../../common/audit/admin-audit.js';
import { ADMIN_PAGE_SIZE, changed } from '../../../common/validation/admin-input.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import type { AdminTicketReplyInput, PageQuery, TicketInput, TicketStatusInput } from '../content.dto.js';
import { PAGE_SIZE } from '../content.type.js';
import * as ticketRepository from '../repositories/ticket.repository.js';

/** Yêu cầu hỗ trợ của tôi kèm toàn bộ tin nhắn, cập nhật gần nhất trước */
export const listMine = (userId: string, { page }: PageQuery) =>
  ticketRepository.findMine(userId, (page - 1) * PAGE_SIZE, PAGE_SIZE);

export const create = (userId: string, { subject, content }: TicketInput) =>
  ticketRepository.createWithMessage(userId, subject, content);

/** Trả lời yêu cầu đang mở của tôi */
export function reply(userId: string, id: string, content: string) {
  return withQuotaTransaction(async (tx) => {
    const ticket = await ticketRepository.findOpenOf(tx, id, userId);
    if (!ticket) throw new AppError(404, 'TICKET_NOT_FOUND', 'Không tìm thấy yêu cầu đang mở của bạn.');
    await ticketRepository.touch(tx, ticket.id);
    return ticketRepository.createUserMessage(tx, ticket.id, userId, content);
  });
}

/* ---------- Quản trị (/admin/tickets) ---------- */

/** Mọi yêu cầu hỗ trợ kèm tin nhắn, 25 mỗi trang */
export async function listForAdmin({ page }: PageQuery) {
  const [items, total] = await ticketRepository.findPage((page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  return { items, total, page };
}

/** Admin trả lời yêu cầu đang mở (updatedAt phải khớp), ghi AdminAudit */
export function adminReply(actorId: string, id: string, { content, expected }: AdminTicketReplyInput) {
  return withQuotaTransaction(async (tx) => {
    changed(await ticketRepository.touchOpenWhereVersion(tx, id, expected));
    const message = await ticketRepository.createAdminMessage(tx, id, actorId, content);
    await audit(tx, actorId, 'REPLY', 'TICKET', id, 'Phản hồi hỗ trợ');
    return message;
  });
}

/** Mở lại / đóng yêu cầu (updatedAt phải khớp), ghi AdminAudit */
export function setStatus(actorId: string, id: string, { status, expected }: TicketStatusInput) {
  return withQuotaTransaction(async (tx) => {
    changed(await ticketRepository.setStatusWhereVersion(tx, id, expected, status));
    await audit(tx, actorId, status, 'TICKET', id, 'Cập nhật trạng thái hỗ trợ');
    return { updated: true };
  });
}
