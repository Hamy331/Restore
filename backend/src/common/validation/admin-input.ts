import { AppError } from '../errors/app-error.js';

/*
 * Kiểm tra đầu vào kiểu cũ của các API quản trị (/admin/*), dùng trong transform của schema zod.
 * Giữ nguyên mã lỗi INVALID_ADMIN_INPUT / INVALID_QUERY / ADMIN_STALE mà app quản trị đang đọc.
 */

/** Số bản ghi mỗi trang ở các danh sách quản trị */
export const ADMIN_PAGE_SIZE = 25;

/** Chuỗi đã trim, dài [min, max] ký tự */
export function text(value: unknown, name: string, min = 1, max = 300) {
  if (typeof value !== 'string' || value.trim().length < min || value.trim().length > max) {
    throw new AppError(400, 'INVALID_ADMIN_INPUT', `${name}: cần ${min}–${max} ký tự.`, name);
  }
  return value.trim();
}

/** Object chỉ chứa các khóa trong [keys] */
export function object(value: unknown, keys: string[]) {
  if (!value || typeof value !== 'object' || Array.isArray(value) || Object.keys(value).some((key) => !keys.includes(key))) {
    throw new AppError(400, 'INVALID_ADMIN_INPUT', 'Dữ liệu chứa trường không hợp lệ.');
  }
  return value as Record<string, unknown>;
}

/** Một trong các giá trị [values] */
export function choice<T extends string>(value: unknown, values: readonly T[]): T {
  if (typeof value !== 'string' || !values.includes(value as T)) throw new AppError(400, 'INVALID_ADMIN_INPUT', 'Lựa chọn không hợp lệ.');
  return value as T;
}

/** Số nguyên trong [min, max] (kiểu number trong JSON, không nhận chuỗi) */
export function integer(value: unknown, min: number, max: number) {
  if (typeof value !== 'number' || !Number.isInteger(value) || value < min || value > max) {
    throw new AppError(400, 'INVALID_ADMIN_INPUT', `Số phải từ ${min} đến ${max}.`);
  }
  return value;
}

export function boolean(value: unknown) {
  if (typeof value !== 'boolean') throw new AppError(400, 'INVALID_ADMIN_INPUT', 'Trạng thái không hợp lệ.');
  return value;
}

/** updatedAt (ISO 8601) lúc admin đọc bản ghi, để chặn ghi đè */
export function version(value: unknown) {
  const date = new Date(text(value, 'updatedAt', 1, 40));
  if (Number.isNaN(+date)) throw new AppError(400, 'INVALID_ADMIN_INPUT', 'Phiên bản không hợp lệ.');
  return date;
}

/** 409 ADMIN_STALE khi cập nhật có điều kiện không đổi được dòng nào */
export function changed(count: number) {
  if (!count) throw new AppError(409, 'ADMIN_STALE', 'Dữ liệu đã đổi. Tải lại trước khi thao tác.');
}

/** Số trang từ query (mặc định 1) */
export function page(value: unknown) {
  if (value == null) return 1;
  if (typeof value !== 'string' || !/^[1-9]\d{0,5}$/.test(value)) throw new AppError(400, 'INVALID_QUERY', 'Trang không hợp lệ.');
  return Number(value);
}

/** Một trang danh sách quản trị: { items, total, page } */
export type AdminPage<T> = { items: T[]; total: number; page: number };
