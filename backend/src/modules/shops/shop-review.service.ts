import type { Prisma, ShopStatus } from '@prisma/client';
import { audit } from '../../common/audit/admin-audit.js';
import { AppError } from '../../common/errors/app-error.js';
import { emit } from '../../common/events/domain-events.js';
import { prisma } from '../../lib/prisma.js';

const adminShopSelect = {
  id: true, name: true, tagline: true, description: true, address: true, logoUrl: true, coverUrl: true, accentColor: true,
  status: true, submittedAt: true, reviewedAt: true, rejectNote: true, verificationType: true, createdAt: true,
  owner: {
    select: {
      id: true, email: true, fullName: true, status: true,
      storeSubscription: { select: { endsAt: true, package: { select: { tier: true } } } },
    },
  },
} as const satisfies Prisma.ShopSelect;

type AdminShopRecord = Prisma.ShopGetPayload<{ select: typeof adminShopSelect }>;

/** Shop cho trang duyệt: thông tin shop + owner { id, email, fullName, status } + verified, planTier, planEndsAt */
function toAdminShopDto({ owner, verificationType, ...shop }: AdminShopRecord, now: Date) {
  const subscription = owner.storeSubscription;
  return {
    ...shop, verified: verificationType !== null,
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
