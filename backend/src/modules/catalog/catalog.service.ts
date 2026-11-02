import { AppError } from '../../common/errors/app-error.js';
import { PROVINCES, WARDS } from './catalog.data.js';
import { toCategoryDto } from './catalog.dto.js';
import * as catalogRepository from './catalog.repository.js';
import { CATEGORY_ORDER, Coordinates, MAX_REVERSE_GEOCODE_KM, Unit } from './catalog.type.js';

/* ---------- Địa lý (dùng chung với home, listings) ---------- */

/** Khoảng cách đường tròn lớn (km) */
export function distanceKm(a: Coordinates, b: Coordinates) {
  const rad = Math.PI / 180;
  const dLat = (b.latitude - a.latitude) * rad, dLon = (b.longitude - a.longitude) * rad;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(a.latitude * rad) * Math.cos(b.latitude * rad) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(Math.min(1, h)));
}

export const findProvince = (code: unknown) => PROVINCES.find((unit) => unit.code === code);

/** Phường/xã theo mã (tìm trong mọi tỉnh) */
export const findWard = (code: unknown) => Object.values(WARDS).flat().find((unit) => unit.code === code);

/** Mọi phường có tọa độ tâm */
export const wardsWithCenter = () => Object.values(WARDS).flat().filter((unit): unit is Unit & { center: Coordinates } => !!unit.center);

/* ---------- API công khai ---------- */

/** Tình trạng sản phẩm đang dùng */
export const listConditions = () => catalogRepository.findActiveConditions();

/** Danh mục đang dùng: danh mục mặc định theo CATEGORY_ORDER, danh mục thêm sau theo tên */
export async function listCategories() {
  const categories = await catalogRepository.findActiveCategories();
  const order = new Map(CATEGORY_ORDER.map((id, index) => [id, index]));
  categories.sort((a, b) => (order.get(a.id) ?? Number.MAX_SAFE_INTEGER) - (order.get(b.id) ?? Number.MAX_SAFE_INTEGER));
  return categories.map(toCategoryDto);
}

export const listProvinces = () => PROVINCES;

export function listWards(provinceCode: string) {
  const wards = Object.hasOwn(WARDS, provinceCode) ? WARDS[provinceCode] : undefined;
  if (!wards) throw new AppError(404, 'LOCATION_NOT_FOUND', 'Chưa có dữ liệu địa chỉ cho tỉnh này.');
  return wards;
}

/** Phường gần GPS nhất (trong 30 km) và tỉnh của nó */
export function reverseGeocode(point: Coordinates) {
  const ward = wardsWithCenter().sort((a, b) => distanceKm(point, a.center) - distanceKm(point, b.center))[0];
  if (!ward || distanceKm(point, ward.center) > MAX_REVERSE_GEOCODE_KM) {
    throw new AppError(404, 'LOCATION_NOT_FOUND', 'GPS nằm ngoài vùng dữ liệu địa chỉ.');
  }
  return { province: findProvince(ward.parentCode), ward };
}
