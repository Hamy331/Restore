import type { z } from 'zod';
import type {
  adminPostListQuery, adminReportQuery, adminTicketReplyBody, knowledgeBody, postBody, resolveReportBody, ticketStatusBody, versionBody,
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

export type PostInput = z.output<typeof postBody>;
export type AdminTicketReplyInput = z.output<typeof adminTicketReplyBody>;
export type TicketStatusInput = z.output<typeof ticketStatusBody>;
export type KnowledgeInput = z.output<typeof knowledgeBody>;
export type VersionInput = z.output<typeof versionBody>;
export type AdminReportQuery = z.output<typeof adminReportQuery>;
export type ResolveReportInput = z.output<typeof resolveReportBody>;

export type AdminPostListQuery = z.output<typeof adminPostListQuery>;
