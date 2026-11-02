import { AppError } from '../errors/app-error.js';

/**
 * Hàm đọc và kiểm tra giá trị từ query/params/body.
 * Mỗi hàm nhận giá trị thô, trả về giá trị đã làm sạch hoặc ném AppError 400.
 */

const invalid = (field: string, message: string, code = 'INVALID_INPUT') =>
  new AppError(400, code, message, field);

/** Chuỗi bắt buộc, đã trim, độ dài trong [min, max] */
export function requiredString(value: unknown, field: string, { min = 1, max = 255 } = {}): string {
  if (typeof value !== 'string' || value.trim().length < min || value.trim().length > max) {
    throw invalid(field, `${field} phải là chuỗi từ ${min} đến ${max} ký tự.`);
  }
  return value.trim();
}

/** Chuỗi không bắt buộc; chuỗi rỗng coi như không truyền */
export function optionalString(value: unknown, field: string, { max = 255 } = {}): string | undefined {
  if (value === undefined || value === null || value === '') return undefined;
  return requiredString(value, field, { min: 1, max });
}

/** Số nguyên dương trong [min, max], nhận cả chuỗi số từ query */
export function integerInRange(
  value: unknown,
  field: string,
  { min, max, fallback }: { min: number; max: number; fallback?: number },
): number {
  if (value === undefined || value === '') {
    if (fallback !== undefined) return fallback;
    throw invalid(field, `Thiếu ${field}.`);
  }
  const parsed = typeof value === 'number' ? value : typeof value === 'string' && /^-?\d+$/.test(value) ? Number(value) : NaN;
  if (!Number.isSafeInteger(parsed) || parsed < min || parsed > max) {
    throw invalid(field, `${field} phải là số nguyên từ ${min} đến ${max}.`);
  }
  return parsed;
}

/** Giá trị nằm trong danh sách cho phép */
export function oneOf<T extends string>(value: unknown, field: string, allowed: readonly T[], fallback?: T): T {
  if ((value === undefined || value === '') && fallback !== undefined) return fallback;
  if (typeof value !== 'string' || !allowed.includes(value as T)) {
    throw invalid(field, `${field} chỉ nhận: ${allowed.join(', ')}.`);
  }
  return value as T;
}

export function optionalBoolean(value: unknown, field: string): boolean | undefined {
  if (value === undefined || value === null || value === '') return undefined;
  if (value === true || value === 'true') return true;
  if (value === false || value === 'false') return false;
  throw invalid(field, `${field} chỉ nhận true hoặc false.`);
}

/** Ngày giờ ISO 8601 không bắt buộc */
export function optionalDate(value: unknown, field: string): Date | null | undefined {
  if (value === undefined) return undefined;
  if (value === null || value === '') return null;
  const date = typeof value === 'string' ? new Date(value) : null;
  if (!date || Number.isNaN(date.getTime())) throw invalid(field, `${field} phải là ngày giờ ISO 8601.`);
  return date;
}

/** Cặp tọa độ GPS không bắt buộc; nếu có thì phải đủ cả hai */
export function optionalCoordinates(latitude: unknown, longitude: unknown) {
  const hasLat = latitude !== undefined && latitude !== '';
  const hasLng = longitude !== undefined && longitude !== '';
  if (!hasLat && !hasLng) return undefined;
  const lat = Number(latitude);
  const lng = Number(longitude);
  if (!hasLat || !hasLng || !Number.isFinite(lat) || !Number.isFinite(lng) ||
      lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    throw invalid('location', 'Cần đủ latitude và longitude hợp lệ.', 'INVALID_LOCATION');
  }
  return { latitude: lat, longitude: lng };
}

/** Đảm bảo body là object JSON và không có trường lạ */
export function jsonObject(value: unknown, allowedKeys: readonly string[]): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw invalid('body', 'Body phải là một object JSON.');
  }
  const unknownKey = Object.keys(value).find((key) => !allowedKeys.includes(key));
  if (unknownKey) throw invalid(unknownKey, `Trường ${unknownKey} không được hỗ trợ.`);
  return value as Record<string, unknown>;
}
