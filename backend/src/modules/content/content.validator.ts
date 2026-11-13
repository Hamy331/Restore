import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { boolean, choice, object, page, text, version } from '../../common/validation/admin-input.js';
import { MEDIA_NAME, MEDIA_PREFIX, POST_STATUSES, REPORT_ACTIONS, REPORT_STATUSES, REPORT_TARGETS, TICKET_STATUSES } from './content.type.js';

/*
 * Schema đầu vào của module content. Bọc các hàm kiểm tra kiểu cũ trong common/validation/admin-input
 * (text, object, choice, page...) để giữ nguyên mã lỗi INVALID_ADMIN_INPUT / INVALID_QUERY.
 */

/** Bỏ dấu tiếng Việt, chữ thường: dùng để lập chỉ mục và tìm tài liệu kiến thức */
export const normalizeKnowledge = (value: string) =>
  value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();

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

/* ---------- Quản trị nội dung (/admin/posts, tickets, knowledge, reports) ---------- */

/**
 * Body POST /admin/posts, PUT /admin/posts/:id.
 * updatedAt để nguyên: chỉ PUT dùng, và chỉ kiểm tra sau khi đã kiểm tra tin liên quan (như API cũ).
 */
export const postBody = z.unknown().transform((value) => {
  const body = object(value, ['title', 'slug', 'category', 'content', 'coverUrl', 'listingIds', 'status', 'updatedAt']);
  const title = text(body.title, 'title', 5, 160), slug = text(body.slug, 'slug', 3, 160);
  const category = text(body.category, 'category', 2, 100), content = text(body.content, 'content', 20, 50000);
  if (!/^[a-z0-9-]+$/.test(slug)) throw new AppError(400, 'INVALID_SLUG', 'Slug chỉ gồm chữ thường, số, dấu gạch ngang.');
  const status = choice(body.status, POST_STATUSES);
  const coverUrl = body.coverUrl ? text(body.coverUrl, 'coverUrl', 1, 300) : null;
  if (coverUrl && !(coverUrl.startsWith(MEDIA_PREFIX) && MEDIA_NAME.test(coverUrl.slice(MEDIA_PREFIX.length)))) {
    throw new AppError(400, 'INVALID_COVER', 'Chọn ảnh bìa đã tải lên hệ thống.');
  }
  if (!Array.isArray(body.listingIds) || body.listingIds.length > 10 || body.listingIds.some((id) => typeof id !== 'string' || id.length > 100)) {
    throw new AppError(400, 'INVALID_LISTINGS', 'Tối đa 10 tin liên quan.');
  }
  const listingIds = [...new Set(body.listingIds as string[])];
  return { data: { title, slug, category, content, coverUrl, listingIds, status }, updatedAt: body.updatedAt };
});

/** Body POST /admin/tickets/:id/reply */
export const adminTicketReplyBody = z.unknown().transform((value) => {
  const body = object(value, ['content', 'updatedAt']);
  return { content: text(body.content, 'content', 1, 4000), expected: version(body.updatedAt) };
});

/** Body POST /admin/tickets/:id/status */
export const ticketStatusBody = z.unknown().transform((value) => {
  const body = object(value, ['status', 'updatedAt']);
  return { status: choice(body.status, TICKET_STATUSES), expected: version(body.updatedAt) };
});

/** Body POST /admin/knowledge, PUT /admin/knowledge/:id (updatedAt chỉ PUT dùng) */
export const knowledgeBody = z.unknown().transform((value) => {
  const body = object(value, ['title', 'content', 'active', 'updatedAt']);
  return {
    data: { title: text(body.title, 'title', 3, 160), content: text(body.content, 'content', 10, 100000), active: boolean(body.active) },
    updatedAt: body.updatedAt,
  };
});

/** Body chỉ có updatedAt (lập chỉ mục, xóa tài liệu); kiểm tra updatedAt ở service để giữ thứ tự lỗi cũ */
export const versionBody = z.unknown().transform((value) => ({ updatedAt: object(value, ['updatedAt']).updatedAt }));

/** Query GET /admin/reports: page, status? */
export const adminReportQuery = z.record(z.string(), z.unknown()).transform((query) => {
  const current = page(query.page);
  return { page: current, status: query.status ? choice(query.status, REPORT_STATUSES) : undefined };
});

/**
 * Body POST /admin/reports/:id/resolve.
 * days, targetUpdatedAt để nguyên: chỉ kiểm tra khi hành động cần tới (sau khi đọc báo cáo), như API cũ.
 */
export const resolveReportBody = z.unknown().transform((value) => {
  const body = object(value, ['action', 'reason', 'days', 'updatedAt', 'targetUpdatedAt']);
  const action = choice(body.action, REPORT_ACTIONS);
  return {
    action, reason: text(body.reason, 'reason', 5, 300), expected: version(body.updatedAt),
    days: body.days, targetUpdatedAt: body.targetUpdatedAt,
  };
});

export const adminPostListQuery = z.record(z.string(), z.unknown()).transform(query => ({page:page(query.page), withAuthor:query.include === 'author'}));
