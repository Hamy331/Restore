import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { adminUserSelect } from '../../users/index.js';

/** Thành viên (role USER), tìm theo họ tên hoặc email; mới đăng ký trước */
export function findMemberPage(q: { name: string; email: string } | undefined, skip: number, take: number) {
  const where: Prisma.UserWhereInput = {
    role: 'USER',
    ...(q ? { OR: [{ fullName: { contains: q.name, mode: 'insensitive' } }, { email: { contains: q.email, mode: 'insensitive' } }] } : {}),
  };
  return prisma.$transaction([
    prisma.user.findMany({ where, select: adminUserSelect, take, skip, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }] }),
    prisma.user.count({ where }),
  ]);
}

export const findSelf = (id: string) => prisma.user.findUniqueOrThrow({ where: { id }, select: adminUserSelect });
