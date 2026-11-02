import { AppError } from '../../common/errors/app-error.js';
import { toUserProfileDto } from './users.dto.js';
import * as usersRepository from './users.repository.js';

/** Hồ sơ của người đang đăng nhập. Tài khoản không còn ACTIVE coi như hết phiên. */
export async function getMyProfile(userId: string) {
  const user = await usersRepository.findProfileById(userId);
  if (!user || user.status !== 'ACTIVE') {
    throw new AppError(401, 'ACCOUNT_UNAVAILABLE', 'Tài khoản không còn khả dụng.');
  }
  return toUserProfileDto(user);
}
