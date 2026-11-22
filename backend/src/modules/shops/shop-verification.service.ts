import type { Prisma } from '@prisma/client';
import { audit } from '../../common/audit/admin-audit.js';
import { AppError } from '../../common/errors/app-error.js';
import { ADMIN_PAGE_SIZE } from '../../common/validation/admin-input.js';
import { prisma } from '../../lib/prisma.js';
import type { ShopVerificationBody, ShopVerificationQuery } from './shop-verification.validator.js';

const select = {
  id: true, name: true, tagline: true, description: true, logoUrl: true, coverUrl: true, address: true, createdAt: true,
  verificationType: true, verifiedAt: true, certificateCode: true,
  owner: {
    select: {
      id: true, fullName: true, email: true, status: true,
      storeSubscription: { select: { endsAt: true, package: { select: { tier: true } } } },
    },
  },
} as const satisfies Prisma.ShopSelect;
type ShopRecord = Prisma.ShopGetPayload<{ select: typeof select }>;

/** Shop kèm chủ shop và gói đang dùng (hết hạn thì coi như Cá nhân) */
function toDto({ owner: { storeSubscription: plan, ...owner }, ...shop }: ShopRecord, now: Date) {
  const active = plan && plan.endsAt > now;
  return { ...shop, owner, plan: { tier: active ? plan.package.tier : 'PERSONAL', endsAt: active ? plan.endsAt : null } };
}

/** Shop chờ xác minh (cũ trước) hoặc đã xác minh (mới xác minh trước); q tìm theo tên shop, tên hoặc email chủ shop */
export async function listShops({ status, q, page }: ShopVerificationQuery, now = new Date()) {
  const contains = { contains: q, mode: 'insensitive' as const };
  const where: Prisma.ShopWhereInput = {
    ...(status === 'ALL' ? {} : { verificationType: status === 'VERIFIED' ? { not: null } : null }),
    ...(q ? { OR: [{ name: contains }, { owner: { fullName: contains } }, { owner: { email: contains } }] } : {}),
  };
  const orderBy: Prisma.ShopOrderByWithRelationInput[] = status === 'PENDING'
    ? [{ createdAt: 'asc' }, { id: 'asc' }]
    : [{ verifiedAt: { sort: 'desc', nulls: 'last' } }, { createdAt: 'desc' }, { id: 'asc' }];
  const [items, total, pending] = await Promise.all([
    prisma.shop.findMany({ where, select, orderBy, skip: (page - 1) * ADMIN_PAGE_SIZE, take: ADMIN_PAGE_SIZE }),
    prisma.shop.count({ where }),
    prisma.shop.count({ where: { verificationType: null } }),
  ]);
  return { items: items.map((shop) => toDto(shop, now)), total, page, pending };
}

/** Mã chứng nhận kế tiếp trong năm, VD "RS-2026-00129" (số 5 chữ số nên so chuỗi cũng đúng thứ tự) */
async function nextCertificateCode(tx: Prisma.TransactionClient, now: Date) {
  const prefix = `RS-${now.getUTCFullYear()}-`;
  const last = await tx.shop.findFirst({
    where: { certificateCode: { startsWith: prefix } }, orderBy: { certificateCode: 'desc' }, select: { certificateCode: true },
  });
  // ponytail: hai admin xác minh cùng lúc có thể ra trùng số; thêm unique index trên certificateCode nếu cần chặt
  return prefix + String(Number(last?.certificateCode?.slice(prefix.length) ?? 0) + 1).padStart(5, '0');
}

/**
 * Xác minh (type) hoặc thu hồi xác minh (type null) một shop; ghi nhật ký quản trị.
 * Lỗi 404 SHOP_NOT_FOUND, 409 SHOP_ALREADY_VERIFIED | SHOP_NOT_VERIFIED
 */
export function setVerification(adminId: string, id: string, { type, reason }: ShopVerificationBody, now = new Date()) {
  return prisma.$transaction(async (tx) => {
    const shop = await tx.shop.findUnique({ where: { id }, select: { verificationType: true, certificateCode: true } });
    if (!shop) throw new AppError(404, 'SHOP_NOT_FOUND', 'Không tìm thấy shop.');
    if (type && shop.verificationType) throw new AppError(409, 'SHOP_ALREADY_VERIFIED', 'Shop đã được xác minh.');
    if (!type && !shop.verificationType) throw new AppError(409, 'SHOP_NOT_VERIFIED', 'Shop chưa được xác minh.');
    const data = type
      ? { verificationType: type, verifiedAt: now, certificateCode: await nextCertificateCode(tx, now) }
      : { verificationType: null, verifiedAt: null, certificateCode: null };
    await tx.shop.update({ where: { id }, data });
    await audit(tx, adminId, type ? 'SHOP_VERIFY' : 'SHOP_UNVERIFY', 'SHOP', id, reason,
      { verificationType: shop.verificationType, certificateCode: shop.certificateCode },
      { verificationType: data.verificationType, certificateCode: data.certificateCode });
    return toDto((await tx.shop.findUnique({ where: { id }, select }))!, now);
  });
}
