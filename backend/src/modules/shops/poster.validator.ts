import { z } from 'zod';
import { int, oneOf, optionalIsoDate, optionalStr, str, strictBody } from '../../common/validation/schemas.js';
import { POSTER_RULES, REJECT_REASONS } from './poster.rules.js';

const days = (fallback?: number) => int('days', { min: POSTER_RULES.minDays, max: POSTER_RULES.maxDays, fallback });

/** Gửi poster mới: title, imageUrl (ảnh tải lên qua /media/images?purpose=poster), listingId?, startsAt?, days */
export const posterCreateBody = strictBody({
  title: str('title', { max: 80 }),
  imageUrl: str('imageUrl', { max: 300 }),
  listingId: optionalStr('listingId', { max: 64 }),
  startsAt: optionalIsoDate('startsAt'),
  days: days(),
});

/** Trường không bắt buộc khi sửa: không gửi = giữ nguyên, có gửi thì kiểm tra như khi tạo */
const maybe = <S extends z.ZodType>(schema: S) =>
  z.unknown().optional().transform((value, ctx): z.output<S> | undefined => {
    if (value === undefined) return undefined;
    const result = schema.safeParse(value);
    if (result.success) return result.data;
    const issue = result.error.issues[0];
    ctx.addIssue({ code: 'custom', message: issue.message, params: issue.code === 'custom' ? issue.params : undefined });
    return z.NEVER;
  });

/** Sửa poster: mọi trường đều không bắt buộc; listingId null hoặc rỗng = mở trang shop */
export const posterUpdateBody = strictBody({
  title: maybe(str('title', { max: 80 })),
  imageUrl: maybe(str('imageUrl', { max: 300 })),
  listingId: z.unknown().optional().transform((value, ctx): string | null | undefined => {
    if (value === undefined) return undefined;
    if (value === null || value === '') return null;
    if (typeof value !== 'string' || value.trim().length > 64) {
      ctx.addIssue({ code: 'custom', message: 'listingId phải là chuỗi tối đa 64 ký tự.', params: { field: 'listingId' } });
      return z.NEVER;
    }
    return value.trim();
  }),
  startsAt: optionalIsoDate('startsAt'),
  days: maybe(days()),
});

/** Query danh sách duyệt của admin: status (mặc định PENDING) */
export const adminPosterQuery = z.object({
  status: oneOf('status', ['PENDING', 'APPROVED', 'REJECTED', 'STOPPED', 'ALL'] as const, 'PENDING'),
});

/** Admin từ chối: reason (bắt buộc), note (bắt buộc khi reason = OTHER) */
export const posterRejectBody = strictBody({
  reason: oneOf('reason', REJECT_REASONS),
  note: optionalStr('note', { max: 300 }),
});

export type PosterCreateBody = z.infer<typeof posterCreateBody>;
export type PosterUpdateBody = z.infer<typeof posterUpdateBody>;
export type AdminPosterQuery = z.infer<typeof adminPosterQuery>;
export type PosterRejectBody = z.infer<typeof posterRejectBody>;
