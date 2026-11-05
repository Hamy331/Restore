import type { Prisma } from '@prisma/client';
import { audit } from '../../../common/audit/admin-audit.js';
import { AppError } from '../../../common/errors/app-error.js';
import { toUserProfileDto } from '../users.dto.js';
import { changed } from '../../../common/validation/admin-input.js';
import * as usersRepository from '../repositories/users.repository.js';

/** Hồ sơ của người đang đăng nhập. Tài khoản không còn ACTIVE coi như hết phiên. */
export async function getMyProfile(userId: string) {
  const user = await usersRepository.findProfileById(userId);
  if (!user || user.status !== 'ACTIVE') {
    throw new AppError(401, 'ACCOUNT_UNAVAILABLE', 'Tài khoản không còn khả dụng.');
  }
  return toUserProfileDto(user);
}

/* ---------- Quản trị thành viên (dùng ở /admin/users và khi xử lý báo cáo) ---------- */

export type SanctionAction = 'WARN' | 'SUSPEND' | 'BAN' | 'RESTORE';

const SANCTION_STATUS = { SUSPEND: 'SUSPENDED', BAN: 'BANNED', RESTORE: 'ACTIVE' } as const;

/** Hồ sơ thành viên cho trang quản trị (null nếu không có) */
export const getAdminUser = (id: string) => usersRepository.findAdminUser(id);

/**
 * Cảnh cáo, tạm khóa [days] ngày, cấm hoặc mở lại tài khoản thành viên đã xác minh, trong transaction [tx].
 * updatedAt phải khớp [expected] (409 ADMIN_STALE nếu không). Khóa/cấm/mở lại thì thu hồi mọi phiên. Ghi AdminAudit.
 */
export async function sanctionUser(tx: Prisma.TransactionClient, actorId: string, id: string, action: SanctionAction,
  reason: string, days: number, expected: Date) {
  const user = await usersRepository.findMember(tx, id);
  if (!user || user.status === 'UNVERIFIED') throw new AppError(409, 'INVALID_USER_ACTION', 'Chỉ xử lý tài khoản thành viên đã xác minh.');
  if (action === 'WARN') {
    if (+user.updatedAt !== +expected) changed(0);
  } else {
    if ((action === 'RESTORE' && !['SUSPENDED', 'BANNED'].includes(user.status)) || (action !== 'RESTORE' && user.status === 'BANNED')) {
      throw new AppError(409, 'INVALID_USER_ACTION', 'Trạng thái tài khoản không phù hợp.');
    }
    changed(await usersRepository.updateMemberStatus(tx, id, expected, {
      status: SANCTION_STATUS[action],
      suspendedUntil: action === 'SUSPEND' ? new Date(Date.now() + days * 86400000) : null,
    }));
    await usersRepository.revokeSessions(tx, id);
  }
  await audit(tx, actorId, action, 'USER', id, reason, user, { days, status: action === 'WARN' ? user.status : SANCTION_STATUS[action] });
}
