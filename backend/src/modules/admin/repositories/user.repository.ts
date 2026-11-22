import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';
import { adminUserSelect } from '../../users/index.js';
import { MEMBER_TYPES, type MemberType } from '../admin.type.js';

/** Điều kiện lọc theo phân loại; gói hết hạn tính là Cá nhân */
function typeWhere(type: MemberType | undefined, now: Date): Prisma.UserWhereInput {
  if (type === 'ADMIN') return { role: 'ADMIN' };
  if (type === 'BASIC' || type === 'PRO') return { role: 'USER', storeSubscription: { is: { endsAt: { gt: now }, package: { tier: type } } } };
  if (type === 'PERSONAL') {
    return { role: 'USER', NOT: { storeSubscription: { is: { endsAt: { gt: now }, package: { tier: { in: ['BASIC', 'PRO'] } } } } } };
  }
  return { role: 'USER' };
}

/**
 * Thành viên, tìm theo họ tên hoặc email; mới đăng ký trước.
 * Không có type: chỉ role USER (như cũ). details: thêm sđt, số tin, gói đang dùng, shop.
 */
export function findMemberPage(
  q: { name: string; email: string } | undefined,
  status: 'UNVERIFIED' | 'ACTIVE' | 'SUSPENDED' | 'BANNED' | undefined,
  skip: number,
  take: number,
  details: boolean,
  type?: MemberType,
  now = new Date(),
) {
  const where: Prisma.UserWhereInput = {
    ...typeWhere(type, now),
    ...(status ? { status } : {}),
    ...(q ? { OR: [{ fullName: { contains: q.name, mode: 'insensitive' } }, { email: { contains: q.email, mode: 'insensitive' } }, ...(details ? [{ username: { contains:q.name, mode:'insensitive' as const } }, { phone: { contains:q.name } }] : [])] } : {}),
  };
  const extra = details ? {
    phone: true, _count: { select: { listings: true } },
    storeSubscription: { select: { endsAt: true, package: { select: { tier: true } } } },
    shop: { select: { name: true, verificationType: true } },
  } : {};
  // Promise.all thay $transaction: chạy song song trên pool thay vì lần lượt trong một giao dịch
  return Promise.all([
    prisma.user.findMany({ where, select: { ...adminUserSelect, ...extra }, take, skip, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }] }),
    prisma.user.count({ where }),
  ]);
}

/** Số tài khoản mỗi phân loại (cùng ô tìm kiếm và trạng thái) */
export async function countMemberTypes(q: { name: string; email: string } | undefined,
  status: 'UNVERIFIED' | 'ACTIVE' | 'SUSPENDED' | 'BANNED' | undefined, now = new Date()) {
  const search: Prisma.UserWhereInput = {
    ...(status ? { status } : {}),
    ...(q ? { OR: [{ fullName: { contains: q.name, mode: 'insensitive' } }, { email: { contains: q.email, mode: 'insensitive' } },
      { username: { contains: q.name, mode: 'insensitive' } }, { phone: { contains: q.name } }] } : {}),
  };
  const counts = await Promise.all(MEMBER_TYPES.map((type) => prisma.user.count({ where: { AND: [search, typeWhere(type, now)] } })));
  return Object.fromEntries(MEMBER_TYPES.map((type, index) => [type, counts[index]])) as Record<MemberType, number>;
}

