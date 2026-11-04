import { z } from 'zod';
import { AppError } from '../errors/app-error.js';

/**
 * Schema zod dùng chung cho query/params/body.
 * Lỗi giữ nguyên message, code và field như các hàm trong parsers.ts,
 * để client nhận đúng JSON lỗi cũ: { success:false, error, code, field }.
 *
 * Dùng: parse(schema, req.query) → giá trị đã làm sạch, hoặc ném AppError 400.
 */

type IssueParams = { code?: string; field?: string };

function fail(ctx: z.RefinementCtx, field: string, message: string, code = 'INVALID_INPUT'): never {
  ctx.addIssue({ code: 'custom', message, params: { code, field } satisfies IssueParams });
  return z.NEVER as never;
}

const isBlank = (value: unknown) => value === undefined || value === '';

/** Chuỗi bắt buộc, đã trim, độ dài trong [min, max] */
export const str = (field: string, { min = 1, max = 255 } = {}) =>
  z.unknown().optional().transform((value, ctx): string => {
    if (typeof value !== 'string' || value.trim().length < min || value.trim().length > max) {
      return fail(ctx, field, `${field} phải là chuỗi từ ${min} đến ${max} ký tự.`);
    }
    return value.trim();
  });

/** Chuỗi không bắt buộc; null hoặc chuỗi rỗng coi như không truyền */
export const optionalStr = (field: string, { max = 255 } = {}) =>
  z.unknown().optional().transform((value, ctx): string | undefined => {
    if (value === undefined || value === null || value === '') return undefined;
    if (typeof value !== 'string' || value.trim().length < 1 || value.trim().length > max) {
      return fail(ctx, field, `${field} phải là chuỗi từ 1 đến ${max} ký tự.`);
    }
    return value.trim();
  });

/** Số nguyên trong [min, max], nhận cả chuỗi số từ query; thiếu thì dùng fallback */
export const int = (field: string, { min, max, fallback }: { min: number; max: number; fallback?: number }) =>
  z.unknown().optional().transform((value, ctx): number => {
    if (isBlank(value)) return fallback ?? fail(ctx, field, `Thiếu ${field}.`);
    const parsed = typeof value === 'number' ? value
      : typeof value === 'string' && /^-?\d+$/.test(value) ? Number(value) : NaN;
    if (!Number.isSafeInteger(parsed) || parsed < min || parsed > max) {
      return fail(ctx, field, `${field} phải là số nguyên từ ${min} đến ${max}.`);
    }
    return parsed;
  });

/** Giá trị nằm trong danh sách cho phép; thiếu thì dùng fallback */
export const oneOf = <T extends string>(field: string, allowed: readonly T[], fallback?: T) =>
  z.unknown().optional().transform((value, ctx): T => {
    if (isBlank(value) && fallback !== undefined) return fallback;
    if (typeof value !== 'string' || !allowed.includes(value as T)) {
      return fail(ctx, field, `${field} chỉ nhận: ${allowed.join(', ')}.`);
    }
    return value as T;
  });

/** true/false hoặc "true"/"false"; null hoặc rỗng coi như không truyền */
export const optionalBool = (field: string) =>
  z.unknown().optional().transform((value, ctx): boolean | undefined => {
    if (value === undefined || value === null || value === '') return undefined;
    if (value === true || value === 'true') return true;
    if (value === false || value === 'false') return false;
    return fail(ctx, field, `${field} chỉ nhận true hoặc false.`);
  });

/** Ngày giờ ISO 8601: undefined = không đổi, null/rỗng = xóa */
export const optionalIsoDate = (field: string) =>
  z.unknown().optional().transform((value, ctx): Date | null | undefined => {
    if (value === undefined) return undefined;
    if (value === null || value === '') return null;
    const date = typeof value === 'string' ? new Date(value) : null;
    if (!date || Number.isNaN(date.getTime())) return fail(ctx, field, `${field} phải là ngày giờ ISO 8601.`);
    return date;
  });

/**
 * Query phân trang: page (từ 1) và limit. `pageSize` là tên cũ của `limit`.
 * Kết quả: { page, limit, skip }.
 */
export const pageQuery = ({ defaultLimit = 10, maxLimit = 50 } = {}) =>
  z.object({ page: z.unknown().optional(), limit: z.unknown().optional(), pageSize: z.unknown().optional() }).transform((query, ctx) => {
    const page = int('page', { min: 1, max: 100_000, fallback: 1 }).safeParse(query.page);
    if (!page.success) return fail(ctx, 'page', page.error.issues[0].message);
    const limit = int('limit', { min: 1, max: maxLimit, fallback: defaultLimit }).safeParse(query.limit ?? query.pageSize);
    if (!limit.success) return fail(ctx, 'limit', limit.error.issues[0].message);
    return { page: page.data, limit: limit.data, skip: (page.data - 1) * limit.data };
  });

/**
 * Cặp tọa độ GPS không bắt buộc (latitude, longitude); nếu có thì phải đủ cả hai.
 * Kết quả: { latitude, longitude } hoặc undefined.
 */
export const coordinates = z
  .object({ latitude: z.unknown().optional(), longitude: z.unknown().optional() })
  .transform(({ latitude, longitude }, ctx) => {
    const hasLat = !isBlank(latitude), hasLng = !isBlank(longitude);
    if (!hasLat && !hasLng) return undefined;
    const lat = Number(latitude), lng = Number(longitude);
    if (!hasLat || !hasLng || !Number.isFinite(lat) || !Number.isFinite(lng) ||
        lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return fail(ctx, 'location', 'Cần đủ latitude và longitude hợp lệ.', 'INVALID_LOCATION');
    }
    return { latitude: lat, longitude: lng };
  });

/** Params có `:id` (chuỗi 1–max ký tự) */
export const idParam = (max = 64) => z.object({ id: str('id', { max }) });

/** Body JSON là object và không có trường lạ */
export const strictBody = <T extends z.ZodRawShape>(shape: T) =>
  z.strictObject(shape, {
    error: (issue) => issue.code === 'unrecognized_keys'
      ? `Trường ${issue.keys[0]} không được hỗ trợ.`
      : 'Body phải là một object JSON.',
  });

/** Đổi lỗi zod (issue đầu tiên) thành AppError 400 cùng code/field như trước */
export function toAppError(error: z.ZodError): AppError {
  const issue = error.issues[0];
  if (!issue) return new AppError(400, 'INVALID_INPUT', 'Dữ liệu không hợp lệ.');
  const params = (issue.code === 'custom' ? issue.params : undefined) as IssueParams | undefined;
  const field = params?.field
    ?? (issue.code === 'unrecognized_keys' ? issue.keys[0] : undefined)
    ?? (issue.path.length ? issue.path.join('.') : 'body');
  return new AppError(400, params?.code ?? 'INVALID_INPUT', issue.message, field);
}

/** Parse giá trị theo schema; sai thì ném AppError 400 */
export function parse<S extends z.ZodType>(schema: S, value: unknown): z.output<S> {
  const result = schema.safeParse(value);
  if (!result.success) throw toAppError(result.error);
  return result.data;
}
