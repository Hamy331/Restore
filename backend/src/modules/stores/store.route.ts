import { NextFunction, Response, Router } from 'express';
import { Role, StoreTier } from '@prisma/client';
import { AppError } from '../../errors/app-error.js';
import { prisma } from '../../lib/prisma.js';
import { AuthRequest, authorizeRoles, verifyToken } from '../../middlewares/auth.middleware.js';
import { storePackageForUser, storeUsage, withQuotaTransaction } from './store.service.js';

const router = Router();
const monthMs = 30 * 86400000;

router.get('/categories', async (_req, res: Response, next: NextFunction) => {
  try {
    res.json({ success: true, data: await prisma.category.findMany({ orderBy: { name: 'asc' } }) });
  } catch (error) {
    next(error);
  }
});

router.get('/packages', async (_req, res: Response, next: NextFunction) => {
  try {
    const packages = await prisma.storePackage.findMany({
      where: { tier: { in: [StoreTier.BASIC, StoreTier.PRO] } },
      orderBy: { priorityLevel: 'asc' },
    });
    res.json({ success: true, data: packages });
  } catch (error) {
    next(error);
  }
});

router.get('/me', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const now = new Date();
    const data = await prisma.$transaction(async (tx) => {
      const current = await storePackageForUser(tx, req.user!.userId, now);
      const usage = await storeUsage(tx, req.user!.userId, now);
      const pendingOrder = await tx.storeOrder.findFirst({
        where: { userId: req.user!.userId, status: 'PENDING' },
        select: { id: true, createdAt: true, amount: true },
        orderBy: { createdAt: 'desc' },
      });
      return {
        package: current.package,
        category: current.category,
        endsAt: current.endsAt,
        pendingOrder,
        usage,
        remaining: {
          listingsToday: Math.max(0, current.package.dailyListingLimit - usage.today),
          activeListings: Math.max(0, current.package.activeListingLimit - usage.active),
          promotionsThisMonth: Math.max(0, current.package.monthlyPromotionQuota - usage.promotionsThisMonth),
        },
      };
    });
    res.json({ success: true, data });
  } catch (error) {
    next(error);
  }
});

router.post('/orders', verifyToken, authorizeRoles(Role.USER), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const packageId = req.body?.packageId;
    const categoryId = req.body?.categoryId;
    if (typeof packageId !== 'string' || typeof categoryId !== 'string' ||
        packageId.length > 100 || categoryId.length > 100) {
      throw new AppError(400, 'INVALID_STORE_ORDER', 'Gói hoặc danh mục không hợp lệ.');
    }
    const order = await withQuotaTransaction(async (tx) => {
      const [storePackage, category, pending] = await Promise.all([
        tx.storePackage.findUnique({ where: { id: packageId } }),
        tx.category.findUnique({ where: { id: categoryId } }),
        tx.storeOrder.findFirst({ where: { userId: req.user!.userId, status: 'PENDING' } }),
      ]);
      if (!storePackage || storePackage.tier === StoreTier.PERSONAL || !category) {
        throw new AppError(404, 'STORE_PACKAGE_NOT_FOUND', 'Gói cửa hàng hoặc danh mục không tồn tại.');
      }
      if (pending) throw new AppError(409, 'STORE_ORDER_PENDING', 'Bạn đã có đơn gói cửa hàng đang chờ xác nhận.');
      return tx.storeOrder.create({
        data: { userId: req.user!.userId, packageId, categoryId, amount: storePackage.monthlyPrice },
        include: { package: true, category: true },
      });
    });
    res.status(201).json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
});

router.get('/admin/orders', verifyToken, authorizeRoles(Role.ADMIN), async (_req, res: Response, next: NextFunction) => {
  try {
    const items = await prisma.storeOrder.findMany({
      where: { status: 'PENDING' },
      include: {
        user: { select: { id: true, email: true, fullName: true } },
        package: true,
        category: true,
      },
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
    if (typeof id !== 'string') throw new AppError(404, 'STORE_ORDER_NOT_FOUND', 'Không tìm thấy đơn gói cửa hàng.');
    const result = await withQuotaTransaction(async (tx) => {
      const now = new Date();
      const order = await tx.storeOrder.findUnique({
        where: { id },
        include: { user: { select: { role: true, status: true } } },
      });
      if (!order || order.status !== 'PENDING') {
        throw new AppError(409, 'STORE_ORDER_NOT_PENDING', 'Đơn không còn ở trạng thái chờ.');
      }
      if (order.user.role !== Role.USER || order.user.status !== 'ACTIVE') {
        throw new AppError(409, 'STORE_USER_UNAVAILABLE', 'Tài khoản mua gói không còn hoạt động.');
      }
      const changed = await tx.storeOrder.updateMany({
        where: { id, status: 'PENDING' },
        data: { status: 'CONFIRMED', decidedAt: now },
      });
      if (!changed.count) throw new AppError(409, 'STORE_ORDER_NOT_PENDING', 'Đơn đã được xử lý.');
      const old = await tx.storeSubscription.findUnique({ where: { userId: order.userId } });
      const base = old && old.endsAt > now && old.packageId === order.packageId &&
        old.categoryId === order.categoryId ? old.endsAt : now;
      const endsAt = new Date(base.getTime() + monthMs);
      const subscription = await tx.storeSubscription.upsert({
        where: { userId: order.userId },
        create: { userId: order.userId, packageId: order.packageId, categoryId: order.categoryId, startsAt: now, endsAt },
        update: { packageId: order.packageId, categoryId: order.categoryId, startsAt: now, endsAt },
        include: { package: true, category: true },
      });
      return { orderId: id, subscription };
    });
    res.json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
});

router.post('/admin/orders/:id/reject', verifyToken, authorizeRoles(Role.ADMIN), async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const id = req.params.id;
    if (typeof id !== 'string') throw new AppError(404, 'STORE_ORDER_NOT_FOUND', 'Không tìm thấy đơn gói cửa hàng.');
    const changed = await prisma.storeOrder.updateMany({
      where: { id, status: 'PENDING' },
      data: { status: 'REJECTED', decidedAt: new Date() },
    });
    if (!changed.count) throw new AppError(409, 'STORE_ORDER_NOT_PENDING', 'Đơn không còn ở trạng thái chờ.');
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

export default router;
