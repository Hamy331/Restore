import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import {
  coordinates,
  idParam,
  int,
  optionalBool,
  optionalIsoDate,
  optionalStr,
  parse,
  str,
  strictBody,
} from '../../common/validation/schemas.js';

/** Query của GET /home/area */
export const areaQuery = z
  .object({ latitude: z.unknown().optional(), longitude: z.unknown().optional(), provinceCode: z.unknown().optional() })
  .transform((query) => ({
    point: parse(coordinates, query),
    provinceCode: parse(optionalStr('provinceCode', { max: 10 }), query.provinceCode),
  }));

/** Params `:id` của banner */
export const bannerIdParams = idParam(64);

/** Đường dẫn trong app phải bắt đầu bằng "/" (VD /trusted-shops?shop=abc) */
function appRoute(value: unknown) {
  const route = parse(optionalStr('route', { max: 200 }), value);
  if (route && !route.startsWith('/')) throw new AppError(400, 'INVALID_INPUT', 'route phải bắt đầu bằng "/".', 'route');
  return route;
}

/** Ảnh là URL http(s) hoặc đường dẫn tương đối của server */
function imageUrl(value: unknown) {
  const url = parse(optionalStr('imageUrl', { max: 500 }), value);
  if (url && !/^(https?:\/\/|\/)/.test(url)) {
    throw new AppError(400, 'INVALID_INPUT', 'imageUrl phải là URL http(s) hoặc đường dẫn bắt đầu bằng "/".', 'imageUrl');
  }
  return url;
}

const sent = z.unknown().optional();
const bannerFields = strictBody({
  title: sent, imageUrl: sent, route: sent, sortOrder: sent, active: sent, startsAt: sent, endsAt: sent, reason: sent,
});

/**
 * Body tạo/sửa banner. Kết quả: { data, reason }.
 * Khi sửa (partial = true) chỉ cập nhật trường được gửi; gửi null để xóa imageUrl/route/startsAt/endsAt.
 */
export const bannerBody = (partial: boolean) =>
  bannerFields.transform((body) => {
    const has = (key: keyof typeof body) => key in body;
    const data = {
      ...(!partial || has('title') ? { title: parse(str('title', { max: 120 }), body.title) } : {}),
      ...(has('imageUrl') ? { imageUrl: imageUrl(body.imageUrl) ?? null } : {}),
      ...(has('route') ? { route: appRoute(body.route) ?? null } : {}),
      ...(has('sortOrder') ? { sortOrder: parse(int('sortOrder', { min: 0, max: 1000 }), body.sortOrder) } : {}),
      ...(has('active') ? { active: parse(optionalBool('active'), body.active) ?? true } : {}),
      ...(has('startsAt') ? { startsAt: parse(optionalIsoDate('startsAt'), body.startsAt) ?? null } : {}),
      ...(has('endsAt') ? { endsAt: parse(optionalIsoDate('endsAt'), body.endsAt) ?? null } : {}),
    };
    if (data.startsAt && data.endsAt && data.startsAt >= data.endsAt) {
      throw new AppError(400, 'INVALID_INPUT', 'endsAt phải sau startsAt.', 'endsAt');
    }
    if (partial && Object.keys(data).length === 0) {
      throw new AppError(400, 'INVALID_INPUT', 'Cần ít nhất một trường để cập nhật.');
    }
    return { data, reason: parse(optionalStr('reason', { max: 300 }), body.reason) ?? '' };
  });

export type BannerInput = z.output<ReturnType<typeof bannerBody>>;
