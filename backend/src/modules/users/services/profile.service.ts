import { Prisma } from '@prisma/client';
import * as repository from '../repositories/profile.repository.js';
import { AppError } from '../../../common/errors/app-error.js';
import { fullName as parseFullName, username as parseUsername } from '../../auth/auth.validator.js';
import { publish } from '../../chat/services/chat.events.js';
import { isMediaUrl } from '../../media/media.service.js';

import { profileSelect } from '../repositories/profile.repository.js';
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
  /** Số shop uy tín đang theo dõi (tab Shop của trang Đang theo dõi) */
  followingShopCount: user._count.shopFollows,
  presence: {
    isOnline: !!user.lastActiveAt && Date.now() - new Date(user.lastActiveAt).getTime() < onlineThresholdMs,
    lastActiveAt: user.lastActiveAt,
  },
});

// [viewerId] khác [id] thì kèm `isFollowing` cho trang hồ sơ công khai.
export const getProfile = async (id: string, viewerId?: string) => {
  const user = await repository.findProfile(id);
  if (!user || user.status !== 'ACTIVE') {
    throw new AppError(404, 'USER_NOT_FOUND', 'Không tìm thấy người dùng.');
  }
  if (!viewerId || viewerId === id) return formatProfile(user);
  const follow = await repository.findFollow(id, viewerId);
  return { ...formatProfile(user), isFollowing: !!follow };
};

const followPageSize = 20;
export function followPage(value: unknown) {
  if (value === undefined) return 1;
  const page = Number(value);
  if (!Number.isSafeInteger(page) || page < 1) {
    throw new AppError(400, 'INVALID_PAGINATION', 'Trang không hợp lệ.');
  }
  return page;
}

// Danh sách người theo dõi ([kind] = followers) hoặc đang theo dõi của [id].
export const listFollows = async (
  id: string,
  viewerId: string,
  kind: 'followers' | 'following',
  pageValue: unknown,
) => {
  const page = followPage(pageValue);
  const [rows, total] = await repository.findFollows(id, viewerId, kind, page, followPageSize);
  return {
    items: rows.map((row) => {
      const user = kind === 'followers' ? row.follower : row.following;
      return {
        id: user.id, fullName: user.fullName, username: user.username, avatarUrl: user.avatarUrl,
        isFollowing: user.followers.length > 0,
        isMe: user.id === viewerId,
      };
    }),
    hasMore: page * followPageSize < total,
  };
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
    if (input.avatarUrl !== null && !isMediaUrl(input.avatarUrl, 'avatar') && (typeof input.avatarUrl !== 'string' ||
        input.avatarUrl.length > 2000 || !/^https:\/\//.test(input.avatarUrl))) {
      throw new AppError(422, 'INVALID_AVATAR_URL', 'Ảnh đại diện cần URL HTTPS hợp lệ.', 'avatarUrl');
    }
    data.avatarUrl = input.avatarUrl as string | null;
  }
  try {
    const user = await repository.updateProfile(id, data);
    return formatProfile(user);
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      throw new AppError(409, 'USERNAME_TAKEN', 'Tên người dùng đã được sử dụng.', 'username');
    }
    throw error;
  }
};

export const heartbeat = async (id: string) => {
  const user = await repository.touchPresence(id);
  const peers = await repository.findPeers(id);
  publish(peers.map((peer) => peer.userId), 'presence', {
    userId: id, isOnline: true, lastActiveAt: user.lastActiveAt,
  });
  return { isOnline: true, lastActiveAt: user.lastActiveAt };
};

export const follow = async (selfId: string, targetId: string) => {
  if (selfId === targetId) throw new AppError(422, 'CANNOT_FOLLOW_SELF', 'Không thể theo dõi chính mình.');
  const target = await repository.findTarget(targetId);
  if (!target || target.status !== 'ACTIVE') throw new AppError(404, 'USER_NOT_FOUND', 'Không tìm thấy người dùng.');
  await repository.upsertFollow(selfId, targetId);
  return { following: true };
};

export const unfollow = async (selfId: string, targetId: string) => {
  await repository.deleteFollow(selfId, targetId);
  return { following: false };
};
