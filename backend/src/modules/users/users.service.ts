import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { AppError } from '../../errors/app-error.js';
import { parseFullName, parseUsername } from '../auth/auth.validation.js';
import { publish } from '../chat/chat.events.js';

const profileSelect = {
  id: true, fullName: true, username: true, avatarUrl: true, bio: true, status: true,
  ratingAverage: true, ratingCount: true, createdAt: true, lastActiveAt: true,
  _count: { select: { followers: true, following: true } },
} satisfies Prisma.UserSelect;

const onlineThresholdMs = 2 * 60 * 1000;
type ProfileRow = Prisma.UserGetPayload<{ select: typeof profileSelect }>;
const formatProfile = (user: ProfileRow) => ({
  id: user.id,
  fullName: user.fullName,
  username: user.username,
  avatarUrl: user.avatarUrl,
  bio: user.bio,
  ratingAverage: user.ratingAverage,
  ratingCount: user.ratingCount,
  createdAt: user.createdAt,
  followerCount: user._count.followers,
  followingCount: user._count.following,
  presence: {
    isOnline: !!user.lastActiveAt && Date.now() - new Date(user.lastActiveAt).getTime() < onlineThresholdMs,
    lastActiveAt: user.lastActiveAt,
  },
});

export const getProfile = async (id: string) => {
  const user = await prisma.user.findUnique({ where: { id }, select: profileSelect });
  if (!user || user.status !== 'ACTIVE') {
    throw new AppError(404, 'USER_NOT_FOUND', 'Không tìm thấy người dùng.');
  }
  return formatProfile(user);
};

export const updateProfile = async (id: string, body: unknown) => {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    throw new AppError(422, 'INVALID_PROFILE', 'Thông tin hồ sơ không hợp lệ.');
  }
  const input = body as Record<string, unknown>;
  const allowed = ['fullName', 'username', 'bio', 'avatarUrl'];
  if (!Object.keys(input).length || Object.keys(input).some((key) => !allowed.includes(key))) {
    throw new AppError(422, 'INVALID_PROFILE_FIELDS', 'Hồ sơ chứa trường không hợp lệ.');
  }
  const data: Prisma.UserUpdateInput = {};
  if ('fullName' in input) data.fullName = parseFullName(input.fullName);
  if ('username' in input) data.username = parseUsername(input.username);
  if ('bio' in input) {
    if (input.bio !== null && (typeof input.bio !== 'string' || input.bio.trim().length > 300)) {
      throw new AppError(422, 'INVALID_BIO', 'Giới thiệu tối đa 300 ký tự.', 'bio');
    }
    data.bio = input.bio === null ? null : (input.bio as string).trim();
  }
  if ('avatarUrl' in input) {
    if (input.avatarUrl !== null && (typeof input.avatarUrl !== 'string' ||
        input.avatarUrl.length > 2000 || !/^https:\/\//.test(input.avatarUrl))) {
      throw new AppError(422, 'INVALID_AVATAR_URL', 'Ảnh đại diện cần URL HTTPS hợp lệ.', 'avatarUrl');
    }
    data.avatarUrl = input.avatarUrl as string | null;
  }
  try {
    const user = await prisma.user.update({ where: { id }, data, select: profileSelect });
    return formatProfile(user);
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      throw new AppError(409, 'USERNAME_TAKEN', 'Tên người dùng đã được sử dụng.', 'username');
    }
    throw error;
  }
};

export const heartbeat = async (id: string) => {
  const user = await prisma.user.update({ where: { id }, data: { lastActiveAt: new Date() }, select: { lastActiveAt: true } });
  const peers = await prisma.conversationMember.findMany({
    where: { conversation: { members: { some: { userId: id } } }, userId: { not: id } },
    select: { userId: true }, distinct: ['userId'],
  });
  publish(peers.map((peer) => peer.userId), 'presence', {
    userId: id, isOnline: true, lastActiveAt: user.lastActiveAt,
  });
  return { isOnline: true, lastActiveAt: user.lastActiveAt };
};

export const follow = async (selfId: string, targetId: string) => {
  if (selfId === targetId) throw new AppError(422, 'CANNOT_FOLLOW_SELF', 'Không thể theo dõi chính mình.');
  const target = await prisma.user.findUnique({ where: { id: targetId }, select: { id: true, status: true } });
  if (!target || target.status !== 'ACTIVE') throw new AppError(404, 'USER_NOT_FOUND', 'Không tìm thấy người dùng.');
  await prisma.userFollow.upsert({
    where: { followerId_followingId: { followerId: selfId, followingId: targetId } },
    create: { followerId: selfId, followingId: targetId }, update: {},
  });
  return { following: true };
};

export const unfollow = async (selfId: string, targetId: string) => {
  await prisma.userFollow.deleteMany({ where: { followerId: selfId, followingId: targetId } });
  return { following: false };
};
