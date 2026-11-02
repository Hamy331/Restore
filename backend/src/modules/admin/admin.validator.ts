import { z } from 'zod';
import { choice, integer, object, page, text, version } from '../../common/validation/admin-input.js';
import { DEFAULT_SUSPEND_DAYS, USER_ACTIONS } from './admin.type.js';

/* Đầu vào của module admin; lỗi INVALID_ADMIN_INPUT / INVALID_QUERY như API cũ */

/** Query có page (từ 1) */
export const pageOnlyQuery = z.record(z.string(), z.unknown()).transform((query) => ({ page: page(query.page) }));

/**
 * Query GET /admin/users: q? tìm trong họ tên (đã trim, 1-100 ký tự) hoặc email (chuỗi gốc), page.
 * Email dùng chuỗi chưa trim như API cũ.
 */
export const userListQuery = z.record(z.string(), z.unknown()).transform((query) => ({
  q: query.q ? { name: text(query.q, 'q', 1, 100), email: String(query.q) } : undefined,
  page: page(query.page),
}));

/** Body POST /admin/users/:id/action */
export const userActionBody = z.unknown().transform((value) => {
  const body = object(value, ['action', 'reason', 'days', 'updatedAt']);
  return {
    action: choice(body.action, USER_ACTIONS),
    reason: text(body.reason, 'reason', 5, 300),
    days: integer(body.days ?? DEFAULT_SUSPEND_DAYS, 1, 365),
    expected: version(body.updatedAt),
  };
});

export const userIdParams = z.object({ id: z.string() });
