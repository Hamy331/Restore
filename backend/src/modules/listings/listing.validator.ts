import { ListingCondition, ListingStatus, Prisma } from '@prisma/client';
import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { choice, object, page, text, version } from '../../common/validation/admin-input.js';
import { idParam, int, oneOf, pageQuery, parse } from '../../common/validation/schemas.js';
import { coordinates, listingLocation } from '../catalog/index.js';
import { FEED_FILTERS, MAX_IMAGES, MODERATION_ACTIONS, OWNER_STATUS_TARGETS } from './listing.type.js';

/*
 * Schema đầu vào của module listings.
 * Các hàm kiểm tra cũ (listingInput, listingFilters, validateAttributes) giữ nguyên logic và
 * thông báo lỗi; schema zod bọc chúng để dùng với validate().
 */

/* ---------- Nội dung tin (tạo, sửa, nháp) ---------- */

export function listingInput(value: unknown, draft = false) {
  const fail = (message: string, field?: string): never => { throw new AppError(400, draft ? 'INVALID_DRAFT' : 'INVALID_LISTING', message, field); };
  if (!value || typeof value !== 'object' || Array.isArray(value)) fail('Dữ liệu tin không hợp lệ.');
  const body = value as Record<string, unknown>;
  const allowed = ['title','description','price','condition','categoryId','isNegotiable','allowSale','allowExchange','exchangeWish','sellerType','location','attributes'];
  // Cờ của thao tác đăng (trả xu, vẫn đăng dù trùng): controller đọc riêng, không thuộc nội dung tin
  const flags = draft ? [] : ['payWithCredits', 'allowDuplicate'];
  if (Object.keys(body).some((key) => !allowed.includes(key) && !flags.includes(key))) fail('Tin có trường không được hỗ trợ.');
  if (flags.some((key) => body[key] !== undefined && typeof body[key] !== 'boolean')) fail('Dữ liệu tin không hợp lệ.');
  const title = body.title ?? '', description = body.description ?? '';
  if (typeof title !== 'string' || title.trim().length > 70 || (!draft && title.trim().length < 5)) fail('Tiêu đề cần từ 5 đến 70 ký tự.', 'title');
  if (typeof description !== 'string' || description.trim().length > 1500 || (!draft && description.trim().length < 10)) fail('Mô tả cần từ 10 đến 1500 ký tự.', 'description');
  const categoryId = body.categoryId == null || body.categoryId === '' ? null : body.categoryId;
  if ((categoryId !== null && (typeof categoryId !== 'string' || categoryId.length > 100)) || (!draft && !categoryId)) fail('Chọn danh mục hợp lệ.', 'categoryId');
  const condition = body.condition ?? null;
  if (!(draft && condition === null) && (typeof condition !== 'string' || !Object.values(ListingCondition).includes(condition as ListingCondition))) fail('Tình trạng không hợp lệ.', 'condition');
  const allowSale = body.allowSale ?? true, allowExchange = body.allowExchange ?? false;
  if (typeof allowSale !== 'boolean' || typeof allowExchange !== 'boolean' || (!allowSale && !allowExchange)) fail('Chọn bán hoặc trao đổi.');
  const rawPrice = body.price == null || body.price === '' ? '0' : String(body.price);
  if ((typeof body.price !== 'number' && typeof body.price !== 'string' && body.price != null) ||
      !/^(0|[1-9]\d{0,11})$/.test(rawPrice) || (!draft && allowSale && rawPrice === '0')) fail('Giá VND không hợp lệ.', 'price');
  const exchangeWish = body.exchangeWish ?? '', sellerType = body.sellerType ?? 'PERSONAL';
  if (typeof exchangeWish !== 'string' || exchangeWish.trim().length > 200) fail('Mong muốn trao đổi tối đa 200 ký tự.', 'exchangeWish');
  if (sellerType !== 'PERSONAL' && sellerType !== 'BUSINESS') fail('Loại người bán không hợp lệ.', 'sellerType');
  const isNegotiable = body.isNegotiable ?? true;
  if (typeof isNegotiable !== 'boolean') fail('Thông tin thương lượng không hợp lệ.', 'isNegotiable');
  const attributes = body.attributes ?? {};
  if (!attributes || typeof attributes !== 'object' || Array.isArray(attributes) ||
    Object.keys(attributes).length > 40 || JSON.stringify(attributes).length > 10000) fail('Thuộc tính không hợp lệ.', 'attributes');
  const location = listingLocation(body.location);
  if (!draft && !location) fail('Chọn địa chỉ giao dịch.', 'location');
  return { title: (title as string).trim(), description: (description as string).trim(), categoryId: categoryId as string | null,
    condition: condition as ListingCondition | null, price: allowSale ? rawPrice : '0', isNegotiable: (allowSale && isNegotiable) as boolean,
    allowSale: allowSale as boolean, allowExchange: allowExchange as boolean,
    exchangeWish: allowExchange ? (exchangeWish as string).trim() : '', sellerType: sellerType as string,
    attributes: attributes as Prisma.InputJsonObject,
    location: location ? JSON.parse(JSON.stringify(location)) as Prisma.InputJsonObject : Prisma.DbNull };
}

/** Tin đầy đủ để đăng: bắt buộc danh mục và tình trạng */
export function createInput(value: unknown) {
  const data = listingInput(value);
  return { ...data, categoryId: data.categoryId!, condition: data.condition! };
}

/** Bản nháp: mọi trường đều có thể trống */
export const draftInput = (value: unknown) => listingInput(value, true);

/* ---------- Bộ lọc tìm kiếm ---------- */

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

/** Kiểm tra thuộc tính theo metadata của danh mục */
export function validateAttributes(values: Prisma.InputJsonObject, metadata: unknown, required: boolean) {
  const schema = ((metadata as { attributes?: Array<{key:string; type:string; required?:boolean; min?:number;max?:number;maxLength?:number;options?:Array<{value:string}>}> })?.attributes ?? []);
  const fail = (key: string): never => { throw new AppError(400,'INVALID_ATTRIBUTES',`Thuộc tính ${key} không hợp lệ.`,key); };
  for (const key of Object.keys(values)) if (!schema.some((field) => field.key === key)) fail(key);
  for (const field of schema) {
    const value = values[field.key];
    if (value == null || value === '') { if (required && field.required && field.type !== 'boolean') fail(field.key); continue; }
    if (field.type === 'number' && (typeof value !== 'number' || !Number.isFinite(value) ||
      (field.min != null && value < field.min) || (field.max != null && value > field.max))) fail(field.key);
    if (field.type === 'boolean' && typeof value !== 'boolean') fail(field.key);
    if ((field.type === 'text' || field.type === 'select') && (typeof value !== 'string' || value.length > (field.maxLength ?? 200))) fail(field.key);
    if (field.type === 'select' && !field.options?.some((option) => option.value === value)) fail(field.key);
  }
}

/* ---------- Schema cho validate() ---------- */

/** Params `:id` = mã tin (không giới hạn độ dài, tin không có thì 404) */
export const listingIdParams = z.object({ id: z.string() });

/** Params `:id` cho API lưu tin */
export const favoriteIdParams = idParam(64);

export const createListingBody = z.unknown().transform(createInput);
export const draftBody = z.unknown().transform(draftInput);

/** Body PATCH /:id/status: { status: AVAILABLE | HIDDEN | SOLD | EXCHANGED, payWithCredits?: boolean } */
export const statusBody = z.unknown().transform((body) => {
  const input = body as { status?: unknown; payWithCredits?: unknown } | undefined;
  const target = input?.status;
  if (typeof target !== 'string' || !OWNER_STATUS_TARGETS.includes(target as ListingStatus) ||
      !body || Object.keys(body).some((key) => key !== 'status' && key !== 'payWithCredits') ||
      (input?.payWithCredits !== undefined && typeof input?.payWithCredits !== 'boolean')) {
    throw new AppError(400, 'INVALID_STATUS', 'Trạng thái tin không hợp lệ.');
  }
  return { status: target as ListingStatus, payWithCredits: input?.payWithCredits === true };
});

/** Body POST /:id/feature: { packageId } là gói FEATURED đang bán */
export const featureBody = z.unknown().transform((body) => {
  const packageId = (body as { packageId?: unknown } | undefined)?.packageId;
  if (typeof packageId !== 'string' || !packageId.trim() || packageId.length > 100) {
    throw new AppError(400, 'INVALID_PACKAGE', 'Gói tin ưu tiên không hợp lệ.');
  }
  return { packageId: packageId.trim() };
});

/**
 * Thứ tự ảnh mới cho PUT /:id/images: { images: string[] }, chỉ gồm ảnh tin đang có, không trùng.
 * Gọi trong service sau khi đã tìm thấy tin (tin không có thì 404 trước khi báo body sai).
 */
export function orderedImages(body: unknown, current: string[]): string[] {
  if (!body || typeof body !== 'object' || Object.keys(body).some((key) => key !== 'images')) {
    throw new AppError(400, 'INVALID_IMAGES', 'Danh sách ảnh không hợp lệ.');
  }
  const value = (body as { images?: unknown }).images;
  if (!Array.isArray(value) || value.length > MAX_IMAGES ||
      value.some((item) => typeof item !== 'string' || !current.includes(item)) ||
      new Set(value).size !== value.length) {
    throw new AppError(400, 'INVALID_IMAGES', 'Danh sách ảnh không hợp lệ.');
  }
  return value as string[];
}

/** Params `:filename` của ảnh tin */
export const mediaParams = z.object({ filename: z.string() });

function positiveInteger(value: unknown, fallback: number, max: number): number {
  if (value === undefined) return fallback;
  const parsed = typeof value === 'string' && /^[1-9]\d*$/.test(value) ? Number(value) : NaN;
  if (!Number.isSafeInteger(parsed) || parsed > max) {
    throw new AppError(400, 'INVALID_PAGINATION', 'Trang hoặc kích thước trang không hợp lệ.');
  }
  return parsed;
}

/** Query GET /mine: page, pageSize (1-100, mặc định 20), status? */
export const mineQuery = z.record(z.string(), z.unknown()).transform((query) => {
  const page = positiveInteger(query.page, 1, 1_000_000);
  const pageSize = positiveInteger(query.pageSize, 20, 100);
  const status = query.status;
  if (status !== undefined && (typeof status !== 'string' || !Object.values(ListingStatus).includes(status as ListingStatus))) {
    throw new AppError(400, 'INVALID_STATUS', 'Bộ lọc trạng thái không hợp lệ.');
  }
  return { page, pageSize, status: status as ListingStatus | undefined };
});

/** Body duyệt tin: { decision: APPROVED | REJECTED, reason?, updatedAt } */
export const decisionBody = z.unknown().transform((body) => {
  const { decision, reason, updatedAt } = (body ?? {}) as Record<string, unknown>;
  const expected = typeof updatedAt === 'string' ? new Date(updatedAt) : null;
  if (typeof decision !== 'string' || !['APPROVED', 'REJECTED'].includes(decision) || !expected || Number.isNaN(+expected) ||
      (decision === 'REJECTED' && (typeof reason !== 'string' || reason.trim().length < 5 || reason.length > 300))) {
    throw new AppError(400, 'INVALID_DECISION', 'Quyết định không hợp lệ.');
  }
  return { decision: decision as 'APPROVED' | 'REJECTED', reason: reason ?? '', expectedUpdatedAt: expected };
});

/**
 * Query GET /listings.
 * - newest:   mới nhất (tin được đẩy xếp trước). Bỏ qua tọa độ nếu có.
 * - nearby:   bắt buộc latitude + longitude, lọc trong radiusKm (mặc định 5) và xếp gần nhất trước.
 * - exchange: chỉ tin cho phép trao đổi.
 * Các bộ lọc tìm kiếm (q, categoryId, condition, minPrice, maxPrice) dùng được với mọi filter.
 */
export const feedQuery = z.record(z.string(), z.unknown()).transform((raw) => {
  const filter = parse(oneOf('filter', FEED_FILTERS, 'newest'), raw.filter);
  const pagination = parse(pageQuery({ defaultLimit: 10, maxLimit: 50 }), raw);
  const { nearby, allowExchange, ...search } = listingFilters(raw);

  if (filter === 'nearby' && !nearby) {
    throw new AppError(400, 'LOCATION_REQUIRED', 'Cần latitude và longitude để xem tin gần bạn.', 'location');
  }
  const filters = {
    ...search,
    ...(filter === 'nearby' || (filter !== 'newest' && nearby) ? { nearby } : {}),
    ...(filter === 'exchange' || allowExchange ? { allowExchange: true } : {}),
  };
  return { filter, pagination, filters };
});

/** Query GET /listings/recommended */
export const recommendedQuery = z.object({
  limit: int('limit', { min: 1, max: 20, fallback: 10 }),
  categoryId: z.string().max(100).optional().transform((value) => value?.trim() || undefined),
});

/** Query GET /listings/favorites: page, limit 1-100 (mặc định 20) */
export const favoritesQuery = pageQuery({ defaultLimit: 20, maxLimit: 100 });

/* ---------- Quản trị tin (/admin/listings), lỗi INVALID_ADMIN_INPUT / INVALID_QUERY như API cũ ---------- */

/** Query GET /admin/listings: status?, q? (1-100 ký tự, tìm trong tiêu đề), page */
export const adminListingQuery = z.record(z.string(), z.unknown()).transform((query) => ({
  status: query.status ? choice(query.status, Object.values(ListingStatus)) : undefined,
  q: query.q ? text(query.q, 'q', 1, 100) : undefined,
  page: page(query.page),
}));

/** Body POST /admin/listings/:id/decision */
export const adminDecisionBody = z.unknown().transform((value) => {
  const body = object(value, ['action', 'reason', 'updatedAt']);
  const action = choice(body.action, MODERATION_ACTIONS);
  return { action, reason: text(body.reason, 'reason', action === 'APPROVE' ? 0 : 5, 300), expectedUpdatedAt: version(body.updatedAt) };
});
