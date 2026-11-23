import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';

export const profileSelect = {
  id: true, fullName: true, username: true, avatarUrl: true, bio: true, status: true,
  ratingAverage: true, ratingCount: true, createdAt: true, lastActiveAt: true,
  _count: { select: { followers: true, following: true } },
} satisfies Prisma.UserSelect;

/** Số shop uy tín [id] đang theo dõi (theo dõi shop = theo dõi chủ shop, nên nằm trong số "đang theo dõi") */
export const countFollowedShops = (id: string) =>
  prisma.userFollow.count({
    where: { followerId: id, following: { status: 'ACTIVE', shop: { is: { verificationType: { not: null } } } } },
  });


export const findProfile = (id: string) =>
  prisma.user.findUnique({ where: { id }, select: profileSelect });

export async function findStorefront(id: string, viewerId: string) {
  const [user, counts] = await Promise.all([
    prisma.user.findFirst({
      where: { id, status: 'ACTIVE' },
      select: {
        ...profileSelect,
        followers: { where: { followerId: viewerId }, select: { followerId: true } },
        phone: true,
        storeSubscription: { select: { startsAt: true, endsAt: true, package: { select: { tier: true } } } },
        shop: { select: {
          id: true, name: true, address: true, logoUrl: true, coverUrl: true, description: true,
          verificationType: true, status: true,
        } },
      },
    }),
    prisma.listing.groupBy({ by: ['status'], where: { ownerId: id, status: { in: ['AVAILABLE', 'SOLD'] } }, _count: true }),
  ]);
  if (!user) return null;
  const count = (status: 'AVAILABLE' | 'SOLD') => counts.find(row => row.status === status)?._count ?? 0;
  const now = new Date();
  const sub = user.storeSubscription;
  const tier = sub && sub.startsAt <= now && now < sub.endsAt ? sub.package.tier : 'PERSONAL';
  const shop = user.shop;
  // Shop chưa được duyệt (chờ duyệt / bị từ chối) chưa hiện lên trang cá nhân
  const branding = shop && (shop.verificationType || (shop.status === 'APPROVED' && tier === 'PRO')) ? {
    id: shop.id, name: shop.name, address: shop.address, logoUrl: shop.logoUrl,
    coverUrl: shop.coverUrl, description: shop.description, verified: !!shop.verificationType,
    // Theo dõi shop = theo dõi chủ shop: dùng chung số người theo dõi và trạng thái của chủ shop
    followerCount: user._count.followers, isFollowing: user.followers.length > 0,
  } : null;
  const listingCount = count('AVAILABLE');
  return { user, storefront: { tier, shop: branding, listingCount, soldCount: count('SOLD'),
    phone: listingCount > 0 ? user.phone : null } };
}

export const findFollow = (id: string, viewerId: string) =>
  prisma.userFollow.findUnique({
    where: { followerId_followingId: { followerId: viewerId, followingId: id } },
  });

export const findFollows = (id: string, viewerId: string, kind: 'followers' | 'following', page: number, followPageSize: number) => {
  const where = kind === 'followers'
    ? { followingId: id, follower: { status: 'ACTIVE' as const } }
    : { followerId: id, following: { status: 'ACTIVE' as const } };
  const userSelect = {
    id: true, fullName: true, username: true, avatarUrl: true,
    followers: { where: { followerId: viewerId }, select: { followerId: true } },
  } as const;
  return prisma.$transaction([
    prisma.userFollow.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }],
      skip: (page - 1) * followPageSize,
      take: followPageSize,
      select: { follower: { select: userSelect }, following: { select: userSelect } },
    }),
    prisma.userFollow.count({ where }),
  ]);
};

export const updateProfile = (id: string, data: Prisma.UserUpdateInput) =>
  prisma.user.update({ where: { id }, data, select: { ...profileSelect, email: true, phone: true } });

export const touchPresence = (id: string) =>
  prisma.user.update({ where: { id }, data: { lastActiveAt: new Date() }, select: { lastActiveAt: true } });

export const findPeers = (id: string) =>
  prisma.conversationMember.findMany({
    where: { conversation: { members: { some: { userId: id } } }, userId: { not: id } },
    select: { userId: true }, distinct: ['userId'],
  });

export const findTarget = (targetId: string) =>
  prisma.user.findUnique({ where: { id: targetId }, select: { id: true, status: true } });

export const upsertFollow = (selfId: string, targetId: string) =>
  prisma.userFollow.upsert({
    where: { followerId_followingId: { followerId: selfId, followingId: targetId } },
    create: { followerId: selfId, followingId: targetId }, update: {},
  });

export const deleteFollow = (selfId: string, targetId: string) =>
  prisma.userFollow.deleteMany({ where: { followerId: selfId, followingId: targetId } });
