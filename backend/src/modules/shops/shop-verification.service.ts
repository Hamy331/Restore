import type { Prisma, ShopStatus, ShopVerificationType } from '@prisma/client';
import { audit } from '../../common/audit/admin-audit.js';
import { AppError } from '../../common/errors/app-error.js';
import { emit } from '../../common/events/domain-events.js';
import { prisma } from '../../lib/prisma.js';
import { isMediaUrl } from '../media/media.service.js';
import { getMyShop } from './my-shop.service.js';
import { nextCertificateCode } from './shop-review.service.js';
import type { ShopVerificationBody } from './my-shop.validator.js';

/**
 * Xin xác minh shop (giấy phép kinh doanh), vào hàng chờ admin. Gửi lại sau khi bị từ chối thì ghi đè hồ sơ cũ.
 * Gửi được ngay sau khi đăng ký (shop đang chờ duyệt) hoặc làm sau; shop bị từ chối thì sửa shop trước.
 * Lỗi 404 SHOP_REQUIRED, 409 SHOP_NOT_APPROVED | SHOP_ALREADY_VERIFIED | VERIFICATION_PENDING, 400 INVALID_IMAGE_URL
 */
export async function submitVerification(userId: string, body: ShopVerificationBody, now = new Date()) {
  const shop = await prisma.shop.findUnique({
    where: { ownerId: userId }, select: { id: true, status: true, verificationType: true, verification: { select: { status: true } } },
  });
  if (!shop) throw new AppError(404, 'SHOP_REQUIRED', 'Bạn chưa có trang shop.');
  if (shop.verificationType) throw new AppError(409, 'SHOP_ALREADY_VERIFIED', 'Shop đã được xác minh.');
  if (shop.status === 'REJECTED') throw new AppError(409, 'SHOP_NOT_APPROVED', 'Sửa shop theo góp ý của ReStore trước khi xin xác minh.');
  if (shop.verification?.status === 'PENDING') throw new AppError(409, 'VERIFICATION_PENDING', 'Hồ sơ xác minh đang chờ duyệt.');
  if (body.documentUrls.some((url) => !isMediaUrl(url, 'verification') || !url.includes(`/verifications/${userId}_`))) {
    throw new AppError(400, 'INVALID_IMAGE_URL', 'Ảnh giấy tờ phải được tải lên qua /media/images?purpose=verification.', 'documentUrls');
  }
  const data = {
    status: 'PENDING' as const, businessName: body.businessName, taxCode: body.taxCode, documentUrls: body.documentUrls,
    submittedAt: now, reviewedAt: null, reviewedById: null, rejectNote: null,
  };
  await prisma.shopVerification.upsert({ where: { shopId: shop.id }, create: { shopId: shop.id, ...data }, update: data });
  return getMyShop(userId, now);
}

const adminSelect = {
  id: true, status: true, businessName: true, taxCode: true, documentUrls: true, submittedAt: true, reviewedAt: true,
  rejectNote: true,
  shop: {
    select: {
      id: true, name: true, logoUrl: true, address: true, status: true, verificationType: true, certificateCode: true,
      owner: { select: { id: true, email: true, fullName: true, phone: true, status: true } },
    },
  },
} as const satisfies Prisma.ShopVerificationSelect;

/** Hồ sơ cho trang admin (100 hồ sơ), chờ duyệt thì gửi lâu nhất trước: { pendingCount, items } */
export async function adminListVerifications(status: ShopStatus | 'ALL') {
  const [items, pendingCount] = await Promise.all([
    prisma.shopVerification.findMany({
      where: status === 'ALL' ? {} : { status },
      select: adminSelect,
      orderBy: status === 'PENDING' ? [{ submittedAt: 'asc' }, { id: 'asc' }] : [{ submittedAt: 'desc' }, { id: 'asc' }],
      take: 100,
    }),
    prisma.shopVerification.count({ where: { status: 'PENDING' } }),
  ]);
  return { pendingCount, items };
}

/** Duyệt / từ chối hồ sơ đang chờ, ghi AdminAudit, rồi báo chủ shop. Lỗi 404 VERIFICATION_NOT_FOUND, 409 VERIFICATION_NOT_PENDING */
async function decide(adminId: string, id: string, decision: { type: ShopVerificationType } | { note: string }, now: Date) {
  const approved = 'type' in decision;
  const record = await prisma.$transaction(async (tx) => {
    const { count } = await tx.shopVerification.updateMany({
      where: { id, status: 'PENDING' },
      data: { status: approved ? 'APPROVED' : 'REJECTED', reviewedAt: now, reviewedById: adminId, rejectNote: approved ? null : decision.note },
    });
    if (!count) {
      const exists = await tx.shopVerification.findUnique({ where: { id }, select: { id: true } });
      if (!exists) throw new AppError(404, 'VERIFICATION_NOT_FOUND', 'Không tìm thấy hồ sơ xác minh.');
      throw new AppError(409, 'VERIFICATION_NOT_PENDING', 'Hồ sơ không còn ở trạng thái chờ duyệt.');
    }
    const { shopId, shop } = await tx.shopVerification.findUniqueOrThrow({
      where: { id }, select: { shopId: true, shop: { select: { verificationType: true, status: true } } },
    });
    // Shop đã được xác minh trực tiếp thì giữ nguyên nhãn và mã cũ. Shop còn chờ duyệt thì duyệt luôn (đã kiểm giấy phép)
    if (approved && !shop.verificationType) {
      await tx.shop.update({
        where: { id: shopId },
        data: {
          verificationType: decision.type, verifiedAt: now, certificateCode: await nextCertificateCode(tx, now),
          ...(shop.status === 'PENDING' ? { status: 'APPROVED' as const, reviewedAt: now } : {}),
        },
      });
    }
    await audit(tx, adminId, approved ? 'SHOP_VERIFY' : 'SHOP_VERIFY_REJECT', 'Shop', shopId,
      approved ? decision.type : decision.note, { status: 'PENDING' }, approved ? { type: decision.type } : { note: decision.note });
    return tx.shopVerification.findUniqueOrThrow({ where: { id }, select: adminSelect });
  });
  // Sau khi commit: báo chủ shop kết quả
  await emit('shop.verificationReviewed', {
    ownerId: record.shop.owner.id, shopId: record.shop.id, shopName: record.shop.name, approved,
    note: approved ? null : decision.note, certificateCode: record.shop.certificateCode,
  });
  return record;
}

export const approveVerification = (adminId: string, id: string, type: ShopVerificationType, now = new Date()) =>
  decide(adminId, id, { type }, now);

export const rejectVerification = (adminId: string, id: string, note: string, now = new Date()) =>
  decide(adminId, id, { note }, now);
