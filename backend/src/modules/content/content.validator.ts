import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { boolean, choice, object, page, text, version } from '../../common/validation/admin-input.js';
import { MEDIA_NAME, MEDIA_PREFIX, REPORT_ACTIONS, REPORT_STATUSES, REPORT_TARGETS, TICKET_STATUSES } from './content.type.js';
import { ADMIN_PAGE_SIZE } from '../../common/validation/admin-input.js';

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
  const body = object(value, ['targetType', 'targetId', 'reason', 'evidence', 'reasonCode', 'contactPhone', 'contactEmail']);
  const targetType = choice(body.targetType, REPORT_TARGETS);
  const targetId = text(body.targetId, 'targetId', 1, 100);
  if (body.reasonCode !== undefined) {
    if (targetType !== 'LISTING') throw new AppError(400, 'INVALID_REPORT', 'Lý do này chỉ dùng cho tin đăng.', 'reasonCode');
    const reasonCode = text(body.reasonCode, 'reasonCode', 1, 80);
    const contactEmail = text(body.contactEmail, 'contactEmail', 3, 254).toLowerCase();
    if (!z.email().safeParse(contactEmail).success) {
      throw new AppError(400, 'INVALID_REPORT_EMAIL', 'Email liên hệ không hợp lệ.', 'contactEmail');
    }
    const phone = text(body.contactPhone, 'contactPhone', 8, 30);
    if (!/^\+?[0-9\s().-]+$/.test(phone)) {
      throw new AppError(400, 'INVALID_REPORT_PHONE', 'Số điện thoại liên hệ không hợp lệ.', 'contactPhone');
    }
    const contactPhone = phone.replace(/[\s().-]/g, '');
    if (!/^\+?[0-9]{8,15}$/.test(contactPhone)) {
      throw new AppError(400, 'INVALID_REPORT_PHONE', 'Số điện thoại cần 8–15 chữ số.', 'contactPhone');
    }
    const evidence = text(body.evidence ?? '', 'evidence', 0, 4000);
    return { targetType, targetId, reason: undefined, evidence, reasonCode, contactPhone, contactEmail };
  }
  if (body.contactPhone !== undefined || body.contactEmail !== undefined) {
    throw new AppError(400, 'INVALID_REPORT', 'Thông tin liên hệ cần đi kèm mã lý do.', 'reasonCode');
  }
  return {
    targetType,
    targetId,
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

/* ---------- Quản trị nội dung (tickets, knowledge, reports) ---------- */
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
  const status = query.status ? choice(query.status, REPORT_STATUSES) : undefined;
  const hours = (key: string) => {
    if (query[key] === undefined || query[key] === '') return undefined;
    const raw = query[key];
    const value = typeof raw === 'string' && /^\d+(\.\d+)?$/.test(raw) ? Number(raw) : NaN;
    if (!Number.isFinite(value) || value < 0 || value * 3_600_000 > 8.64e15) {
      throw new AppError(400, 'INVALID_QUERY', 'Số giờ chờ không hợp lệ.', key);
    }
    return value;
  };
  const minWaitHours = hours('minWaitHours'), maxWaitHours = hours('maxWaitHours');
  let asOf: Date | undefined;
  if (query.asOf !== undefined) {
    if (typeof query.asOf !== 'string' || !z.iso.datetime().safeParse(query.asOf).success) {
      throw new AppError(400, 'INVALID_QUERY', 'Mốc thời gian không hợp lệ.', 'asOf');
    }
    asOf = new Date(query.asOf);
    if (asOf.getTime() > Date.now()) throw new AppError(400, 'INVALID_QUERY', 'Không dùng mốc thời gian trong tương lai.', 'asOf');
  }
  if (query.uncategorized !== undefined && query.uncategorized !== 'true' && query.uncategorized !== 'false') {
    throw new AppError(400, 'INVALID_QUERY', 'Bộ lọc báo cáo cũ không hợp lệ.');
  }
  if (query.uncategorized === 'true' && query.reasonCode) {
    throw new AppError(400, 'INVALID_QUERY', 'Không kết hợp mã lý do và báo cáo chưa phân loại.');
  }
  if ((minWaitHours !== undefined || maxWaitHours !== undefined) && status !== 'OPEN') {
    throw new AppError(400, 'INVALID_QUERY', 'Thời gian chờ chỉ áp dụng cho báo cáo đang mở.');
  }
  if (minWaitHours !== undefined && maxWaitHours !== undefined && minWaitHours > maxWaitHours) {
    throw new AppError(400, 'INVALID_QUERY', 'Số giờ chờ tối thiểu phải nhỏ hơn hoặc bằng tối đa.');
  }
  const limit = query.limit === undefined ? ADMIN_PAGE_SIZE : Number(query.limit);
  if (!Number.isInteger(limit) || limit < 1 || limit > 100) throw new AppError(400, 'INVALID_QUERY', 'Kích thước trang từ 1 đến 100.');
  return {
    page: current, status, limit, minWaitHours, maxWaitHours, asOf,
    reasonCode: query.reasonCode ? text(query.reasonCode, 'reasonCode', 1, 80) : undefined,
    uncategorized: query.uncategorized === 'true',
    targetType: query.targetType ? choice(query.targetType, REPORT_TARGETS) : undefined,
    targetId: query.targetId ? text(query.targetId, 'targetId', 1, 100) : undefined,
    sort: query.sort ? choice(query.sort, ['oldest', 'newest', 'most_reports'] as const) : 'oldest' as const,
  };
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

/** Query GET /admin/tickets: page, status? (OPEN | RESOLVED; giá trị khác coi như tất cả) */
export const adminTicketListQuery = z.record(z.string(), z.unknown()).transform((query) => ({
  page: page(query.page),
  status: query.status === 'OPEN' || query.status === 'RESOLVED' ? query.status : undefined,
}));
