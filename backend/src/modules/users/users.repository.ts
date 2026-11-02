import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';

/** Các cột được phép trả ra ngoài: không có password, OTP, authVersion. */
export const profileSelect = {
  id: true,
  email: true,
  fullName: true,
  username: true,
  phone: true,
  avatarUrl: true,
  role: true,
  status: true,
  ratingAverage: true,
  ratingCount: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.UserSelect;

export type UserProfile = Prisma.UserGetPayload<{ select: typeof profileSelect }>;

export const findProfileById = (id: string) =>
  prisma.user.findUnique({ where: { id }, select: profileSelect });
