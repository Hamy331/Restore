import type { z } from 'zod';
import type {
  knowledgeSearchQuery, knowledgeUploadBody, knowledgeUploadQuery, pageOnlyQuery, reportBody, ticketBody, ticketReplyBody,
} from './content.validator.js';

/* Vào (suy ra từ schema). Kết quả trả ra là bản ghi Prisma, giữ nguyên như API cũ. */

export type PageQuery = z.output<typeof pageOnlyQuery>;
export type KnowledgeSearchQuery = z.output<typeof knowledgeSearchQuery>;
export type KnowledgeUploadQuery = z.output<typeof knowledgeUploadQuery>;
export type KnowledgeUploadBody = z.output<typeof knowledgeUploadBody>;
export type ReportInput = z.output<typeof reportBody>;
export type TicketInput = z.output<typeof ticketBody>;
export type TicketReplyInput = z.output<typeof ticketReplyBody>;
