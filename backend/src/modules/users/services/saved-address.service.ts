import { AppError } from '../../../common/errors/app-error.js';
import { findProvince, findWard, listingLocation, type ListingLocation } from '../../catalog/index.js';
import * as repository from '../repositories/saved-address.repository.js';
import type { SavedAddressRow } from '../repositories/saved-address.repository.js';

/** Mỗi người lưu tối đa 5 địa chỉ; lưu thêm thì bỏ địa chỉ lâu không dùng nhất */
export const MAX_SAVED_ADDRESSES = 5;
const MAX_LABEL = 40;

/** Số nhà/đường bỏ dấu, chữ thường, gộp khoảng trắng: "12  Lê Lợi" và "12 le loi" là một địa chỉ */
export const streetKey = (street: string) =>
  street.normalize('NFD').replace(/\p{M}/gu, '').replace(/đ/gi, 'd').toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, ' ').trim();

/** Địa chỉ trả cho app: cùng dạng location của tin (provinceCode, ward, toạ độ...) kèm id, tên, lần dùng cuối */
export function toSavedAddressDto(row: SavedAddressRow) {
  return {
    id: row.id,
    label: row.label,
    provinceCode: row.provinceCode,
    wardCode: row.wardCode,
    province: findProvince(row.provinceCode) ?? null,
    ward: findWard(row.wardCode) ?? null,
    streetAddress: row.streetAddress,
    latitude: row.latitude,
    longitude: row.longitude,
    geoSource: row.geoSource,
    lastUsedAt: row.lastUsedAt,
  };
}

export const listSavedAddresses = async (userId: string) =>
  (await repository.listByUser(userId)).map(toSavedAddressDto);

function parseLabel(value: unknown) {
  if (value == null) return null;
  if (typeof value !== 'string' || value.trim().length > MAX_LABEL) {
    throw new AppError(400, 'INVALID_ADDRESS_LABEL', `Tên địa chỉ tối đa ${MAX_LABEL} ký tự.`, 'label');
  }
  return value.trim() || null;
}

/**
 * Lưu [location] (đã kiểm tra) vào sổ địa chỉ: trùng phường + số nhà thì cập nhật toạ độ và lần dùng cuối,
 * mới thì thêm, quá 5 thì xoá các địa chỉ lâu không dùng nhất. [label] undefined = giữ tên cũ.
 */
export async function rememberAddress(userId: string, location: ListingLocation, label?: string | null) {
  const key = streetKey(location.streetAddress);
  const row = await repository.transaction(async (tx) => {
    const now = new Date();
    const point = {
      provinceCode: location.provinceCode, streetAddress: location.streetAddress,
      latitude: location.latitude, longitude: location.longitude, geoSource: location.geoSource, lastUsedAt: now,
    };
    const existing = await repository.findByKey(tx, userId, location.wardCode, key);
    const saved = existing
      ? await repository.update(existing.id, { ...point, ...(label !== undefined && { label }) }, tx)
      : await repository.create(tx, { ...point, userId, wardCode: location.wardCode, streetKey: key, label: label ?? null });
    const all = await repository.listByUser(userId, tx);
    const extra = all.slice(MAX_SAVED_ADDRESSES).map((item) => item.id);
    if (extra.length) await repository.removeMany(tx, extra);
    return saved;
  });
  return toSavedAddressDto(row);
}

/** POST /users/me/addresses: body là location của tin (provinceCode, wardCode, streetAddress, latitude, longitude, geoSource) + label */
export async function saveAddress(userId: string, body: unknown) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new AppError(400, 'INVALID_LOCATION', 'Địa chỉ không hợp lệ.', 'location');
  }
  const { label, ...rest } = body as Record<string, unknown>;
  const location = listingLocation(rest);
  if (!location) throw new AppError(400, 'INVALID_LOCATION', 'Địa chỉ không hợp lệ.', 'location');
  return rememberAddress(userId, location, label === undefined ? undefined : parseLabel(label));
}

/** Đặt / bỏ tên của địa chỉ đã lưu */
export async function renameAddress(userId: string, id: string, body: unknown) {
  const value = body && typeof body === 'object' ? (body as Record<string, unknown>) : {};
  if (Object.keys(value).some((key) => key !== 'label')) {
    throw new AppError(400, 'INVALID_ADDRESS_LABEL', 'Chỉ đổi được tên địa chỉ.', 'label');
  }
  const label = parseLabel(value.label);
  const existing = await repository.findOwned(userId, id);
  if (!existing) throw new AppError(404, 'ADDRESS_NOT_FOUND', 'Không tìm thấy địa chỉ.');
  return toSavedAddressDto(await repository.update(id, { label }));
}

export async function deleteAddress(userId: string, id: string) {
  const { count } = await repository.remove(userId, id);
  if (!count) throw new AppError(404, 'ADDRESS_NOT_FOUND', 'Không tìm thấy địa chỉ.');
}

/** Gọi sau khi đăng / sửa tin: lỗi khi lưu sổ địa chỉ không được làm hỏng việc đăng tin */
export async function rememberListingAddress(userId: string, location: unknown) {
  if (!location || typeof location !== 'object' || !('wardCode' in location)) return;
  try {
    await rememberAddress(userId, location as ListingLocation);
  } catch (error) {
    console.warn('[saved-address] không lưu được địa chỉ của tin', error);
  }
}
