import { ListingCondition } from '@prisma/client';
import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { boolean, choice, object, text } from '../../common/validation/admin-input.js';
import { PROVINCES, WARDS } from './catalog.data.js';
import { LOCATION_KEYS } from './catalog.type.js';

/* ---------- Tọa độ, địa chỉ tin (dùng chung với listings, home) ---------- */

/** Tọa độ GPS hợp lệ (số hữu hạn, trong khoảng), sai thì 400 INVALID_LOCATION */
export function coordinates(latitude: unknown, longitude: unknown) {
  if (typeof latitude !== 'number' || typeof longitude !== 'number' || !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw new AppError(400, 'INVALID_LOCATION', 'Tọa độ không hợp lệ.', 'location');
  }
  return { latitude, longitude };
}

/**
 * Địa chỉ của tin: tỉnh + phường có trong dữ liệu, địa chỉ đường tối đa 200 ký tự,
 * tọa độ GPS thiết bị nếu gửi (không thì lấy tâm phường). null nếu không gửi.
 */
export function listingLocation(value: unknown) {
  if (value == null) return null;
  if (typeof value !== 'object' || Array.isArray(value)) throw new AppError(400, 'INVALID_LOCATION', 'Địa chỉ không hợp lệ.', 'location');
  const body = value as Record<string, unknown>;
  if (Object.keys(body).some((key) => !LOCATION_KEYS.includes(key))) {
    throw new AppError(400, 'INVALID_LOCATION', 'Địa chỉ chứa trường không được hỗ trợ.', 'location');
  }
  const province = PROVINCES.find((unit) => unit.code === body.provinceCode);
  const ward = province && WARDS[province.code]?.find((unit) => unit.code === body.wardCode);
  const streetAddress = body.streetAddress ?? '';
  if (!province || !ward || typeof streetAddress !== 'string' || streetAddress.trim().length > 200 ||
    !['device', 'ward_center'].includes(String(body.geoSource ?? 'ward_center'))) {
    throw new AppError(400, 'INVALID_LOCATION', 'Tỉnh/phường hoặc địa chỉ không hợp lệ.', 'location');
  }
  const hasPoint = body.latitude != null || body.longitude != null;
  const point = hasPoint ? coordinates(body.latitude, body.longitude) : ward.center;
  return {
    provinceCode: province.code, wardCode: ward.code, province, ward,
    streetAddress: streetAddress.trim(), ...point,
    geoSource: hasPoint && body.geoSource === 'device' ? 'device' : 'ward_center',
  };
}

export type ListingLocation = NonNullable<ReturnType<typeof listingLocation>>;

/* ---------- API công khai ---------- */

/** Query GET /locations/reverse-geocode: latitude, longitude (chuỗi số, bắt buộc cả hai) */
export const reverseGeocodeQuery = z.record(z.string(), z.unknown()).transform(({ latitude, longitude }) => {
  if (typeof latitude !== 'string' || typeof longitude !== 'string' || !latitude.trim() || !longitude.trim()) {
    throw new AppError(400, 'INVALID_LOCATION', 'Cần đủ tọa độ GPS.', 'location');
  }
  return coordinates(Number(latitude), Number(longitude));
});

export const provinceParams = z.object({ code: z.string() });

/* ---------- Quản trị ---------- */

/* Lỗi INVALID_ADMIN_INPUT như API cũ */

/** Body POST /admin/categories */
export const createCategoryBody = z.unknown().transform((value) => {
  const body = object(value, ['id', 'name', 'description', 'active']);
  const name = text(body.name, 'name', 2, 100), id = text(body.id, 'id', 2, 80);
  const description = text(body.description, 'description', 0, 500), active = boolean(body.active);
  if (!/^[a-z0-9-]+$/.test(id)) throw new AppError(400, 'INVALID_ID', 'Mã danh mục chỉ gồm chữ thường, số và dấu gạch ngang.');
  return { id, name, description, active };
});

/** Body PUT /admin/categories/:id */
export const updateCategoryBody = z.unknown().transform((value) => {
  const body = object(value, ['name', 'description', 'active']);
  return { name: text(body.name, 'name', 2, 100), description: text(body.description, 'description', 0, 500), active: boolean(body.active) };
});

/** Params PUT /admin/conditions/:condition */
export const conditionParams = z.record(z.string(), z.unknown())
  .transform((params) => ({ condition: choice(params.condition, Object.values(ListingCondition)) }));

/** Body PUT /admin/conditions/:condition */
export const conditionBody = z.unknown().transform((value) => {
  const body = object(value, ['name', 'active']);
  return { name: text(body.name, 'name', 2, 100), active: boolean(body.active) };
});

export const categoryIdParams = z.object({ id: z.string() });

export type CreateCategoryInput = z.output<typeof createCategoryBody>;
export type UpdateCategoryInput = z.output<typeof updateCategoryBody>;
export type ConditionParams = z.output<typeof conditionParams>;
export type ConditionInput = z.output<typeof conditionBody>;
export type ProvinceParams = z.output<typeof provinceParams>;
