import { ListingCondition } from '@prisma/client';
import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { idParam, int, oneOf, optionalStr, pageQuery, parse, str, strictBody } from '../../common/validation/schemas.js';
import { findProvince, findWard } from '../catalog/index.js';
import { tokens } from './wanted-alert.matcher.js';
import { AREA_LEVELS, DEAL_TYPES, DealType, KEYWORDS_MAX, KEYWORDS_MIN, MATCH_LEVELS, MAX_PRICE } from './wanted-alert.type.js';

const invalid = (message: string, field: string, code = 'INVALID_INPUT') => new AppError(400, code, message, field);

/** Giá không bắt buộc: null hoặc không gửi là không giới hạn */
const price = (field: string, value: unknown) =>
  value == null || value === '' ? null : parse(int(field, { min: 0, max: MAX_PRICE }), value);

/** Mảng giá trị trong danh sách cho phép, bỏ trùng; null hoặc không gửi là rỗng */
function setOf<T extends string>(field: string, allowed: readonly T[], value: unknown): T[] {
  if (value == null) return [];
  if (!Array.isArray(value) || value.some((item) => typeof item !== 'string' || !allowed.includes(item as T))) {
    throw invalid(`${field} chỉ nhận mảng các giá trị: ${allowed.join(', ')}.`, field);
  }
  return [...new Set(value as T[])];
}

/**
 * Khu vực { code, level: 'province' | 'ward', label? }; null là toàn quốc.
 * Mã phải có trong dữ liệu địa chỉ; nhãn do server dựng lại ("Phường, Tỉnh").
 */
function area(value: unknown) {
  if (value == null) return null;
  const body = value as Record<string, unknown>;
  const level = typeof value === 'object' && !Array.isArray(value) ? body.level : undefined;
  if (!AREA_LEVELS.includes(level as never) || typeof body.code !== 'string') {
    throw invalid('Khu vực không hợp lệ.', 'area', 'INVALID_LOCATION');
  }
  if (level === 'province') {
    const province = findProvince(body.code);
    if (!province) throw invalid('Không tìm thấy tỉnh/thành này.', 'area', 'INVALID_LOCATION');
    return { areaCode: province.code, areaLevel: 'province', areaLabel: province.name };
  }
  const ward = findWard(body.code);
  const province = ward && findProvince(ward.parentCode);
  if (!ward) throw invalid('Không tìm thấy phường/xã này.', 'area', 'INVALID_LOCATION');
  return { areaCode: ward.code, areaLevel: 'ward', areaLabel: province ? `${ward.name}, ${province.name}` : ward.name };
}

const sent = z.unknown().optional();

/**
 * Body của POST /wanted-alerts và POST /wanted-alerts/preview (WantedAlertDraft.toJson trong app):
 * { keywords, categoryId?, minPrice?, maxPrice?, conditions?, dealTypes?, area?, matchLevel? }
 */
export const draftBody = strictBody({
  keywords: sent, categoryId: sent, minPrice: sent, maxPrice: sent, conditions: sent, dealTypes: sent, area: sent, matchLevel: sent,
}).transform((body) => {
  const keywords = parse(str('keywords', { min: KEYWORDS_MIN, max: KEYWORDS_MAX }), body.keywords);
  if (tokens(keywords).length === 0) throw invalid('keywords cần ít nhất một từ có nghĩa.', 'keywords');
  const minPrice = price('minPrice', body.minPrice);
  const maxPrice = price('maxPrice', body.maxPrice);
  if (minPrice != null && maxPrice != null && minPrice > maxPrice) throw invalid('minPrice phải nhỏ hơn hoặc bằng maxPrice.', 'maxPrice');
  return {
    keywords,
    categoryId: parse(optionalStr('categoryId', { max: 64 }), body.categoryId) ?? null,
    minPrice,
    maxPrice,
    conditions: setOf('conditions', Object.values(ListingCondition), body.conditions),
    dealTypes: setOf<DealType>('dealTypes', DEAL_TYPES, body.dealTypes),
    ...(area(body.area) ?? { areaCode: null, areaLevel: null, areaLabel: null }),
    matchLevel: parse(oneOf('matchLevel', MATCH_LEVELS, 'BALANCED'), body.matchLevel),
  };
});

/** Query của POST /wanted-alerts/preview: limit (1-50, mặc định 20) */
export const previewQuery = z.object({ limit: z.unknown().optional() })
  .transform((query) => ({ limit: parse(int('limit', { min: 1, max: 50, fallback: 20 }), query.limit) }));

/** Query của GET /wanted-alerts/:id/matches: page, limit (mặc định 10, tối đa 50) */
export const matchesQuery = pageQuery({ defaultLimit: 10, maxLimit: 50 });

export const alertIdParams = idParam(64);
