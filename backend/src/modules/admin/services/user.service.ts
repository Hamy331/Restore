import { ADMIN_PAGE_SIZE } from '../../../common/validation/admin-input.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import { sanctionUser } from '../../users/index.js';
import type { UserActionInput, UserListQuery } from '../admin.dto.js';
import * as userRepository from '../repositories/user.repository.js';

/** Hồ sơ của admin đang đăng nhập */
export const getSelf = (id: string) => userRepository.findSelf(id);

/** Thành viên, 25 mỗi trang */
export async function listMembers({ q, page }: UserListQuery) {
  const [items, total] = await userRepository.findMemberPage(q, (page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  return { items, total, page };
}

/** Cảnh cáo / tạm khóa / cấm / mở lại thành viên (logic ở module users) */
export function act(actorId: string, id: string, { action, reason, days, expected }: UserActionInput) {
  return withQuotaTransaction(async (tx) => {
    await sanctionUser(tx, actorId, id, action, reason, days, expected);
    return { updated: true };
  });
}
