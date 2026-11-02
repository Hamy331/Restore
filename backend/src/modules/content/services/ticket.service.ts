import { AppError } from '../../../common/errors/app-error.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import type { PageQuery, TicketInput } from '../content.dto.js';
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
