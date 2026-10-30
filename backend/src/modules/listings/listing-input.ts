import { ListingCondition, Prisma } from '@prisma/client';
import { AppError } from '../../errors/app-error.js';
import { listingLocation } from '../catalog/catalog.js';

export function listingInput(value: unknown, draft = false) {
  const fail = (message: string, field?: string): never => { throw new AppError(400, draft ? 'INVALID_DRAFT' : 'INVALID_LISTING', message, field); };
  if (!value || typeof value !== 'object' || Array.isArray(value)) fail('Dữ liệu tin không hợp lệ.');
  const body = value as Record<string, unknown>;
  const allowed = ['title','description','price','condition','categoryId','isNegotiable','allowSale','allowExchange','exchangeWish','sellerType','location','attributes'];
  if (Object.keys(body).some((key) => !allowed.includes(key))) fail('Tin có trường không được hỗ trợ.');
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
