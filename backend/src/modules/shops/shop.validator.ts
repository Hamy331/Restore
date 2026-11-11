import { ListingCondition } from '@prisma/client';
import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { idParam, pageQuery, parse } from '../../common/validation/schemas.js';

/** :id của shop */
export const shopIdParams = idParam(100);

const SORTS = ['newest', 'price_asc', 'price_desc', 'relevance', 'nearest'] as const;

/**
 * Query GET /shops/:id/listings: categoryId?, minPrice?, maxPrice?, condition? (nhiều giá trị cách nhau dấu phẩy),
 * sort? (newest | price_asc | price_desc; giá trị khác coi như newest), page, limit (1-50, mặc định 10)
 */
export const shopListingsQuery = z.record(z.string(), z.unknown()).transform((raw) => {
  const pagination = parse(pageQuery({ defaultLimit: 10, maxLimit: 50 }), raw);
  const text = (key: string) => (typeof raw[key] === 'string' && raw[key] ? (raw[key] as string).trim() : undefined);
  const money = (key: string) => {
    const value = text(key);
    if (value !== undefined && !/^\d{1,12}$/.test(value)) throw new AppError(400, 'INVALID_QUERY', 'Khoảng giá không hợp lệ.', key);
    return value === undefined ? undefined : Number(value);
  };
  const conditions = (text('condition') ?? '').split(',').map((item) => item.trim()).filter(Boolean);
  for (const item of conditions) {
    if (!Object.values(ListingCondition).includes(item as ListingCondition)) {
      throw new AppError(400, 'INVALID_QUERY', 'Tình trạng sản phẩm không hợp lệ.', 'condition');
    }
  }
  const sort = SORTS.find((item) => item === text('sort')) ?? 'newest';
  return {
    pagination,
    categoryId: text('categoryId'),
    minPrice: money('minPrice'),
    maxPrice: money('maxPrice'),
    conditions: conditions as ListingCondition[],
    sort,
  };
});

export type ShopIdParams = z.infer<typeof shopIdParams>;
export type ShopListingsQuery = z.infer<typeof shopListingsQuery>;
