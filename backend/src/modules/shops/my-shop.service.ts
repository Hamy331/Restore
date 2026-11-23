import { Prisma } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import { prisma } from '../../lib/prisma.js';
import { storePackageForUser } from '../commerce/services/quota.service.js';
import { isMediaUrl } from '../media/media.service.js';
import { visible } from '../listings/repositories/listing.repository.js';
import { toShopDto } from './shop.dto.js';
import { shopSelect } from './shop.repository.js';
import { shopNameProblem, type ShopCreateBody, type ShopUpdateBody } from './my-shop.validator.js';

/** Gói Cửa hàng (tier PRO) mới được mở shop */
const STORE_TIER = 'PRO';

const findMine = (ownerId: string) => prisma.shop.findUnique({
  where: { ownerId },
  select: {
    ...shopSelect, status: true, rejectNote: true, reviewedAt: true,
    verification: { select: { status: true, rejectNote: true, submittedAt: true, reviewedAt: true } },
  },
});

/**
 * Trang Quản lý shop: { shop (Shop như GET /shops/:id, kể cả khi chưa duyệt) | null,
 *   review { status (PENDING | APPROVED | REJECTED), rejectNote, reviewedAt } | null,
 *   verification { status, rejectNote, submittedAt, reviewedAt } | null (hồ sơ xin xác minh gần nhất),
 *   storePlan (đang dùng gói Cửa hàng), canCreate, nameLocked (shop đã duyệt / xác minh thì không tự đổi tên),
 *   planEndsAt, stats { followerCount, listingCount, runningPosters, pendingPosters } | null }
 */
export async function getMyShop(userId: string, now = new Date()) {
  const [mine, plan] = await Promise.all([findMine(userId), storePackageForUser(prisma, userId, now)]);
  const storePlan = plan.package.tier === STORE_TIER;
  const base = { storePlan, planEndsAt: plan.endsAt };
  if (!mine) return { ...base, shop: null, review: null, verification: null, canCreate: storePlan, nameLocked: false, stats: null };
  const { status, rejectNote, reviewedAt, verification, ...shop } = mine;
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
    review: { status, rejectNote, reviewedAt },
    verification,
    canCreate: false,
    nameLocked: status === 'APPROVED' || shop.verificationType !== null,
    stats: { followerCount: shop.owner._count.followers, listingCount, runningPosters, pendingPosters },
  };
}

/** Tên có số điện thoại, đường dẫn web hoặc từ quảng cáo quá mức thì 400 SHOP_NAME_NOT_ALLOWED */
function assertName(name: string | undefined) {
  const rule = name === undefined ? null : shopNameProblem(name);
  if (rule) {
    throw new AppError(400, 'SHOP_NAME_NOT_ALLOWED',
      'Tên shop không được chứa số điện thoại, đường dẫn web hoặc từ ngữ như "số 1", "tốt nhất", "chính hãng".', 'name', { rule });
  }
}

/** Mở shop, vào hàng chờ duyệt. Lỗi 403 SHOP_PLAN_REQUIRED, 409 SHOP_EXISTS, 400 SHOP_NAME_NOT_ALLOWED */
export async function createMyShop(userId: string, body: ShopCreateBody, now = new Date()) {
  assertName(body.name);
  const plan = await storePackageForUser(prisma, userId, now);
  if (plan.package.tier !== STORE_TIER) {
    throw new AppError(403, 'SHOP_PLAN_REQUIRED', 'Chỉ gói Cửa hàng Pro mới mở được trang shop.', undefined,
      { tier: plan.package.tier });
  }
  if (await prisma.shop.findUnique({ where: { ownerId: userId }, select: { id: true } })) {
    throw new AppError(409, 'SHOP_EXISTS', 'Bạn đã có trang shop.');
  }
  await prisma.shop.create({
    data: {
      ownerId: userId, name: body.name, tagline: body.tagline ?? '', description: body.description ?? '',
      address: body.address ?? null, status: 'PENDING', submittedAt: now,
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

/**
 * Sửa thông tin shop. Shop bị từ chối thì lưu xong là gửi duyệt lại. Shop đã duyệt / xác minh thì không đổi tên.
 * Lỗi 404 SHOP_REQUIRED, 409 SHOP_NAME_LOCKED, 400 INVALID_IMAGE_URL | SHOP_NAME_NOT_ALLOWED
 */
export async function updateMyShop(userId: string, body: ShopUpdateBody, now = new Date()) {
  const shop = await prisma.shop.findUnique({
    where: { ownerId: userId }, select: { id: true, name: true, verificationType: true, status: true },
  });
  if (!shop) throw new AppError(404, 'SHOP_REQUIRED', 'Bạn chưa có trang shop.');
  const renamed = body.name !== undefined && body.name !== shop.name;
  if (renamed && (shop.status === 'APPROVED' || shop.verificationType !== null)) {
    throw new AppError(409, 'SHOP_NAME_LOCKED', 'Shop đã được duyệt, liên hệ ReStore để đổi tên.', 'name');
  }
  if (renamed) assertName(body.name);
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
      openingHours: body.openingHours === null ? Prisma.DbNull : body.openingHours,
      ...(shop.status === 'REJECTED' ? { status: 'PENDING', submittedAt: now, rejectNote: null, reviewedAt: null } : {}),
    },
  });
  return getMyShop(userId, now);
}
