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

/* ---------- Quản trị thành viên ---------- */

type Db = Prisma.TransactionClient;

/** Cột trả cho trang quản trị thành viên */
export const adminUserSelect = {
  id: true, email: true, fullName: true, username: true, role: true, status: true,
  suspendedUntil: true, updatedAt: true, createdAt: true,
} as const satisfies Prisma.UserSelect;

export type AdminUser = Prisma.UserGetPayload<{ select: typeof adminUserSelect }>;

export const findAdminUser = (id: string, db: Db = prisma) => db.user.findUnique({ where: { id }, select: adminUserSelect });

export const findMember = (tx: Db, id: string) => tx.user.findFirst({ where: { id, role: 'USER' }, select: adminUserSelect });

/** Đổi trạng thái thành viên khi updatedAt vẫn như lúc đọc; tăng authVersion để token cũ hết hiệu lực. Trả về số dòng đổi. */
export async function updateMemberStatus(tx: Db, id: string, expected: Date,
  data: { status: AdminUser['status']; suspendedUntil: Date | null }) {
  const result = await tx.user.updateMany({ where: { id, role: 'USER', updatedAt: expected }, data: { ...data, authVersion: { increment: 1 } } });
  return result.count;
}

/** Thu hồi mọi phiên đăng nhập còn hiệu lực */
export const revokeSessions = (tx: Db, userId: string) =>
  tx.authSession.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } });
