import { AppError } from '../../common/errors/app-error.js';
import {
  integerInRange,
  jsonObject,
  optionalBoolean,
  optionalCoordinates,
  optionalDate,
  optionalString,
  requiredString,
} from '../../common/validation/parsers.js';

/** Query của GET /home/area */
export function parseAreaQuery(query: Record<string, unknown>) {
  return {
    point: optionalCoordinates(query.latitude, query.longitude),
    provinceCode: optionalString(query.provinceCode, 'provinceCode', { max: 10 }),
  };
}

export function parseBannerId(params: Record<string, unknown>) {
  return { id: requiredString(params.id, 'id', { max: 64 }) };
}

/** Đường dẫn trong app phải bắt đầu bằng "/" (VD /trusted-shops?shop=abc) */
function appRoute(value: unknown) {
  const route = optionalString(value, 'route', { max: 200 });
  if (route && !route.startsWith('/')) throw new AppError(400, 'INVALID_INPUT', 'route phải bắt đầu bằng "/".', 'route');
  return route;
}

/** Ảnh là URL http(s) hoặc đường dẫn tương đối của server */
function imageUrl(value: unknown) {
  const url = optionalString(value, 'imageUrl', { max: 500 });
  if (url && !/^(https?:\/\/|\/)/.test(url)) {
    throw new AppError(400, 'INVALID_INPUT', 'imageUrl phải là URL http(s) hoặc đường dẫn bắt đầu bằng "/".', 'imageUrl');
  }
  return url;
}

const bannerKeys = ['title', 'imageUrl', 'route', 'sortOrder', 'active', 'startsAt', 'endsAt', 'reason'] as const;

/**
 * Body tạo/sửa banner.
 * Khi sửa ([partial] = true) chỉ cập nhật trường được gửi; gửi null để xóa imageUrl/route/startsAt/endsAt.
 */
export function parseBannerBody(partial: boolean) {
  return (value: unknown) => {
    const body = jsonObject(value, bannerKeys);
    const has = (key: string) => key in body;
    const data = {
      ...(!partial || has('title') ? { title: requiredString(body.title, 'title', { max: 120 }) } : {}),
      ...(has('imageUrl') ? { imageUrl: imageUrl(body.imageUrl) ?? null } : {}),
      ...(has('route') ? { route: appRoute(body.route) ?? null } : {}),
      ...(has('sortOrder') ? { sortOrder: integerInRange(body.sortOrder, 'sortOrder', { min: 0, max: 1000 }) } : {}),
      ...(has('active') ? { active: optionalBoolean(body.active, 'active') ?? true } : {}),
      ...(has('startsAt') ? { startsAt: optionalDate(body.startsAt, 'startsAt') ?? null } : {}),
      ...(has('endsAt') ? { endsAt: optionalDate(body.endsAt, 'endsAt') ?? null } : {}),
    };
    if (data.startsAt && data.endsAt && data.startsAt >= data.endsAt) {
      throw new AppError(400, 'INVALID_INPUT', 'endsAt phải sau startsAt.', 'endsAt');
    }
    if (partial && Object.keys(data).length === 0) {
      throw new AppError(400, 'INVALID_INPUT', 'Cần ít nhất một trường để cập nhật.');
    }
    return { data, reason: optionalString(body.reason, 'reason', { max: 300 }) ?? '' };
  };
}

export type BannerInput = ReturnType<ReturnType<typeof parseBannerBody>>;
