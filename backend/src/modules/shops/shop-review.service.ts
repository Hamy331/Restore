import type { Prisma, ShopStatus } from '@prisma/client';
import { audit } from '../../common/audit/admin-audit.js';
import { AppError } from '../../common/errors/app-error.js';
import { emit } from '../../common/events/domain-events.js';
import { prisma } from '../../lib/prisma.js';

const adminShopSelect = {
  id: true, name: true, tagline: true, description: true, address: true, logoUrl: true, coverUrl: true, accentColor: true,
  status: true, submittedAt: true, reviewedAt: true, rejectNote: true, verificationType: true, verifiedAt: true,
  certificateCode: true, createdAt: true, categoryIds: true,
  owner: {
    select: {
      id: true, email: true, fullName: true, status: true,
      storeSubscription: { select: { endsAt: true, package: { select: { tier: true } } } },
    },
  },
} as const satisfies Prisma.ShopSelect;

type AdminShopRecord = Prisma.ShopGetPayload<{ select: typeof adminShopSelect }>;

/** Shop cho trang duyệt: thông tin shop + owner { id, email, fullName, status } + verified, verificationType, planTier, planEndsAt */
function toAdminShopDto({ owner, verificationType, ...shop }: AdminShopRecord, now: Date) {
  const subscription = owner.storeSubscription;
  return {
    ...shop, verified: verificationType !== null, verificationType,
    owner: { id: owner.id, email: owner.email, fullName: owner.fullName, status: owner.status },
    planTier: subscription && subscription.endsAt > now ? subscription.package.tier : 'PERSONAL',
    planEndsAt: subscription?.endsAt ?? null,
  };
}

/** Danh sách cho admin (100 shop), chờ duyệt thì gửi lâu nhất trước: { pendingCount, items } */
export async function adminListShops(status: ShopStatus | 'ALL', now = new Date()) {
  const [items, pendingCount] = await Promise.all([
    prisma.shop.findMany({
      where: status === 'ALL' ? {} : { status },
      select: adminShopSelect,
      orderBy: status === 'PENDING' ? [{ submittedAt: 'asc' }, { id: 'asc' }] : [{ updatedAt: 'desc' }, { id: 'asc' }],
      take: 100,
    }),
    prisma.shop.count({ where: { status: 'PENDING' } }),
  ]);
  return { pendingCount, items: items.map((shop) => toAdminShopDto(shop, now)) };
}

/** Duyệt / từ chối shop đang chờ duyệt, ghi AdminAudit, rồi báo chủ shop. Lỗi 404 SHOP_NOT_FOUND, 409 SHOP_NOT_PENDING */
async function decide(adminId: string, id: string, status: 'APPROVED' | 'REJECTED', note: string | null, now: Date) {
  const shop = await prisma.$transaction(async (tx) => {
    // Chỉ đổi khi còn chờ duyệt: hai admin bấm cùng lúc thì người sau nhận 409
    const { count } = await tx.shop.updateMany({
      where: { id, status: 'PENDING' }, data: { status, reviewedAt: now, rejectNote: note },
    });
    if (!count) {
      const exists = await tx.shop.findUnique({ where: { id }, select: { id: true } });
      if (!exists) throw new AppError(404, 'SHOP_NOT_FOUND', 'Không tìm thấy shop.');
      throw new AppError(409, 'SHOP_NOT_PENDING', 'Shop không còn ở trạng thái chờ duyệt.');
    }
    await audit(tx, adminId, status === 'APPROVED' ? 'SHOP_APPROVE' : 'SHOP_REJECT', 'Shop', id, note ?? 'approve',
      { status: 'PENDING' }, { status, rejectNote: note });
    return tx.shop.findUniqueOrThrow({ where: { id }, select: adminShopSelect });
  });
  // Sau khi commit: báo chủ shop kết quả duyệt
  await emit('shop.reviewed', {
    ownerId: shop.owner.id, shopId: id, shopName: shop.name, approved: status === 'APPROVED', note,
  });
  return toAdminShopDto(shop, now);
}

export const approveShop = (adminId: string, id: string, now = new Date()) => decide(adminId, id, 'APPROVED', null, now);

export const rejectShop = (adminId: string, id: string, note: string, now = new Date()) =>
  decide(adminId, id, 'REJECTED', note, now);

/** Mã chứng nhận kế tiếp trong năm, VD "RS-2026-00129" (số 5 chữ số nên so chuỗi cũng đúng thứ tự) */
export async function nextCertificateCode(tx: Prisma.TransactionClient, now: Date) {
  const prefix = `RS-${now.getUTCFullYear()}-`;
  const last = await tx.shop.findFirst({
    where: { certificateCode: { startsWith: prefix } }, orderBy: { certificateCode: 'desc' }, select: { certificateCode: true },
  });
  // ponytail: hai admin xác minh cùng lúc có thể ra trùng số; thêm unique index trên certificateCode nếu cần chặt
  return prefix + String(Number(last?.certificateCode?.slice(prefix.length) ?? 0) + 1).padStart(5, '0');
}

/**
 * Xác minh shop đã duyệt (type) để lên "Shop uy tín" với mã chứng nhận, hoặc thu hồi (type null); ghi AdminAudit.
 * Lỗi 404 SHOP_NOT_FOUND, 409 SHOP_NOT_APPROVED | SHOP_ALREADY_VERIFIED | SHOP_NOT_VERIFIED
 */
export function setVerification(adminId: string, id: string, type: 'OFFICIAL_BRAND' | 'CERTIFIED' | null, reason: string,
  now = new Date()) {
  return prisma.$transaction(async (tx) => {
    const shop = await tx.shop.findUnique({ where: { id }, select: { status: true, verificationType: true, certificateCode: true } });
    if (!shop) throw new AppError(404, 'SHOP_NOT_FOUND', 'Không tìm thấy shop.');
    if (type && shop.status !== 'APPROVED') throw new AppError(409, 'SHOP_NOT_APPROVED', 'Chỉ xác minh được shop đã duyệt.');
    if (type && shop.verificationType) throw new AppError(409, 'SHOP_ALREADY_VERIFIED', 'Shop đã được xác minh.');
    if (!type && !shop.verificationType) throw new AppError(409, 'SHOP_NOT_VERIFIED', 'Shop chưa được xác minh.');
    const data = type
      ? { verificationType: type, verifiedAt: now, certificateCode: await nextCertificateCode(tx, now) }
      : { verificationType: null, verifiedAt: null, certificateCode: null };
    await tx.shop.update({ where: { id }, data });
    // Xác minh trực tiếp thì hồ sơ xin xác minh đang chờ (nếu có) coi như đã duyệt
    if (type) {
      await tx.shopVerification.updateMany({
        where: { shopId: id, status: 'PENDING' }, data: { status: 'APPROVED', reviewedAt: now, reviewedById: adminId },
      });
    }
    await audit(tx, adminId, type ? 'SHOP_VERIFY' : 'SHOP_UNVERIFY', 'Shop', id, reason,
      { verificationType: shop.verificationType, certificateCode: shop.certificateCode },
      { verificationType: data.verificationType, certificateCode: data.certificateCode });
    return toAdminShopDto(await tx.shop.findUniqueOrThrow({ where: { id }, select: adminShopSelect }), now);
  });
}
