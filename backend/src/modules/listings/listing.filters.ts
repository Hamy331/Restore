import { ListingCondition } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import { coordinates } from '../catalog/catalog.js';

/**
 * Bộ lọc tìm kiếm tin đăng dùng chung cho GET /listings, tìm kiếm, gần bạn.
 * Query: q, categoryId, condition, minPrice, maxPrice, latitude + longitude (+ radiusKm), allowExchange
 */
export function listingFilters(query: Record<string, unknown>) {
  const q = query.q;
  const categoryId = query.categoryId;
  const condition = query.condition;
  const minPrice = query.minPrice;
  const maxPrice = query.maxPrice;
  if (q !== undefined && (typeof q !== 'string' || q.trim().length > 100)) {
    throw new AppError(400, 'INVALID_QUERY', 'Từ khóa tìm kiếm không hợp lệ.');
  }
  if (categoryId !== undefined && (typeof categoryId !== 'string' || categoryId.length > 100)) {
    throw new AppError(400, 'INVALID_QUERY', 'Danh mục không hợp lệ.');
  }
  if (condition !== undefined && (typeof condition !== 'string' || !Object.values(ListingCondition).includes(condition as ListingCondition))) {
    throw new AppError(400, 'INVALID_QUERY', 'Tình trạng sản phẩm không hợp lệ.');
  }
  for (const value of [minPrice, maxPrice]) {
    if (value !== undefined && (typeof value !== 'string' || !/^\d{1,12}$/.test(value))) {
      throw new AppError(400, 'INVALID_QUERY', 'Khoảng giá không hợp lệ.');
    }
  }
  if (minPrice !== undefined && maxPrice !== undefined && Number(minPrice) > Number(maxPrice)) {
    throw new AppError(400, 'INVALID_QUERY', 'Giá thấp nhất phải nhỏ hơn giá cao nhất.');
  }
  let nearby: {latitude:number;longitude:number;radius:number} | undefined;
  if (query.latitude != null || query.longitude != null) {
    if(typeof query.latitude!=='string' || typeof query.longitude!=='string' || !query.latitude.trim() || !query.longitude.trim()) throw new AppError(400,'INVALID_QUERY','Cần đủ tọa độ để tìm gần bạn.');
    const point=coordinates(Number(query.latitude),Number(query.longitude));
    const radius=query.radiusKm==null?5:Number(query.radiusKm);
    if(!Number.isFinite(radius)||radius<1||radius>100)throw new AppError(400,'INVALID_QUERY','Bán kính từ 1 đến 100 km.');
    nearby={...point,radius};
  }
  if(query.allowExchange!=null && query.allowExchange!=='true' && query.allowExchange!=='false')throw new AppError(400,'INVALID_QUERY','Bộ lọc trao đổi không hợp lệ.');
  return {
    ...(nearby?{nearby}:{}), ...(query.allowExchange==='true'?{allowExchange:true}:{}),
    q: typeof q === 'string' ? q.trim() : '',
    categoryId: typeof categoryId === 'string' ? categoryId : '',
    condition: typeof condition === 'string' ? condition as ListingCondition : null,
    minPrice: typeof minPrice === 'string' ? minPrice : null,
    maxPrice: typeof maxPrice === 'string' ? maxPrice : null,
  };
}

export type ListingFilters = ReturnType<typeof listingFilters>;
