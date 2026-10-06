import express, { Router, Request, Response, NextFunction } from 'express';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../errors/app-error.js';
import { ListingCondition, ListingStatus, Prisma, Role } from '@prisma/client';
import { AuthRequest, authorizeRoles, verifyToken } from '../../middlewares/auth.middleware.js';
import { storePackageForUser, storeUsage, withQuotaTransaction } from '../stores/store.service.js';
import { randomUUID } from 'node:crypto';
import { mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import path from 'node:path';

const router = Router();
const imageDirectory = path.join(process.cwd(), 'uploads', 'listings');
const imagePrefix = '/api/v1/listings/media/';
const maxImages = 6;
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
  condition: true,
  category: { select: { id: true, name: true } },
  images: true,
  createdAt: true,
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
  return {
    q: typeof q === 'string' ? q.trim() : '',
    categoryId: typeof categoryId === 'string' ? categoryId : '',
    condition: typeof condition === 'string' ? condition as ListingCondition : null,
    minPrice: typeof minPrice === 'string' ? minPrice : null,
    maxPrice: typeof maxPrice === 'string' ? maxPrice : null,
  };
}

function output(listing: {
  id: string;
  title: string;
  description: string;
  price: { toString(): string };
  isNegotiable: boolean;
  condition: string;
  category: { id: string; name: string } | null;
  images: string[];
  createdAt: Date;
  owner: { id: string; fullName: string; ratingAverage: number; ratingCount: number };
}) {
  return { ...listing, price: listing.price.toString() };
}

export function createInput(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new AppError(400, 'INVALID_LISTING', 'Dữ liệu tin đăng không hợp lệ.');
  }
  const body = value as Record<string, unknown>;
  if (Object.keys(body).some((key) => !['title', 'description', 'price', 'condition', 'isNegotiable', 'categoryId'].includes(key))) {
    throw new AppError(400, 'INVALID_LISTING', 'Tin đăng có trường dữ liệu chưa được hỗ trợ.');
  }
  const title = typeof body.title === 'string' ? body.title.trim() : '';
  const description = typeof body.description === 'string' ? body.description.trim() : '';
  const price = body.price;
  const condition = body.condition;
  const categoryId = body.categoryId;
  if (typeof categoryId !== 'string' || categoryId.length < 1 || categoryId.length > 100) {
    throw new AppError(400, 'INVALID_LISTING', 'Danh mục không hợp lệ.', 'categoryId');
  }
  if (title.length < 5 || title.length > 120) {
    throw new AppError(400, 'INVALID_LISTING', 'Tiêu đề cần từ 5 đến 120 ký tự.', 'title');
  }
  if (description.length < 20 || description.length > 5000) {
    throw new AppError(400, 'INVALID_LISTING', 'Mô tả cần từ 20 đến 5000 ký tự.', 'description');
  }
  if (typeof price !== 'string' || !/^[1-9]\d{0,11}$/.test(price)) {
    throw new AppError(400, 'INVALID_LISTING', 'Giá phải là số nguyên VND từ 1 đến 999999999999.', 'price');
  }
  if (typeof condition !== 'string' || !Object.values(ListingCondition).includes(condition as ListingCondition)) {
    throw new AppError(400, 'INVALID_LISTING', 'Tình trạng sản phẩm không hợp lệ.', 'condition');
  }
  if (typeof body.isNegotiable !== 'boolean') {
    throw new AppError(400, 'INVALID_LISTING', 'Thông tin thương lượng không hợp lệ.', 'isNegotiable');
  }
  return { title, description, price, categoryId, condition: condition as ListingCondition, isNegotiable: body.isNegotiable };
}

export function draftInput(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new AppError(400, 'INVALID_DRAFT', 'Dữ liệu nháp không hợp lệ.');
  }
  const body = value as Record<string, unknown>;
  if (Object.keys(body).some((key) => !['title', 'description', 'price', 'condition', 'isNegotiable', 'categoryId'].includes(key))) {
    throw new AppError(400, 'INVALID_DRAFT', 'Bản nháp có trường dữ liệu chưa được hỗ trợ.');
  }
  const title = body.title ?? '';
  const description = body.description ?? '';
  const price = body.price === '' || body.price == null ? '0' : body.price;
  const condition = body.condition ?? ListingCondition.USED_GOOD;
  const categoryId = body.categoryId === '' || body.categoryId == null ? null : body.categoryId;
  const isNegotiable = body.isNegotiable ?? true;
  if (typeof title !== 'string' || title.trim().length > 120 ||
      typeof description !== 'string' || description.trim().length > 5000 ||
      typeof price !== 'string' || !/^(0|[1-9]\d{0,11})$/.test(price) ||
      typeof condition !== 'string' || !Object.values(ListingCondition).includes(condition as ListingCondition) ||
      (categoryId !== null && (typeof categoryId !== 'string' || categoryId.length > 100)) ||
      typeof isNegotiable !== 'boolean') {
    throw new AppError(400, 'INVALID_DRAFT', 'Trường dữ liệu bản nháp không hợp lệ.');
  }
  return { title: title.trim(), description: description.trim(), price,
    condition: condition as ListingCondition, categoryId, isNegotiable };
}

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
  return (current === ListingStatus.AVAILABLE && (target === ListingStatus.HIDDEN || target === ListingStatus.SOLD)) ||
    (current === ListingStatus.HIDDEN && (target === ListingStatus.AVAILABLE || target === ListingStatus.SOLD));
}

router.post('/', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const data = createInput(req.body);
    const listing = await withQuotaTransaction(async (tx) => {
      const now = new Date();
      const category = await tx.category.findUnique({ where: { id: data.categoryId } });
      if (!category) throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
      const current = await storePackageForUser(tx, req.user!.userId, now);
      const usage = await storeUsage(tx, req.user!.userId, now);
      if (usage.today >= current.package.dailyListingLimit) {
        throw new AppError(409, 'DAILY_LISTING_LIMIT', 'Bạn đã dùng hết lượt đăng tin trong ngày.');
      }
      if (usage.active >= current.package.activeListingLimit) {
        throw new AppError(409, 'ACTIVE_LISTING_LIMIT', 'Bạn đã đạt giới hạn tin đang hoạt động.');
      }
      return tx.listing.create({
        data: { ...data, ownerId: req.user!.userId, images: [], publishedAt: now },
        select: fields,
      });
    });
    res.status(201).json({ success: true, data: output(listing) });
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
    res.status(201).json({ success: true, data: { ...output(listing), status: listing.status } });
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
      if (current.status !== ListingStatus.DRAFT) throw new AppError(409, 'DRAFT_CHANGED', 'Tin này không còn là bản nháp.');
      if (data.categoryId && !await tx.category.findUnique({ where: { id: data.categoryId } })) {
        throw new AppError(400, 'INVALID_DRAFT', 'Danh mục không tồn tại.', 'categoryId');
      }
      await updateOwnedListing(tx, id, req.user!.userId, ListingStatus.DRAFT, data);
      return tx.listing.findUniqueOrThrow({ where: { id }, select: { ...fields, status: true } });
    });
    res.json({ success: true, data: { ...output(listing), status: listing.status } });
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
      if (current.status !== ListingStatus.DRAFT) throw new AppError(409, 'DRAFT_CHANGED', 'Tin này không còn là bản nháp.');
      const data = createInput({
        title: current.title, description: current.description,
        price: current.price.toString(), condition: current.condition,
        categoryId: current.categoryId, isNegotiable: current.isNegotiable,
      });
      if (!await tx.category.findUnique({ where: { id: data.categoryId } })) {
        throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
      }
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
        { status: ListingStatus.AVAILABLE, publishedAt: now });
      return tx.listing.findUniqueOrThrow({ where: { id }, select: { ...fields, status: true } });
    });
    res.json({ success: true, data: { ...output(listing), status: listing.status } });
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

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const page = positiveInteger(req.query.page, 1, 1000000);
    const pageSize = positiveInteger(req.query.pageSize, 12, 50);
    const filters = listingFilters(req.query);
    const where: Prisma.ListingWhereInput = {
      ...visible,
      ...(filters.q ? { title: { contains: filters.q, mode: 'insensitive' } } : {}),
      ...(filters.categoryId ? { categoryId: filters.categoryId } : {}),
      ...(filters.condition ? { condition: filters.condition } : {}),
      ...(filters.minPrice || filters.maxPrice ? { price: {
        ...(filters.minPrice ? { gte: new Prisma.Decimal(filters.minPrice) } : {}),
        ...(filters.maxPrice ? { lte: new Prisma.Decimal(filters.maxPrice) } : {}),
      } } : {}),
    };
    const now = new Date();
    const [ranked, totalItems] = await prisma.$transaction([
      prisma.$queryRaw<{ id: string }[]>`
        SELECT l.id
        FROM "Listing" l
        JOIN "User" u ON u.id = l."ownerId" AND u.status = 'ACTIVE'
        LEFT JOIN "StoreSubscription" ss ON ss."userId" = l."ownerId"
          AND ss."startsAt" <= ${now} AND ss."endsAt" > ${now}
        LEFT JOIN "StorePackage" sp ON sp.id = ss."packageId"
        LEFT JOIN LATERAL (
          SELECT
            MAX(CASE WHEN pp.kind = 'FEATURED' AND p."endsAt" > ${now}
              THEN pp.priority END) AS "featuredPriority",
            MAX(CASE WHEN pp.kind = 'BUMP' AND p."startsAt" <= ${now}
              THEN p."startsAt" + LEAST(pp."durationDays" - 1,
                FLOOR(EXTRACT(EPOCH FROM (${now} - p."startsAt")) / 86400)::integer)
                * INTERVAL '1 day' END) AS "bumpedAt"
          FROM "Promotion" p
          JOIN "PromotionPackage" pp ON pp.id = p."packageId"
          WHERE p."listingId" = l.id AND p."startsAt" <= ${now}
        ) boosted ON TRUE
        WHERE l.status = 'AVAILABLE'
          AND (${filters.q} = '' OR POSITION(LOWER(${filters.q}) IN LOWER(l.title)) > 0)
          AND (${filters.categoryId} = '' OR l."categoryId" = ${filters.categoryId})
          AND (${filters.condition}::text IS NULL OR l.condition = ${filters.condition}::"ListingCondition")
          AND (${filters.minPrice}::numeric IS NULL OR l.price >= ${filters.minPrice}::numeric)
          AND (${filters.maxPrice}::numeric IS NULL OR l.price <= ${filters.maxPrice}::numeric)
        ORDER BY COALESCE(boosted."featuredPriority", 0) DESC,
          CASE WHEN ss."categoryId" = l."categoryId" THEN COALESCE(sp."priorityLevel", 0) ELSE 0 END DESC,
          GREATEST(COALESCE(l."publishedAt", l."createdAt"),
            COALESCE(boosted."bumpedAt", l."createdAt")) DESC,
          COALESCE(l."publishedAt", l."createdAt") DESC, l.id DESC
        LIMIT ${pageSize} OFFSET ${(page - 1) * pageSize}
      `,
      prisma.listing.count({ where }),
    ]);
    const items = ranked.length
      ? await prisma.listing.findMany({ where: { id: { in: ranked.map((row) => row.id) } }, select: fields })
      : [];
    const byId = new Map(items.map((item) => [item.id, item]));
    res.json({
      success: true,
      data: ranked.flatMap((row) => {
        const item = byId.get(row.id);
        return item ? [output(item)] : [];
      }),
      pagination: { page, pageSize, totalItems, totalPages: Math.ceil(totalItems / pageSize) },
    });
  } catch (error) {
    next(error);
  }
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
      data: items.map((item) => ({ ...output(item), status: item.status })),
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
    res.json({ success: true, data: { ...output(listing), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.get('/media/:filename', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const filename = req.params.filename;
    if (typeof filename !== 'string' || !imageName.test(filename)) throw new AppError(404, 'IMAGE_NOT_FOUND', 'Không tìm thấy ảnh.');
    const bytes = await readFile(path.join(imageDirectory, filename));
    res.setHeader('Cache-Control', 'public, max-age=86400');
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
      if (current.status !== ListingStatus.AVAILABLE && current.status !== ListingStatus.HIDDEN && current.status !== ListingStatus.DRAFT) throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Tin này không thể sửa ảnh.');
      if (current.images.length >= maxImages) throw new AppError(409, 'IMAGE_LIMIT', 'Mỗi tin được tối đa 6 ảnh.');
      filename = `${randomUUID()}.${extension}`;
      await mkdir(imageDirectory, { recursive: true });
      await writeFile(path.join(imageDirectory, filename), req.body as Buffer, { flag: 'wx' });
      const url = `${imagePrefix}${filename}`;
      const changed = await prisma.listing.updateMany({
        where: { id, ownerId: req.user!.userId, status: current.status, images: { equals: current.images } },
        data: { images: [...current.images, url] },
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
    if (current.status !== ListingStatus.AVAILABLE && current.status !== ListingStatus.HIDDEN && current.status !== ListingStatus.DRAFT) throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Tin này không thể sửa ảnh.');
    if (!req.body || Object.keys(req.body).some((key) => key !== 'images')) throw new AppError(400, 'INVALID_IMAGES', 'Danh sách ảnh không hợp lệ.');
    const images = orderedImages(req.body.images, current.images);
    const changed = await prisma.listing.updateMany({
      where: { id, ownerId: req.user!.userId, status: current.status, images: { equals: current.images } },
      data: { images },
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
      if (current.status !== ListingStatus.AVAILABLE && current.status !== ListingStatus.HIDDEN) {
        throw new AppError(409, 'LISTING_NOT_EDITABLE', 'Chỉ sửa được tin đang hiển thị hoặc đã ẩn.');
      }
      if (!await tx.category.findUnique({ where: { id: data.categoryId } })) {
        throw new AppError(400, 'INVALID_LISTING', 'Danh mục không tồn tại.', 'categoryId');
      }
      await updateOwnedListing(tx, id, req.user!.userId, current.status, data);
      return tx.listing.findUniqueOrThrow({ where: { id }, select: { ...fields, status: true } });
    });
    res.json({ success: true, data: { ...output(listing), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.patch('/:id/status', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    const target = req.body?.status;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng của bạn.');
    if (typeof target !== 'string' || (target !== ListingStatus.AVAILABLE && target !== ListingStatus.HIDDEN && target !== ListingStatus.SOLD) ||
        !req.body || Object.keys(req.body).some((key) => key !== 'status')) {
      throw new AppError(400, 'INVALID_STATUS', 'Trạng thái tin không hợp lệ.');
    }
    const listing = await withQuotaTransaction(async (tx) => {
      const current = await requireOwnedListing(tx, id, req.user!.userId);
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
    res.json({ success: true, data: { ...output(listing), status: listing.status } });
  } catch (error) {
    next(error);
  }
});

router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng.');
    const listing = await prisma.listing.findFirst({
      where: { ...visible, id },
      select: fields,
    });
    if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đăng.');
    res.json({ success: true, data: output(listing) });
  } catch (error) {
    next(error);
  }
});

export default router;
