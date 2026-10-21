import { randomUUID } from 'node:crypto';
import { NextFunction, Response, Router } from 'express';
import { PromotionKind, Role, StoreTier } from '@prisma/client';
import { AppError } from '../../errors/app-error.js';
import { prisma } from '../../lib/prisma.js';
import { AuthRequest, authorizeRoles, verifyToken } from '../../middlewares/auth.middleware.js';
import { storePackageForUser, storeUsage, withQuotaTransaction } from '../stores/store.service.js';

const router = Router();

export function promotionPackageInput(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new AppError(400, 'INVALID_PROMOTION_PACKAGE', 'Dữ liệu gói quảng cáo không hợp lệ.');
  }
  const body = value as Record<string, unknown>;
  const name = typeof body.name === 'string' ? body.name.trim() : '';
  const { kind, durationDays, priority, price, active } = body;
  if (name.length < 3 || name.length > 80 ||
      !Object.values(PromotionKind).includes(kind as PromotionKind) ||
      !Number.isInteger(durationDays) || (durationDays as number) < 1 || (durationDays as number) > 30 ||
      !Number.isInteger(priority) || (priority as number) < 0 || (priority as number) > 10 ||
      (kind === PromotionKind.BUMP && priority !== 0) ||
      (kind === PromotionKind.FEATURED && (priority as number) < 1) ||
      typeof price !== 'string' || !/^[1-9]\d{0,11}$/.test(price) || typeof active !== 'boolean') {
    throw new AppError(400, 'INVALID_PROMOTION_PACKAGE', 'Tên, loại, thời lượng, giá hoặc độ ưu tiên không hợp lệ.');
  }
  return { name, kind: kind as PromotionKind, durationDays: durationDays as number,
    priority: priority as number, price: price as string, active: active as boolean };
}

function purchaseInput(body: unknown) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new AppError(400, 'INVALID_PROMOTION', 'Tin đăng hoặc gói quảng cáo không hợp lệ.');
  }
  const { listingId, packageId } = body as Record<string, unknown>;
  if (typeof listingId !== 'string' || typeof packageId !== 'string' ||
      !listingId || !packageId || listingId.length > 100 || packageId.length > 100) {
    throw new AppError(400, 'INVALID_PROMOTION', 'Tin đăng hoặc gói quảng cáo không hợp lệ.');
  }
  return { listingId, packageId };
}

router.get('/packages', async (_req, res: Response, next: NextFunction) => {
  try {
    res.json({ success: true, data: await prisma.promotionPackage.findMany({
      orderBy: [{ kind: 'asc' }, { durationDays: 'asc' }],
    }) });
  } catch (error) {
    next(error);
  }
});

router.post('/packages', verifyToken, authorizeRoles(Role.ADMIN), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const item = await prisma.promotionPackage.create({ data: { id: randomUUID(), ...promotionPackageInput(req.body) } });
    res.status(201).json({ success: true, data: item });
  } catch (error) {
    next(error);
  }
});

router.put('/packages/:id', verifyToken, authorizeRoles(Role.ADMIN), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Không tìm thấy gói quảng cáo.');
    const input = promotionPackageInput(req.body);
    const existing = await prisma.promotionPackage.findUnique({ where: { id }, include: {
      _count: { select: { promotions: true, orders: true } },
    } });
    if (!existing) throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Không tìm thấy gói quảng cáo.');
    if ((existing._count.promotions || existing._count.orders) &&
        (existing.kind !== input.kind || existing.durationDays !== input.durationDays || existing.priority !== input.priority)) {
      throw new AppError(409, 'PROMOTION_PACKAGE_IN_USE', 'Gói đã có giao dịch. Chỉ được sửa tên, giá và trạng thái bán.');
    }
    const changed = await prisma.promotionPackage.updateMany({ where: { id }, data: input });
    if (!changed.count) throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Không tìm thấy gói quảng cáo.');
    res.json({ success: true, data: await prisma.promotionPackage.findUniqueOrThrow({ where: { id } }) });
  } catch (error) {
    next(error);
  }
});

router.get('/my', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const items = await prisma.promotion.findMany({
      where: { userId: req.user!.userId },
      include: { package: true, listing: { select: { id: true, title: true, status: true } } },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    res.json({ success: true, data: items });
  } catch (error) {
    next(error);
  }
});

router.post('/redeem', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { listingId, packageId } = purchaseInput(req.body);
    const item = await withQuotaTransaction(async (tx) => {
      const now = new Date();
      const [listing, promotionPackage, current, usage] = await Promise.all([
        tx.listing.findFirst({ where: { id: listingId, ownerId: req.user!.userId, status: 'AVAILABLE' } }),
        tx.promotionPackage.findFirst({ where: { id: packageId, active: true } }),
        storePackageForUser(tx, req.user!.userId, now),
        storeUsage(tx, req.user!.userId, now),
      ]);
      if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đang hiển thị của bạn.');
      if (!promotionPackage) throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Gói quảng cáo không còn bán.');
      if (current.package.tier === StoreTier.PERSONAL || !listing.categoryId ||
          listing.categoryId !== current.category?.id) {
        throw new AppError(403, 'STORE_CATEGORY_REQUIRED', 'Lượt quảng cáo kèm gói chỉ áp dụng trong danh mục cửa hàng.');
      }
      if (usage.promotionsThisMonth >= current.package.monthlyPromotionQuota) {
        throw new AppError(409, 'PROMOTION_QUOTA_EXHAUSTED', 'Bạn đã dùng hết lượt quảng cáo trong tháng.');
      }
      const existing = await tx.promotion.findFirst({
        where: { listingId, endsAt: { gt: now }, package: { kind: promotionPackage.kind } },
      });
      if (existing) throw new AppError(409, 'PROMOTION_ALREADY_ACTIVE', 'Tin đang có quảng cáo cùng loại.');
      return tx.promotion.create({
        data: { userId: req.user!.userId, listingId, packageId, source: 'INCLUDED',
          startsAt: now, endsAt: new Date(now.getTime() + promotionPackage.durationDays * 86400000) },
        include: { package: true },
      });
    });
    res.status(201).json({ success: true, data: item });
  } catch (error) {
    next(error);
  }
});

router.post('/orders', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const { listingId, packageId } = purchaseInput(req.body);
    const order = await withQuotaTransaction(async (tx) => {
      const [listing, promotionPackage, pending] = await Promise.all([
        tx.listing.findFirst({ where: { id: listingId, ownerId: req.user!.userId, status: 'AVAILABLE' } }),
        tx.promotionPackage.findFirst({ where: { id: packageId, active: true } }),
        tx.promotionOrder.findFirst({ where: { userId: req.user!.userId, listingId, status: 'PENDING' } }),
      ]);
      if (!listing) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin đang hiển thị của bạn.');
      if (!promotionPackage) throw new AppError(404, 'PROMOTION_PACKAGE_NOT_FOUND', 'Gói quảng cáo không còn bán.');
      if (pending) throw new AppError(409, 'PROMOTION_ORDER_PENDING', 'Tin này đã có đơn quảng cáo chờ xác nhận.');
      return tx.promotionOrder.create({
        data: { userId: req.user!.userId, listingId, packageId, amount: promotionPackage.price },
        include: { package: true, listing: { select: { id: true, title: true } } },
      });
    });
    res.status(201).json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/orders', verifyToken, authorizeRoles(Role.ADMIN), async (_req, res: Response, next: NextFunction) => {
  try {
    const items = await prisma.promotionOrder.findMany({
      where: { status: 'PENDING' },
      include: { user: { select: { id: true, email: true, fullName: true } },
        listing: { select: { id: true, title: true, status: true } }, package: true },
      orderBy: { createdAt: 'asc' },
      take: 100,
    });
    res.json({ success: true, data: items });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/orders/:id/confirm', verifyToken, authorizeRoles(Role.ADMIN), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'PROMOTION_ORDER_NOT_FOUND', 'Không tìm thấy đơn quảng cáo.');
    const promotion = await withQuotaTransaction(async (tx) => {
      const now = new Date();
      const order = await tx.promotionOrder.findUnique({
        where: { id }, include: { package: true, user: { select: { role: true, status: true } },
          listing: { select: { ownerId: true, status: true } } },
      });
      if (!order || order.status !== 'PENDING') {
        throw new AppError(409, 'PROMOTION_ORDER_NOT_PENDING', 'Đơn không còn ở trạng thái chờ.');
      }
      if (order.listing.ownerId !== order.userId || order.listing.status !== 'AVAILABLE') {
        throw new AppError(409, 'LISTING_UNAVAILABLE', 'Tin không còn đủ điều kiện quảng cáo.');
      }
      if (order.user.role !== Role.USER || order.user.status !== 'ACTIVE') {
        throw new AppError(409, 'PROMOTION_USER_UNAVAILABLE', 'Tài khoản mua quảng cáo không còn hoạt động.');
      }
      const changed = await tx.promotionOrder.updateMany({
        where: { id, status: 'PENDING' }, data: { status: 'CONFIRMED', decidedAt: now },
      });
      if (!changed.count) throw new AppError(409, 'PROMOTION_ORDER_NOT_PENDING', 'Đơn đã được xử lý.');
      const latest = await tx.promotion.findFirst({
        where: { listingId: order.listingId, endsAt: { gt: now }, package: { kind: order.package.kind } },
        orderBy: { endsAt: 'desc' },
      });
      const startsAt = latest ? latest.endsAt : now;
      return tx.promotion.create({
        data: { userId: order.userId, listingId: order.listingId, packageId: order.packageId,
          source: 'PURCHASED', orderId: id, startsAt,
          endsAt: new Date(startsAt.getTime() + order.package.durationDays * 86400000) },
        include: { package: true },
      });
    });
    res.json({ success: true, data: promotion });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/orders/:id/reject', verifyToken, authorizeRoles(Role.ADMIN), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'PROMOTION_ORDER_NOT_FOUND', 'Không tìm thấy đơn quảng cáo.');
    const changed = await prisma.promotionOrder.updateMany({
      where: { id, status: 'PENDING' }, data: { status: 'REJECTED', decidedAt: new Date() },
    });
    if (!changed.count) throw new AppError(409, 'PROMOTION_ORDER_NOT_PENDING', 'Đơn không còn ở trạng thái chờ.');
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

export default router;
