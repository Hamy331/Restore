import { AppError } from '../../common/errors/app-error.js';
import { LEGACY_WARD_CODES, PROVINCES, WARDS } from './catalog.data.js';
import { toCategoryDto } from './catalog.dto.js';
import * as catalogRepository from './catalog.repository.js';
import { CATEGORY_ORDER, Coordinates, MAX_REVERSE_GEOCODE_KM, Unit } from './catalog.type.js';
import { wardCodeAt } from './location.geo.js';

/* ---------- Địa lý (dùng chung với home, listings) ---------- */

/** Khoảng cách đường tròn lớn (km) */
export function distanceKm(a: Coordinates, b: Coordinates) {
  const rad = Math.PI / 180;
  const dLat = (b.latitude - a.latitude) * rad, dLon = (b.longitude - a.longitude) * rad;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(a.latitude * rad) * Math.cos(b.latitude * rad) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(Math.min(1, h)));
}

type WardWithCenter = Unit & { center: Coordinates };

const PROVINCE_BY_CODE = new Map(PROVINCES.map((unit) => [unit.code, unit]));
const WARD_BY_CODE = new Map(Object.values(WARDS).flat().map((unit) => [unit.code, unit as WardWithCenter]));

export const findProvince = (code: unknown) => (typeof code === 'string' ? PROVINCE_BY_CODE.get(code) : undefined);

/** Phường/xã theo mã (tìm trong mọi tỉnh), nhận cả mã mẫu cũ ("79-SG") */
export function findWard(code: unknown) {
  if (typeof code !== 'string') return undefined;
  return WARD_BY_CODE.get(Object.hasOwn(LEGACY_WARD_CODES, code) ? LEGACY_WARD_CODES[code]! : code);
}

/** Tâm tỉnh: tâm phường mã nhỏ nhất (phường trung tâm cũ, VD Phường Ba Đình của Hà Nội) */
export const provinceCenter = (code: string) => (Object.hasOwn(WARDS, code) ? WARDS[code]![0]?.center : undefined);

/** Mọi phường (đều có tọa độ tâm) */
export const wardsWithCenter = () => [...WARD_BY_CODE.values()];

/**
 * Phường và tỉnh chứa điểm GPS: theo ranh giới phường; điểm ngoài mọi ranh giới (biển, sai số GPS
 * sát bờ) lấy phường có tâm gần nhất trong MAX_REVERSE_GEOCODE_KM. undefined nếu ngoài Việt Nam.
 */
export function locatePoint(point: Coordinates) {
  let ward = findWard(wardCodeAt(point));
  if (!ward) {
    let best = MAX_REVERSE_GEOCODE_KM;
    for (const candidate of WARD_BY_CODE.values()) {
      const distance = distanceKm(point, candidate.center);
      if (distance <= best) [ward, best] = [candidate, distance];
    }
  }
  const province = ward && findProvince(ward.parentCode);
  return ward && province ? { province, ward } : undefined;
}

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
  if (!wards) throw new AppError(404, 'LOCATION_NOT_FOUND', 'Không tìm thấy tỉnh/thành này.');
  return wards;
}

/** Chữ thường, bỏ dấu tiếng Việt (kể cả đ), gộp khoảng trắng */
const fold = (input: string) =>
  input.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/\s+/g, ' ').trim();

/** Khu vực để chọn (trang chọn khu vực, Gần bạn): tỉnh/thành hoặc phường/xã kèm tâm */
export type AreaOption = { code: string; name: string; shortName?: string; level: string; parentName?: string; center: Coordinates };

/**
 * Mọi khu vực tìm được, tỉnh trước. Tâm tỉnh lấy tâm phường mã nhỏ nhất (phường trung tâm cũ,
 * VD Phường Ba Đình của Hà Nội), vì tâm hình học của tỉnh có đảo (Khánh Hoà, Trường Sa) rơi ra biển.
 */
const AREAS: { option: AreaOption; keys: string[]; parentKey?: string }[] = [
  ...PROVINCES.map((province) => ({
    option: { code: province.code, name: province.name, shortName: province.shortName, level: province.level, center: provinceCenter(province.code)! },
    keys: [fold(province.shortName ?? province.name), fold(province.name)],
  })),
  ...wardsWithCenter().map((ward) => {
    const province = findProvince(ward.parentCode)!;
    return {
      option: { code: ward.code, name: ward.name, shortName: ward.shortName, level: ward.level, parentName: province.name, center: ward.center },
      keys: [fold(ward.shortName ?? ward.name), fold(ward.name)],
      parentKey: fold(province.name),
    };
  }),
];

/**
 * Tìm khu vực theo tên, không phân biệt dấu: khớp tên trước (khớp từ đầu tên ngắn lên đầu),
 * rồi tới phường thuộc tỉnh có tên khớp.
 */
export function searchAreas(query: string, limit: number) {
  const q = fold(query);
  if (!q) return [];
  const byName = AREAS.filter((area) => area.keys.some((key) => key.includes(q)))
    .map((area, index) => ({ area, rank: area.keys[0]!.startsWith(q) ? 0 : 1, index }))
    .sort((a, b) => a.rank - b.rank || a.index - b.index)
    .map(({ area }) => area);
  const byParent = AREAS.filter((area) => !area.keys.some((key) => key.includes(q)) && area.parentKey?.includes(q));
  return [...byName, ...byParent].slice(0, limit).map((area) => area.option);
}

/** Phường và tỉnh chứa GPS, 404 nếu ngoài Việt Nam */
export function reverseGeocode(point: Coordinates) {
  const found = locatePoint(point);
  if (!found) throw new AppError(404, 'LOCATION_NOT_FOUND', 'GPS nằm ngoài Việt Nam.');
  return found;
}
