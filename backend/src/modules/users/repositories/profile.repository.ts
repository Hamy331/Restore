import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';

export const profileSelect = {
  id: true, fullName: true, username: true, avatarUrl: true, bio: true, status: true,
  ratingAverage: true, ratingCount: true, createdAt: true, lastActiveAt: true,
  _count: { select: { followers: true, following: true } },
} satisfies Prisma.UserSelect;


export const findProfile = (id: string) =>
  prisma.user.findUnique({ where: { id }, select: profileSelect });

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
  prisma.user.update({ where: { id }, data, select: profileSelect });

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
