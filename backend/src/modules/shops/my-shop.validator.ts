import { z } from 'zod';
import { optionalStr, str, strictBody } from '../../common/validation/schemas.js';

/** Giới hạn độ dài các trường của shop */
export const SHOP_LIMITS = { name: [2, 60], tagline: 80, description: 1000, address: 120, url: 300 } as const;

const fail = (ctx: z.RefinementCtx, field: string, message: string) => {
  ctx.addIssue({ code: 'custom', message, params: { field } });
  return z.NEVER;
};

/** Trường sửa được và xoá được: không gửi = giữ nguyên, null hoặc "" = xoá, chuỗi thì trim và kiểm tra độ dài */
const clearable = (field: string, max: number, pattern?: { regex: RegExp; message: string }) =>
  z.unknown().optional().transform((value, ctx): string | null | undefined => {
    if (value === undefined) return undefined;
    if (value === null || value === '') return null;
    if (typeof value !== 'string' || value.trim().length > max) {
      return fail(ctx, field, `${field} phải là chuỗi tối đa ${max} ký tự.`);
    }
    const text = value.trim();
    if (!text) return null;
    if (pattern && !pattern.regex.test(text)) return fail(ctx, field, pattern.message);
    return text;
  });

const name = () => str('name', { min: SHOP_LIMITS.name[0], max: SHOP_LIMITS.name[1] });

/** Chữ thường, bỏ dấu tiếng Việt (kể cả đ) */
const fold = (input: string) => input.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd');

/** Từ quảng cáo quá mức hoặc mạo danh (so khớp sau khi bỏ dấu) */
const BANNED_WORDS = /\b(so (1|mot)|top 1|no\.? ?1|tot nhat|re nhat|uy tin nhat|chinh hang|admin|restore)\b/;

/**
 * Tên shop bị chặn ngay khi lưu (theo quy định kiểm duyệt cửa hàng của Chợ Tốt): số điện thoại, đường dẫn web,
 * từ quảng cáo quá mức hoặc mạo danh. Trả về luật vi phạm, null = được. Phần còn lại admin duyệt tay.
 */
export function shopNameProblem(value: string): 'PHONE' | 'LINK' | 'WORDING' | null {
  if (/(\d[\s.-]?){9,}/.test(value)) return 'PHONE';
  if (/https?:\/\/|www\.|\.(com|vn|net|org|info|biz|shop|store)\b/i.test(value)) return 'LINK';
  return BANNED_WORDS.test(fold(value)) ? 'WORDING' : null;
}

/** Tạo shop (gói Cửa hàng): name, tagline?, description?, address? */
export const shopCreateBody = strictBody({
  name: name(),
  tagline: optionalStr('tagline', { max: SHOP_LIMITS.tagline }),
  description: optionalStr('description', { max: SHOP_LIMITS.description }),
  address: optionalStr('address', { max: SHOP_LIMITS.address }),
});

/**
 * Sửa shop: mọi trường không bắt buộc. logoUrl / coverUrl là ảnh tải lên qua /media/images?purpose=shop;
 * accentColor dạng "#RRGGBB". Gửi null hoặc "" để xoá (riêng name không xoá được).
 */
export const shopUpdateBody = strictBody({
  name: z.unknown().optional().transform((value, ctx): string | undefined => {
    if (value === undefined) return undefined;
    const result = name().safeParse(value);
    return result.success ? result.data : fail(ctx, 'name', result.error.issues[0].message);
  }),
  tagline: clearable('tagline', SHOP_LIMITS.tagline),
  description: clearable('description', SHOP_LIMITS.description),
  address: clearable('address', SHOP_LIMITS.address),
  logoUrl: clearable('logoUrl', SHOP_LIMITS.url),
  coverUrl: clearable('coverUrl', SHOP_LIMITS.url),
  accentColor: clearable('accentColor', 7, { regex: /^#[0-9A-Fa-f]{6}$/, message: 'accentColor phải có dạng #RRGGBB.' }),
});

export type ShopCreateBody = z.infer<typeof shopCreateBody>;
export type ShopUpdateBody = z.infer<typeof shopUpdateBody>;
