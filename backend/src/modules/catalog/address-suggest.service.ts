import { AppError } from '../../common/errors/app-error.js';
import { findWard, locatePoint, provinceCenter } from './catalog.service.js';
import type { Coordinates } from './catalog.type.js';

/*
 * Gợi ý số nhà, tên đường khi nhập địa chỉ. Chọn nguồn bằng ADDRESS_PROVIDER:
 *  - photon (mặc định): Photon trên dữ liệu OpenStreetMap, miễn phí, không cần key.
 *    Server công cộng photon.komoot.io chỉ dùng hợp lý (không cam kết tải lớn); có thể tự host
 *    rồi trỏ PHOTON_URL sang.
 *  - off: tắt, luôn trả danh sách rỗng.
 * Kết quả được cache trong bộ nhớ để giảm số lượt gọi ra ngoài.
 */

export type AddressSuggestion = {
  /** Dòng số nhà/tên đường để điền vào ô, VD "12 Nguyễn Huệ" */
  label: string;
  /** Mô tả phụ (phường, tỉnh...) để người dùng phân biệt */
  description: string;
  provinceCode?: string;
  wardCode?: string;
  latitude?: number;
  longitude?: number;
};

export type AddressSuggestInput = { q: string; provinceCode?: string; wardCode?: string; limit: number };

type Provider = 'photon' | 'off';

const TIMEOUT_MS = 4000;
const CACHE_TTL_MS = 10 * 60_000;
const CACHE_MAX = 500;
/** Khung bao Việt Nam [minLon, minLat, maxLon, maxLat] để Photon chỉ trả kết quả trong nước */
const VIETNAM_BBOX = '102.1,8.2,109.6,23.5';

const cache = new Map<string, { at: number; value: AddressSuggestion[] }>();

function provider(): Provider {
  const value = process.env.ADDRESS_PROVIDER?.trim().toLowerCase() || 'photon';
  if (value === 'photon' || value === 'off') return value;
  throw new AppError(500, 'ADDRESS_PROVIDER_INVALID', 'ADDRESS_PROVIDER chỉ nhận photon hoặc off.');
}

/** Điểm ưu tiên khi tìm: tâm phường nếu đã chọn, không thì tâm tỉnh */
function biasPoint(input: AddressSuggestInput): Coordinates | undefined {
  return findWard(input.wardCode)?.center ?? (input.provinceCode ? provinceCenter(input.provinceCode) : undefined);
}

async function getJson(url: URL, headers: Record<string, string> = {}) {
  let response: Response;
  try {
    response = await fetch(url, { headers: { Accept: 'application/json', ...headers }, signal: AbortSignal.timeout(TIMEOUT_MS) });
  } catch {
    throw new AppError(502, 'ADDRESS_SUGGEST_UNAVAILABLE', 'Chưa lấy được gợi ý địa chỉ, thử lại sau.');
  }
  if (!response.ok) throw new AppError(502, 'ADDRESS_SUGGEST_UNAVAILABLE', 'Chưa lấy được gợi ý địa chỉ, thử lại sau.');
  return response.json() as Promise<unknown>;
}

/** Gắn phường/tỉnh chứa tọa độ (dữ liệu ranh giới của mình), lọc theo tỉnh đang chọn */
function withArea(item: AddressSuggestion, provinceCode?: string): AddressSuggestion | undefined {
  if (item.latitude == null || item.longitude == null) return item;
  const found = locatePoint({ latitude: item.latitude, longitude: item.longitude });
  if (!found) return undefined;
  if (provinceCode && found.province.code !== provinceCode) return undefined;
  return {
    ...item,
    provinceCode: found.province.code, wardCode: found.ward.code,
    description: `${found.ward.name}, ${found.province.name}`,
  };
}

type PhotonFeature = { geometry?: { coordinates?: [number, number] }; properties?: Record<string, unknown> };

async function photon(input: AddressSuggestInput): Promise<AddressSuggestion[]> {
  const url = new URL('/api/', process.env.PHOTON_URL?.trim() || 'https://photon.komoot.io');
  url.searchParams.set('q', input.q);
  url.searchParams.set('limit', String(Math.min(input.limit * 3, 30)));
  url.searchParams.set('bbox', VIETNAM_BBOX);
  const bias = biasPoint(input);
  if (bias) {
    url.searchParams.set('lat', String(bias.latitude));
    url.searchParams.set('lon', String(bias.longitude));
  }
  const body = await getJson(url, { 'User-Agent': 'ReStore-backend/1.0' }) as { features?: PhotonFeature[] };
  const results: AddressSuggestion[] = [];
  for (const feature of body.features ?? []) {
    const p = feature.properties ?? {};
    if (p.countrycode !== 'VN') continue;
    const text = (key: string) => (typeof p[key] === 'string' ? (p[key] as string).trim() : '');
    const street = text('street') || (p.type === 'street' || p.osm_key === 'highway' ? text('name') : '');
    const label = [text('housenumber'), street].filter(Boolean).join(' ') || text('name');
    const [longitude, latitude] = feature.geometry?.coordinates ?? [];
    if (!label || typeof latitude !== 'number' || typeof longitude !== 'number') continue;
    const item = withArea({ label, description: '', latitude, longitude }, input.provinceCode);
    if (item) results.push(item);
  }
  return results;
}

/** Gợi ý địa chỉ cho ô số nhà/tên đường, ưu tiên quanh phường/tỉnh đang chọn */
export async function suggestAddresses(input: AddressSuggestInput): Promise<AddressSuggestion[]> {
  const source = provider();
  if (source === 'off') return [];
  const key = `${source}|${input.q.toLowerCase()}|${input.provinceCode ?? ''}|${input.wardCode ?? ''}|${input.limit}`;
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_TTL_MS) return hit.value;

  const items = await photon(input);
  const seen = new Set<string>();
  const value = items.filter((item) => {
    const id = `${item.label.toLowerCase()}|${item.wardCode ?? item.description}`;
    if (seen.has(id)) return false;
    seen.add(id);
    return true;
  }).slice(0, input.limit);

  if (cache.size >= CACHE_MAX) cache.delete(cache.keys().next().value!);
  cache.set(key, { at: Date.now(), value });
  return value;
}

/** Chỉ dùng trong test */
export const clearAddressSuggestCache = () => cache.clear();
