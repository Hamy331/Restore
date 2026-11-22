import { ADMIN_PAGE_SIZE } from '../../../common/validation/admin-input.js';
import { ROLE_PERMISSIONS } from '../../../common/auth/permissions.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import { sanctionUser } from '../../users/index.js';
import type { UserActionInput, UserListQuery } from '../admin.dto.js';
import * as userRepository from '../repositories/user.repository.js';

/** Hồ sơ của admin đang đăng nhập */
export async function getSelf(id: string) {
  const user = await userRepository.findSelf(id);
  return { ...user, permissions: ROLE_PERMISSIONS[user.role] };
}

/** Thành viên, 25 mỗi trang */
export async function listMembers({ q, status, page, details, type }: UserListQuery, now = new Date()) {
  // details (bảng quản trị web): gói đang dùng planTier (hết hạn = PERSONAL), shop, số tài khoản mỗi phân loại; đếm song song với trang
  const [[items, total], counts] = await Promise.all([
    userRepository.findMemberPage(q, status, (page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE, details, type, now),
    details ? userRepository.countMemberTypes(q, status, now) : undefined,
  ]);
  if (!details) return { items, total, page };
  return {
    items: items.map(({ storeSubscription: subscription, shop: rawShop, ...member }) => {
      const storeSubscription = subscription as { endsAt: Date; package: { tier: string } } | null | undefined;
      const shop = rawShop as { name: string; verificationType: string | null } | null | undefined;
      const active = !!storeSubscription && storeSubscription.endsAt > now;
      return {
        ...member,
        planTier: active ? storeSubscription!.package.tier : 'PERSONAL',
        planEndsAt: active ? storeSubscription!.endsAt : null,
        shop: shop ? { name: shop.name, verified: shop.verificationType !== null } : null,
      };
    }),
    total, page, counts,
  };
}

/** Cảnh cáo / tạm khóa / cấm / mở lại thành viên (logic ở module users) */
export function act(actorId: string, id: string, { action, reason, days, expected }: UserActionInput) {
  return withQuotaTransaction(async (tx) => {
    await sanctionUser(tx, actorId, id, action, reason, days, expected);
    return { updated: true };
  });
}
