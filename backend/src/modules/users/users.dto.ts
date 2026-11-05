import type { UserProfile } from './repositories/users.repository.js';

/** Hồ sơ trả cho app: không có password, OTP, authVersion */
export type UserProfileDto = {
  id: string;
  email: string;
  fullName: string | null;
  username: string | null;
  phone: string | null;
  avatarUrl: string | null;
  role: UserProfile['role'];
  status: UserProfile['status'];
  ratingAverage: UserProfile['ratingAverage'];
  ratingCount: number;
  createdAt: Date;
  updatedAt: Date;
};

export const toUserProfileDto = (user: UserProfile): UserProfileDto => ({
  id: user.id,
  email: user.email,
  fullName: user.fullName,
  username: user.username,
  phone: user.phone,
  avatarUrl: user.avatarUrl,
  role: user.role,
  status: user.status,
  ratingAverage: user.ratingAverage,
  ratingCount: user.ratingCount,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});
