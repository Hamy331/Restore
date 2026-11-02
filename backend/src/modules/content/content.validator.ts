import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { choice, normalizeKnowledge, object, page, text } from '../admin/admin.service.js';
import { REPORT_TARGETS } from './content.type.js';

/*
 * Schema đầu vào của module content. Bọc các hàm kiểm tra dùng chung với admin
 * (text, object, choice, page) để giữ nguyên mã lỗi INVALID_ADMIN_INPUT / INVALID_QUERY.
 */

/** Query có page (từ 1) */
export const pageOnlyQuery = z.record(z.string(), z.unknown()).transform((query) => ({ page: page(query.page) }));

/** Query GET /knowledge/search: q (2-100 ký tự), đã bỏ dấu, chữ thường */
export const knowledgeSearchQuery = z.record(z.string(), z.unknown())
  .transform((query) => ({ q: normalizeKnowledge(text(query.q, 'q', 2, 100)) }));

/** Query POST /knowledge/upload: title (3-160 ký tự) */
export const knowledgeUploadQuery = z.record(z.string(), z.unknown())
  .transform((query) => ({ title: text(query.title, 'title', 3, 160) }));

/** Body POST /knowledge/upload: văn bản UTF-8 (.txt, .md), 10-100000 ký tự */
export const knowledgeUploadBody = z.unknown().transform((body) => {
  const content = text(body, 'content', 10, 100000);
  if (content.includes('\u0000')) throw new AppError(400, 'INVALID_DOCUMENT', 'Chỉ nhận văn bản UTF-8 (.txt, .md).');
  return { content };
});

/** Body POST /reports */
export const reportBody = z.unknown().transform((value) => {
  const body = object(value, ['targetType', 'targetId', 'reason', 'evidence']);
  return {
    targetType: choice(body.targetType, REPORT_TARGETS),
    targetId: text(body.targetId, 'targetId', 1, 100),
    reason: text(body.reason, 'reason', 5, 300),
    evidence: text(body.evidence, 'evidence', 5, 4000),
  };
});

/** Body POST /tickets */
export const ticketBody = z.unknown().transform((value) => {
  const body = object(value, ['subject', 'content']);
  return { subject: text(body.subject, 'subject', 5, 160), content: text(body.content, 'content', 5, 4000) };
});

/** Body POST /tickets/:id/reply */
export const ticketReplyBody = z.unknown().transform((value) => {
  const body = object(value, ['content']);
  return { content: text(body.content, 'content', 1, 4000) };
});

export const idParams = z.object({ id: z.string() });
export const slugParams = z.object({ slug: z.string() });
export const mediaParams = z.object({ filename: z.string() });
