import express, { Router, Request, Response, NextFunction } from 'express';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../errors/app-error.js';
import { ListingCondition, ListingStatus, Prisma, Role } from '@prisma/client';
import { AuthRequest, authorizeRoles, verifyToken } from '../../middlewares/auth.middleware.js';
import { storePackageForUser, storeUsage, withQuotaTransaction } from '../stores/store.service.js';
import { listingInput, validateAttributes } from './listing-input.js';
import { listingQuery } from './listing-query.js';
import { coordinates } from '../catalog/catalog.js';
import { publicLocation } from '../catalog/catalog.js';
import { randomUUID } from 'node:crypto';
import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';

const router = Router();
const imageDirectory = path.join(process.cwd(), 'uploads', 'listings');
const imagePrefix = '/api/v1/listings/media/';
const maxImages = 20;
const maxImageBytes = 5 * 1024 * 1024;
const imageName = /^[0-9a-f-]{36}\.(jpg|png|webp)$/;

export function imageExtension(contentType: unknown, bytes: unknown): string {
  if (!Buffer.isBuffer(bytes) || bytes.length === 0 || bytes.length > maxImageBytes) {
    throw new AppError(400, 'INVALID_IMAGE', 'Ảnh phải có dung lượng tối đa 5 MB.');
  }
  const content = bytes as Buffer;
  if (contentType === 'image/jpeg' && content.length >= 3 && content[0] === 0xff && content[1] === 0xd8 && content[2] === 0xff) return 'jpg';
  if (contentType === 'image/png' && content.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) return 'png';
  if (contentType === 'image/webp' && content.toString('ascii', 0, 4) === 'RIFF' && content.toString('ascii', 8, 12) === 'WEBP') return 'webp';
  throw new AppError(400, 'INVALID_IMAGE', 'Chỉ nhận ảnh JPEG, PNG hoặc WebP hợp lệ.');
}

export function orderedImages(value: unknown, current: string[]): string[] {
  if (!Array.isArray(value) || value.length > maxImages ||
      value.some((item) => typeof item !== 'string' || !current.includes(item)) ||
      new Set(value).size !== value.length) {
    throw new AppError(400, 'INVALID_IMAGES', 'Danh sách ảnh không hợp lệ.');
  }
  return value as string[];
}
const visible = { status: 'AVAILABLE' as const, owner: { status: 'ACTIVE' as const } };
const fields = {
  id: true,
  title: true,
  description: true,
  price: true,
  isNegotiable: true,
  ownerId: true, categoryId: true, status: true, updatedAt: true,
  allowSale: true, allowExchange: true, exchangeWish: true, sellerType: true, attributes: true, location: true, reviewReason: true,
  condition: true,
  category: { select: { id: true, name: true } },
  images: true,
  createdAt: true,
  viewCount: true,
  publishedAt: true,
  owner: { select: { id: true, fullName: true, ratingAverage: true, ratingCount: true } },
} as const;

function positiveInteger(value: unknown, fallback: number, max: number): number {
  if (value === undefined) return fallback;
  if (typeof value !== 'string' || !/^[1-9]\d*$/.test(value)) {
    throw new AppError(400, 'INVALID_PAGINATION', 'Trang hoặc kích thước trang không hợp lệ.');
  }
  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed > max) {
    throw new AppError(400, 'INVALID_PAGINATION', 'Trang hoặc kích thước trang không hợp lệ.');
  }
  return parsed;
}

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

export function output(listing: Prisma.ListingGetPayload<{ select: typeof fields }>, owner = false) {
  const location = owner ? listing.location : publicLocation(listing.location);
  const address = listing.location as {province?:{name?:string};ward?:{name?:string}} | null;
  return { ...listing, price: listing.price.toString(), location,
    areaLabel: address ? [address.ward?.name,address.province?.name].filter(Boolean).join(', ') : '' };
}
export function createInput(value: unknown) { const data = listingInput(value); return { ...data, categoryId: data.categoryId!, condition: data.condition! }; }
export function draftInput(value: unknown) { return listingInput(value, true); }

export async function requireOwnedListing(tx: Prisma.TransactionClient, id: string, ownerId: string) {
  const listing = await tx.listing.findFirst({ where: { id, ownerId } });
  if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
  return listing;
}

export async function updateOwnedListing(tx: Prisma.TransactionClient, id: string, ownerId: string,
  expectedStatus: ListingStatus, data: Prisma.ListingUncheckedUpdateManyInput) {
  const changed = await tx.listing.updateMany({
    where: { id, ownerId, status: expectedStatus }, data,
  });
  if (!changed.count) throw new AppError(409, 'LISTING_CHANGED', 'Tin đã thay đổi. Vui lòng tải lại.');
}

export function canChangeListingStatus(current: ListingStatus, target: ListingStatus) {
  return (current === ListingStatus.AVAILABLE && (target === ListingStatus.HIDDEN || target === ListingStatus.SOLD || target === ListingStatus.EXCHANGED)) ||
    (current === ListingStatus.HIDDEN && (target === ListingStatus.AVAILABLE || target === ListingStatus.SOLD || target === ListingStatus.EXCHANGED));
}

router.post('/', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const data = createInput(req.body);
    const listing = await withQuotaTransaction(async (tx) => {
      const now = new Date();
      const category = await tx.category.findUnique({ where: { id: data.categoryId } });
      if (!category) throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
      validateAttributes(data.attributes, category.metadata, true);
      const current = await storePackageForUser(tx, req.user!.userId, now);
      const usage = await storeUsage(tx, req.user!.userId, now);
      if (usage.today >= current.package.dailyListingLimit) {
        throw new AppError(409, 'DAILY_LISTING_LIMIT', 'Bạn đã dùng hết lượt đăng tin trong ngày.');
      }
      if (usage.active >= current.package.activeListingLimit) {
        throw new AppError(409, 'ACTIVE_LISTING_LIMIT', 'Bạn đã đạt giới hạn tin đang hoạt động.');
      }
      return tx.listing.create({
        data: { ...data, ownerId: req.user!.userId, images: [], publishedAt: now, status: ListingStatus.PENDING },
        select: fields,
      });
    });
    res.status(201).json({ success: true, data: output(listing, true) });
  } catch (error) {
    next(error);
  }
});

router.post('/drafts', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const data = draftInput(req.body);
    if (data.categoryId && !await prisma.category.findUnique({ where: { id: data.categoryId } })) {
      throw new AppError(400, 'INVALID_DRAFT', 'Danh mục không tồn tại.', 'categoryId');
    }
    const listing = await prisma.listing.create({
      data: { ...data, ownerId: req.user!.userId, status: ListingStatus.DRAFT, images: [] },
      select: { ...fields, status: true },
    });
    res.status(201).json({ success: true, data: { ...output(listing, true), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.put('/drafts/:id', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy bản nháp của bạn.');
    const data = draftInput(req.body);
    const listing = await prisma.$transaction(async (tx) => {
      const current = await requireOwnedListing(tx, id, req.user!.userId);
      if (!['DRAFT','PENDING','REJECTED','AVAILABLE','HIDDEN'].includes(current.status)) throw new AppError(409, 'DRAFT_CHANGED', 'Tin này không còn sửa được.');
      if (data.categoryId && !await tx.category.findUnique({ where: { id: data.categoryId } })) {
        throw new AppError(400, 'INVALID_DRAFT', 'Danh mục không tồn tại.', 'categoryId');
      }
      const category = data.categoryId ? await tx.category.findUnique({where:{id:data.categoryId}}) : null;
      if (category) validateAttributes(data.attributes,category.metadata,false);
      await updateOwnedListing(tx, id, req.user!.userId, current.status, {...data,status:ListingStatus.DRAFT,reviewReason:null});
      return tx.listing.findUniqueOrThrow({ where: { id }, select: { ...fields, status: true } });
    });
    res.json({ success: true, data: { ...output(listing, true), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.post('/drafts/:id/publish', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy bản nháp của bạn.');
    const listing = await withQuotaTransaction(async (tx) => {
      const current = await requireOwnedListing(tx, id, req.user!.userId);
      if (current.status === ListingStatus.PENDING) return tx.listing.findUniqueOrThrow({where:{id},select:fields});
      if (current.status !== ListingStatus.DRAFT) throw new AppError(409, 'DRAFT_CHANGED', 'Tin này không còn là bản nháp.');
      if (!current.images.length) throw new AppError(400, 'INVALID_LISTING', 'Cần ít nhất một ảnh để đăng tin.', 'images');
      const location = current.location as Record<string, unknown> | null;
      const data = createInput({
        title: current.title, description: current.description,
        price: current.price.toString(), condition: current.condition,
        categoryId: current.categoryId, isNegotiable: current.isNegotiable,
        allowSale: current.allowSale, allowExchange: current.allowExchange,
        exchangeWish: current.exchangeWish, sellerType: current.sellerType, attributes: current.attributes,
        location: location ? Object.fromEntries(['provinceCode','wardCode','streetAddress','latitude','longitude','geoSource'].map((key)=>[key,location[key]])) : null,
      });
      const category = await tx.category.findUnique({ where: { id: data.categoryId } });
      if (!category) {
        throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
      }
      validateAttributes(data.attributes, category.metadata, true);
      const now = new Date();
      const plan = await storePackageForUser(tx, req.user!.userId, now);
      const usage = await storeUsage(tx, req.user!.userId, now);
      if (usage.today >= plan.package.dailyListingLimit) {
        throw new AppError(409, 'DAILY_LISTING_LIMIT', 'Bạn đã dùng hết lượt đăng tin trong ngày.');
      }
      if (usage.active >= plan.package.activeListingLimit) {
        throw new AppError(409, 'ACTIVE_LISTING_LIMIT', 'Bạn đã đạt giới hạn tin đang hoạt động.');
      }
      await updateOwnedListing(tx, id, req.user!.userId, ListingStatus.DRAFT,
        { status: ListingStatus.PENDING, publishedAt: now });
      return tx.listing.findUniqueOrThrow({ where: { id }, select: { ...fields, status: true } });
    });
    res.json({ success: true, data: { ...output(listing, true), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.delete('/drafts/:id', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy bản nháp của bạn.');
    const current = await prisma.listing.findFirst({ where: { id, ownerId: req.user!.userId, status: ListingStatus.DRAFT } });
    if (!current) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy bản nháp của bạn.');
    const deleted = await prisma.listing.deleteMany({ where: { id, ownerId: req.user!.userId, status: ListingStatus.DRAFT } });
    if (!deleted.count) throw new AppError(409, 'DRAFT_CHANGED', 'Tin này không còn là bản nháp.');
    for (const url of current.images) {
      if (url.startsWith(imagePrefix) && imageName.test(url.slice(imagePrefix.length))) {
        await unlink(path.join(imageDirectory, url.slice(imagePrefix.length))).catch(() => {});
      }
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

router.get('/', (req:AuthRequest,res,next)=>req.headers.authorization?verifyToken(req,res,next):next(), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const page = positiveInteger(req.query.page, 1, 1000000);
    const pageSize = positiveInteger(req.query.pageSize, 12, 50);
    const filters = listingFilters(req.query);
    const query=listingQuery(filters,new Date());
    const [ranked,totals]=await prisma.$transaction([
      prisma.$queryRaw<{id:string;distanceKm:number|null}[]>`${query} LIMIT ${pageSize} OFFSET ${(page-1)*pageSize}`,
      prisma.$queryRaw<{n:number}[]>`SELECT COUNT(*)::int AS n FROM (${query}) ranked`,
    ]);
    const totalItems=totals[0]?.n??0;
    const items = ranked.length
      ? await prisma.listing.findMany({ where: { ...visible, id: { in: ranked.map((row) => row.id) } }, select: fields })
      : [];
    const byId = new Map(items.map((item) => [item.id, item]));
    const favorites=req.user && ranked.length?await prisma.listingFavorite.findMany({where:{userId:req.user.userId,listingId:{in:ranked.map(row=>row.id)}},select:{listingId:true}}):[];
    const favoriteIds=new Set(favorites.map(row=>row.listingId));
    res.json({
      success: true,
      data: ranked.flatMap((row) => {
        const item = byId.get(row.id);
        return item ? [{...output(item),distanceKm:row.distanceKm,isFavorite:favoriteIds.has(item.id)}] : [];
      }),
      pagination: { page, pageSize, totalItems, totalPages: Math.ceil(totalItems / pageSize) },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/summary', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest,res,next) => {
  try {
    const ownerId=req.user!.userId;
    const [active,sold]=await prisma.$transaction([
      prisma.listing.count({where:{ownerId,status:'AVAILABLE'}}),
      prisma.listing.count({where:{ownerId,status:'SOLD'}}),
    ]);
    res.json({success:true,data:{active,sold}});
  } catch(error) {next(error);}
});
router.get('/mine', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const page = positiveInteger(req.query.page, 1, 1000000);
    const pageSize = positiveInteger(req.query.pageSize, 20, 100);
    const status = req.query.status;
    if (status !== undefined && (typeof status !== 'string' || !Object.values(ListingStatus).includes(status as ListingStatus))) {
      throw new AppError(400, 'INVALID_STATUS', 'Bộ lọc trạng thái không hợp lệ.');
    }
    const where = { ownerId: req.user!.userId, ...(status ? { status: status as ListingStatus } : {}) };
    const [items, totalItems] = await prisma.$transaction([
      prisma.listing.findMany({
        where,
        select: { ...fields, status: true },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      prisma.listing.count({ where }),
    ]);
    res.json({
      success: true,
      data: items.map((item) => ({ ...output(item, true), status: item.status })),
      pagination: { page, pageSize, totalItems, totalPages: Math.ceil(totalItems / pageSize) },
    });
  } catch (error) {
    next(error);
  }
});

router.get('/mine/:id', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
    const listing = await prisma.listing.findFirst({
      where: { id, ownerId: req.user!.userId },
      select: { ...fields, status: true },
    });
    if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
    res.json({ success: true, data: { ...output(listing, true), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.get('/media/:filename', (req: AuthRequest,res,next) => req.headers.authorization ? verifyToken(req,res,next) : next(), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const filename = req.params.filename;
    if (typeof filename !== 'string' || !imageName.test(filename)) throw new AppError(404, 'IMAGE_NOT_FOUND', 'Không tìm thấy ảnh.');
    const mediaListing = await prisma.listing.findFirst({where:{images:{has:imagePrefix+filename}},select:{ownerId:true,status:true,owner:{select:{status:true}}}});
    if (!mediaListing || !(req.user?.role === Role.ADMIN || req.user?.userId === mediaListing.ownerId ||
      (mediaListing.status === ListingStatus.AVAILABLE && mediaListing.owner.status === 'ACTIVE'))) throw new AppError(404,'IMAGE_NOT_FOUND','Không tìm thấy ảnh.');
    const bytes = await readFile(path.join(imageDirectory, filename));
    res.setHeader('Cache-Control', 'private, no-store');
    res.type(path.extname(filename) === '.jpg' ? 'image/jpeg' : `image/${path.extname(filename).slice(1)}`);
    res.send(bytes);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return next(new AppError(404, 'IMAGE_NOT_FOUND', 'Không tìm thấy ảnh.'));
    next(error);
  }
});

router.post('/:id/images', verifyToken, authorizeRoles(Role.USER),
  express.raw({ type: () => true, limit: '5mb' }),
  async (req: AuthRequest, res: Response, next: NextFunction) => {
    let filename = '';
    try {
      const id = req.params.id;
      if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
      const extension = imageExtension(req.headers['content-type']?.split(';')[0], req.body);
      const current = await prisma.listing.findFirst({ where: { id, ownerId: req.user!.userId } });
      if (!current) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
      if (current.status !== ListingStatus.AVAILABLE && current.status !== ListingStatus.HIDDEN && current.status !== ListingStatus.DRAFT && current.status !== ListingStatus.PENDING && current.status !== ListingStatus.REJECTED) throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Tin này không thể sửa ảnh.');
      if (current.images.length >= maxImages) throw new AppError(409, 'IMAGE_LIMIT', 'Mỗi tin được tối đa 20 ảnh.');
      filename = `${randomUUID()}.${extension}`;
      await mkdir(imageDirectory, { recursive: true });
      await writeFile(path.join(imageDirectory, filename), req.body as Buffer, { flag: 'wx' });
      const url = `${imagePrefix}${filename}`;
      const changed = await prisma.listing.updateMany({
        where: { id, ownerId: req.user!.userId, status: current.status, images: { equals: current.images } },
        data: { images: [...current.images, url], status: current.status === ListingStatus.DRAFT ? ListingStatus.DRAFT : ListingStatus.PENDING },
      });
      if (!changed.count) throw new AppError(409, 'LISTING_CHANGED', 'Tin đã thay đổi. Vui lòng thử lại.');
      res.status(201).json({ success: true, data: { url } });
    } catch (error) {
      if (filename) await unlink(path.join(imageDirectory, filename)).catch(() => {});
      next(error);
    }
  });

router.put('/:id/images', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
    const current = await prisma.listing.findFirst({ where: { id, ownerId: req.user!.userId } });
    if (!current) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
    if (!['AVAILABLE','HIDDEN','DRAFT','PENDING','REJECTED'].includes(current.status)) throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Tin này không thể sửa ảnh.');
    if (!req.body || Object.keys(req.body).some((key) => key !== 'images')) throw new AppError(400, 'INVALID_IMAGES', 'Danh sách ảnh không hợp lệ.');
    const images = orderedImages(req.body.images, current.images);
    const changed = await prisma.listing.updateMany({
      where: { id, ownerId: req.user!.userId, status: current.status, images: { equals: current.images } },
      data: { images, status: current.status === ListingStatus.DRAFT ? ListingStatus.DRAFT : ListingStatus.PENDING },
    });
    if (!changed.count) throw new AppError(409, 'LISTING_CHANGED', 'Tin đã thay đổi. Vui lòng thử lại.');
    for (const url of current.images.filter((item) => !images.includes(item))) {
      if (url.startsWith(imagePrefix) && imageName.test(url.slice(imagePrefix.length))) {
        await unlink(path.join(imageDirectory, url.slice(imagePrefix.length))).catch(() => {});
      }
    }
    res.json({ success: true, data: { images } });
  } catch (error) {
    next(error);
  }
});

router.put('/:id', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
    const data = createInput(req.body);
    const listing = await prisma.$transaction(async (tx) => {
      const current = await requireOwnedListing(tx, id, req.user!.userId);
      if (current.status !== ListingStatus.AVAILABLE && current.status !== ListingStatus.HIDDEN && current.status !== ListingStatus.REJECTED && current.status !== ListingStatus.PENDING) {
        throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Chỉ sửa được tin đang hiển thị hoặc đã ẩn.');
      }
      const category = await tx.category.findUnique({ where: { id: data.categoryId } });
      if (!category) {
        throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
      }
      validateAttributes(data.attributes, category.metadata, true);
      await updateOwnedListing(tx, id, req.user!.userId, current.status, {...data,status:ListingStatus.PENDING,reviewReason:null});
      return tx.listing.findUniqueOrThrow({ where: { id }, select: { ...fields, status: true } });
    });
    res.json({ success: true, data: { ...output(listing, true), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/status', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    const target = req.body?.status;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
    if (typeof target !== 'string' || (target !== ListingStatus.AVAILABLE && target !== ListingStatus.HIDDEN && target !== ListingStatus.SOLD && target !== ListingStatus.EXCHANGED) ||
        !req.body || Object.keys(req.body).some((key) => key !== 'status')) {
      throw new AppError(400, 'INVALID_STATUS', 'Trạng thái tin không hợp lệ.');
    }
    const listing = await withQuotaTransaction(async (tx) => {
      const current = await requireOwnedListing(tx, id, req.user!.userId);
      if ((target === ListingStatus.SOLD && !current.allowSale) || (target === ListingStatus.EXCHANGED && !current.allowExchange)) throw new AppError(400,'INVALID_STATUS','Tin không hỗ trợ loại giao dịch này.');
      if (!canChangeListingStatus(current.status, target as ListingStatus)) {
        throw new AppError(409, 'INVALID_STATUS_CHANGE', 'Không thể đổi trạng thái tin theo cách này.');
      }
      if (target === ListingStatus.AVAILABLE) {
        const now = new Date();
        const plan = await storePackageForUser(tx, req.user!.userId, now);
        const usage = await storeUsage(tx, req.user!.userId, now);
        if (usage.active >= plan.package.activeListingLimit) {
          throw new AppError(409, 'ACTIVE_LISTING_LIMIT', 'Bạn đã đạt giới hạn tin đang hoạt động.');
        }
      }
      await updateOwnedListing(tx, id, req.user!.userId, current.status,
        { status: target as ListingStatus });
      return tx.listing.findUniqueOrThrow({ where: { id }, select: { ...fields, status: true } });
    });
    res.json({ success: true, data: { ...output(listing, true), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.get('/favorites',verifyToken,authorizeRoles(Role.USER),async(req:AuthRequest,res,next)=>{
 try{const rows=await prisma.listingFavorite.findMany({where:{userId:req.user!.userId,listing:visible},select:{listing:{select:fields}},take:100,orderBy:{createdAt:'desc'}});res.json({success:true,data:rows.map(row=>output(row.listing))});}catch(error){next(error);}
});
router.put('/:id/favorite',verifyToken,authorizeRoles(Role.USER),async(req:AuthRequest,res,next)=>{
 try{const listing=await prisma.listing.findFirst({where:{...visible,id:req.params.id as string},select:{id:true}});if(!listing)throw new AppError(404,'LISTING_NOT_FOUND','Tin không còn hiển thị.');const key={userId:req.user!.userId,listingId:listing.id};await prisma.listingFavorite.upsert({where:{userId_listingId:key},create:key,update:{}});res.json({success:true});}catch(error){next(error);}
});
router.get('/:id/favorite',verifyToken,authorizeRoles(Role.USER),async(req:AuthRequest,res,next)=>{
  try { const favorite=await prisma.listingFavorite.findUnique({where:{userId_listingId:{userId:req.user!.userId,listingId:req.params.id as string}}});res.json({success:true,data:!!favorite}); } catch(error){next(error);}
});
router.delete('/:id/favorite',verifyToken,authorizeRoles(Role.USER),async(req:AuthRequest,res,next)=>{
 try{await prisma.listingFavorite.deleteMany({where:{userId:req.user!.userId,listingId:req.params.id as string}});res.status(204).send();}catch(error){next(error);}
});

router.get('/recommended', (req:AuthRequest,res,next)=>req.headers.authorization?verifyToken(req,res,next):next(), async (req:AuthRequest,res,next) => {
  try {
    const items = await prisma.listing.findMany({where:{...visible,promotions:{some:{startsAt:{lte:new Date()},endsAt:{gt:new Date()},package:{kind:'FEATURED'}}}},select:fields,take:10,orderBy:{publishedAt:'desc'}});
    const favorites=req.user?await prisma.listingFavorite.findMany({where:{userId:req.user.userId,listingId:{in:items.map(item=>item.id)}},select:{listingId:true}}):[];
    const ids=new Set(favorites.map(row=>row.listingId));
    res.json({success:true,data:items.map(item=>({...output(item),isFeatured:true,isFavorite:ids.has(item.id)}))});
  } catch(error) {next(error);}
});
router.post('/admin/:id/decision', verifyToken, authorizeRoles(Role.ADMIN), async (req: AuthRequest,res,next) => {
  try {
    const {decision,reason,updatedAt}=req.body??{};
    const expected=typeof updatedAt==='string'?new Date(updatedAt):null;
    if (!['APPROVED','REJECTED'].includes(decision) || !expected || Number.isNaN(+expected) || (decision==='REJECTED' && (typeof reason!=='string'||reason.trim().length<5||reason.length>300))) throw new AppError(400,'INVALID_DECISION','Quyết định không hợp lệ.');
    const current=await prisma.listing.findFirst({where:{id:req.params.id as string,status:'PENDING'}});
    if(!current) throw new AppError(404,'LISTING_NOT_FOUND','Không tìm thấy tin chờ duyệt.');
    if(decision==='APPROVED' && !current.images.length) throw new AppError(400,'INVALID_LISTING','Tin cần ít nhất một ảnh.');
    const changed=await prisma.listing.updateMany({where:{id:current.id,status:'PENDING',updatedAt:expected},data:{status:decision==='APPROVED'?'AVAILABLE':'REJECTED',reviewReason:decision==='REJECTED'?reason.trim():null}});
    if(!changed.count) throw new AppError(409,'LISTING_CHANGED','Tin đã thay đổi; tải lại trước khi duyệt.');
    res.json({success:true});
  } catch(error){next(error);}
});
router.get('/admin/pending',verifyToken,authorizeRoles(Role.ADMIN),async(_req,res,next)=>{
  try{const items=await prisma.listing.findMany({where:{status:'PENDING'},select:fields,orderBy:{publishedAt:'asc'},take:100});res.json({success:true,data:items.map(item=>output(item,true))});}catch(error){next(error);}
});

router.get('/:id', (req:AuthRequest,res,next)=>req.headers.authorization?verifyToken(req,res,next):next(), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng.');
    const listing = await prisma.listing.findFirst({
      where: { ...visible, id },
      select: fields,
    });
    if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng.');
    const views=await prisma.$queryRaw<{viewCount:number}[]>`UPDATE "Listing" SET "viewCount"="viewCount"+
      CASE WHEN ${req.user?.role===Role.ADMIN} OR "ownerId"=${req.user?.userId??''} THEN 0 ELSE 1 END
      WHERE id=${id} AND status='AVAILABLE' AND EXISTS(SELECT 1 FROM "User" WHERE id="Listing"."ownerId" AND status='ACTIVE') RETURNING "viewCount"`;
    if(!views.length)throw new AppError(404,'LISTING_NOT_FOUND','Tin không còn hiển thị.');
    listing.viewCount=views[0]!.viewCount;
    res.json({ success: true, data: output(listing) });
  } catch (error) {
    next(error);
  }
});

export default router;
