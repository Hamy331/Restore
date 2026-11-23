import { Prisma } from '@prisma/client';
import { AppError } from '../../common/errors/app-error.js';
import { prisma } from '../../lib/prisma.js';
import { withQuotaTransaction } from '../commerce/services/quota.service.js';
import { spendCredits } from '../credits/credit.hold.js';
import { isMediaUrl } from '../media/media.service.js';
import { visible } from '../listings/repositories/listing.repository.js';
import { toShopDto } from './shop.dto.js';
import { shopSelect } from './shop.repository.js';
import {
  SHOP_REGISTRATION_CREDITS, SHOP_TERMS_VERSION, shopNameProblem, type ShopCreateBody, type ShopUpdateBody,
} from './my-shop.validator.js';

/**
 * Quyền theo cửa hàng cho tab Tài khoản và Bảng tin: shopStatus (PENDING | APPROVED | REJECTED | null = chưa đăng ký),
 * isPartner (shop đã duyệt / đã xác minh: có nhãn Đối tác), canPost (đối tác hoặc admin mới đăng bài lên Bảng tin)
 */
export async function sellerAccess(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId }, select: { role: true, shop: { select: { status: true, verificationType: true } } },
  });
  const isPartner = !!user?.shop && (user.shop.status === 'APPROVED' || user.shop.verificationType !== null);
  return { shopStatus: user?.shop?.status ?? null, isPartner, canPost: isPartner || user?.role === 'ADMIN' };
}

/** Bảng tin chỉ cho đối tác và admin đăng bài, người dùng thường chỉ xem, thả tim, bình luận. Lỗi 403 FEED_POST_FORBIDDEN */
export async function assertCanPost(userId: string) {
  if ((await sellerAccess(userId)).canPost) return;
  throw new AppError(403, 'FEED_POST_FORBIDDEN', 'Chỉ cửa hàng đối tác mới đăng bài lên Bảng tin.');
}

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
 *   canCreate (chưa đăng ký cửa hàng), registration { fee (xu), termsVersion } (đăng ký lên cửa hàng),
 *   nameLocked (shop đã duyệt / xác minh thì không tự đổi tên),
 *   stats { followerCount, listingCount, runningPosters, pendingPosters } | null }
 */
export async function getMyShop(userId: string, now = new Date()) {
  const mine = await findMine(userId);
  const base = { registration: { fee: SHOP_REGISTRATION_CREDITS, termsVersion: SHOP_TERMS_VERSION } };
  if (!mine) return { ...base, shop: null, review: null, verification: null, canCreate: true, nameLocked: false, stats: null };
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

/**
 * Đăng ký lên cửa hàng (không phụ thuộc gói tài khoản): đồng ý hợp đồng, trả phí một lần bằng xu, shop vào hàng chờ duyệt.
 * Duyệt xong là Đối tác; xác minh giấy phép làm sau. Lỗi 409 SHOP_EXISTS | NOT_ENOUGH_CREDITS, 400 SHOP_NAME_NOT_ALLOWED
 */
export async function createMyShop(userId: string, body: ShopCreateBody, now = new Date()) {
  assertName(body.name);
  await withQuotaTransaction(async (tx) => {
    if (await tx.shop.findUnique({ where: { ownerId: userId }, select: { id: true } })) {
      throw new AppError(409, 'SHOP_EXISTS', 'Bạn đã có trang shop.');
    }
    await spendCredits(tx, { userId, amount: SHOP_REGISTRATION_CREDITS, note: 'Phí đăng ký lên Cửa hàng' });
    await tx.shop.create({
      data: {
        ownerId: userId, name: body.name, tagline: body.tagline ?? '', description: body.description ?? '',
        address: body.address ?? null, status: 'PENDING', submittedAt: now,
        termsVersion: body.termsVersion, termsAcceptedAt: now, registrationCredits: SHOP_REGISTRATION_CREDITS,
      },
    });
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
