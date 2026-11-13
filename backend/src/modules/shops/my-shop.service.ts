import { AppError } from '../../common/errors/app-error.js';
import { prisma } from '../../lib/prisma.js';
import { storePackageForUser } from '../commerce/services/quota.service.js';
import { isMediaUrl } from '../media/media.service.js';
import { visible } from '../listings/repositories/listing.repository.js';
import { toShopDto } from './shop.dto.js';
import { shopSelect } from './shop.repository.js';
import type { ShopCreateBody, ShopUpdateBody } from './my-shop.validator.js';

/** Gói Cửa hàng (tier PRO) mới được mở shop */
const STORE_TIER = 'PRO';

const findMine = (ownerId: string) => prisma.shop.findUnique({ where: { ownerId }, select: shopSelect });

/**
 * Trang Quản lý shop: { shop (Shop như GET /shops/:id, kể cả khi chưa xác minh) | null,
 *   storePlan (đang dùng gói Cửa hàng), canCreate, nameLocked (shop đã xác minh thì không tự đổi tên),
 *   planEndsAt, stats { followerCount, listingCount, runningPosters, pendingPosters } | null }
 */
export async function getMyShop(userId: string, now = new Date()) {
  const [shop, plan] = await Promise.all([findMine(userId), storePackageForUser(prisma, userId, now)]);
  const storePlan = plan.package.tier === STORE_TIER;
  const base = { storePlan, planEndsAt: plan.endsAt };
  if (!shop) return { ...base, shop: null, canCreate: storePlan, nameLocked: false, stats: null };
  const [listingCount, runningPosters, pendingPosters] = await Promise.all([
    prisma.listing.count({ where: { ...visible, ownerId: userId } }),
    prisma.shopBanner.count({
      where: {
        shopId: shop.id, status: 'APPROVED',
        AND: [{ OR: [{ startsAt: null }, { startsAt: { lte: now } }] }, { OR: [{ endsAt: null }, { endsAt: { gt: now } }] }],
      },
    }),
    prisma.shopBanner.count({ where: { shopId: shop.id, status: 'PENDING' } }),
  ]);
  return {
    ...base,
    shop: toShopDto(shop, { listingCount, isFollowing: false }),
    canCreate: false,
    nameLocked: shop.verificationType !== null,
    stats: { followerCount: shop._count.followers, listingCount, runningPosters, pendingPosters },
  };
}

/** Mở shop. Lỗi 403 SHOP_PLAN_REQUIRED, 409 SHOP_EXISTS */
export async function createMyShop(userId: string, body: ShopCreateBody, now = new Date()) {
  const plan = await storePackageForUser(prisma, userId, now);
  if (plan.package.tier !== STORE_TIER) {
    throw new AppError(403, 'SHOP_PLAN_REQUIRED', 'Chỉ gói Cửa hàng mới mở được trang shop.', undefined,
      { tier: plan.package.tier });
  }
  if (await prisma.shop.findUnique({ where: { ownerId: userId }, select: { id: true } })) {
    throw new AppError(409, 'SHOP_EXISTS', 'Bạn đã có trang shop.');
  }
  await prisma.shop.create({
    data: {
      ownerId: userId, name: body.name, tagline: body.tagline ?? '', description: body.description ?? '',
      address: body.address ?? null,
    },
  });
  return getMyShop(userId, now);
}

function assertOwnImage(userId: string, field: 'logoUrl' | 'coverUrl', url: string | null | undefined) {
  if (!url) return;
  if (!isMediaUrl(url, 'shop') || !url.includes(`/shops/${userId}_`)) {
    throw new AppError(400, 'INVALID_IMAGE_URL', 'Ảnh shop phải được tải lên qua /media/images?purpose=shop.', field);
  }
}

/** Sửa thông tin shop. Lỗi 404 SHOP_REQUIRED, 409 SHOP_NAME_LOCKED, 400 INVALID_IMAGE_URL */
export async function updateMyShop(userId: string, body: ShopUpdateBody, now = new Date()) {
  const shop = await prisma.shop.findUnique({ where: { ownerId: userId }, select: { id: true, name: true, verificationType: true } });
  if (!shop) throw new AppError(404, 'SHOP_REQUIRED', 'Bạn chưa có trang shop.');
  if (body.name !== undefined && body.name !== shop.name && shop.verificationType !== null) {
    throw new AppError(409, 'SHOP_NAME_LOCKED', 'Shop đã xác minh, liên hệ ReStore để đổi tên.', 'name');
  }
  assertOwnImage(userId, 'logoUrl', body.logoUrl);
  assertOwnImage(userId, 'coverUrl', body.coverUrl);
  await prisma.shop.update({
    where: { id: shop.id },
    data: {
      name: body.name,
      tagline: body.tagline === undefined ? undefined : body.tagline ?? '',
      description: body.description === undefined ? undefined : body.description ?? '',
      address: body.address,
      logoUrl: body.logoUrl,
      coverUrl: body.coverUrl,
      accentColor: body.accentColor,
    },
  });
  return getMyShop(userId, now);
}
