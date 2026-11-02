import { AppError } from '../../common/errors/app-error.js';
import { catalog, distanceKm } from '../catalog/catalog.js';
import * as homeRepository from './home.repository.js';
import { toPublicBanner } from './home.mapper.js';
import type { BannerInput } from './home.validation.js';

/** Bản chụp JSON của banner để lưu vào AdminAudit */
const snapshot = (value: unknown) => JSON.parse(JSON.stringify(value));

/** Khoảng cách tối đa (km) từ GPS tới tâm phường gần nhất để coi là cùng khu vực */
const MAX_AREA_DISTANCE_KM = 30;
export const NATIONWIDE_AREA = { code: null, name: 'Toàn quốc' } as const;

/**
 * Khu vực đang xem ở trang chủ.
 * Ưu tiên provinceCode, sau đó tới tọa độ GPS; không có gì thì trả "Toàn quốc".
 */
export function resolveArea(input: { provinceCode?: string; point?: { latitude: number; longitude: number } }) {
  if (input.provinceCode) {
    const province = catalog.provinces.find((unit) => unit.code === input.provinceCode);
    if (!province) throw new AppError(404, 'AREA_NOT_FOUND', 'Không tìm thấy tỉnh/thành này.', 'provinceCode');
    return { code: province.code, name: province.name };
  }
  if (input.point) {
    const point = input.point;
    const nearest = Object.values(catalog.wards)
      .flat()
      .filter((ward) => ward.center)
      .map((ward) => ({ ward, distance: distanceKm(point, ward.center!) }))
      .sort((a, b) => a.distance - b.distance)[0];
    const province = nearest && nearest.distance <= MAX_AREA_DISTANCE_KM
      ? catalog.provinces.find((unit) => unit.code === nearest.ward.parentCode)
      : undefined;
    if (province) return { code: province.code, name: province.name };
  }
  return NATIONWIDE_AREA;
}

export async function listVisibleBanners(now = new Date()) {
  return (await homeRepository.findVisibleBanners(now)).map(toPublicBanner);
}

/* ---------- Quản trị banner (ADMIN) ---------- */

export const listAllBanners = () => homeRepository.findAllBanners();

export function createBanner(actorId: string, { data, reason }: BannerInput) {
  return homeRepository.saveBannerWithAudit(
    (tx) => tx.homeBanner.create({ data: { ...data, title: data.title! } }),
    (banner) => ({ actorId, action: 'HOME_BANNER_CREATE', targetType: 'HOME_BANNER', targetId: banner.id, reason, after: snapshot(banner) }),
  );
}

export async function updateBanner(actorId: string, id: string, { data, reason }: BannerInput) {
  const before = await requireBanner(id);
  const startsAt = data.startsAt !== undefined ? data.startsAt : before.startsAt;
  const endsAt = data.endsAt !== undefined ? data.endsAt : before.endsAt;
  if (startsAt && endsAt && startsAt >= endsAt) {
    throw new AppError(400, 'INVALID_INPUT', 'endsAt phải sau startsAt.', 'endsAt');
  }
  return homeRepository.saveBannerWithAudit(
    (tx) => tx.homeBanner.update({ where: { id }, data }),
    (banner) => ({ actorId, action: 'HOME_BANNER_UPDATE', targetType: 'HOME_BANNER', targetId: id, reason, before: snapshot(before), after: snapshot(banner) }),
  );
}

export async function deleteBanner(actorId: string, id: string, reason = '') {
  const before = await requireBanner(id);
  await homeRepository.saveBannerWithAudit(
    (tx) => tx.homeBanner.delete({ where: { id } }),
    () => ({ actorId, action: 'HOME_BANNER_DELETE', targetType: 'HOME_BANNER', targetId: id, reason, before: snapshot(before) }),
  );
}

async function requireBanner(id: string) {
  const banner = await homeRepository.findBannerById(id);
  if (!banner) throw new AppError(404, 'BANNER_NOT_FOUND', 'Không tìm thấy banner.');
  return banner;
}
