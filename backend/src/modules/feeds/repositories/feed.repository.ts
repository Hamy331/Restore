import { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';

export const author = { id: true, fullName: true, avatarUrl: true } as const;
export const available = { author: { status: 'ACTIVE' as const } };
export const postInclude = (userId: string) => ({
  author: {
    select: {
      ...author,
      followers: { where: { followerId: userId }, select: { followerId: true } },
    },
  },
  listing: { include: { owner: { select: { status: true } } } },
  likes: { where: { userId }, select: { userId: true } },
  _count: { select: { likes: true, comments: { where: available } } },
}) satisfies Prisma.FeedPostInclude;
export async function setPostLike(postId: string, userId: string, like: boolean, db = prisma.feedPostLike) {
  if (like) await db.createMany({ data: [{ postId, userId }], skipDuplicates: true });
  else await db.deleteMany({ where: { postId, userId } });
  return { likedByMe: like, likeCount: await db.count({ where: { postId } }) };
}


export function followingFilter(userId: string) {
  return { author: { status: 'ACTIVE' as const, followers: { some: { followerId: userId } } } };
}

export const findPost = (postId: string) =>
  prisma.feedPost.findFirst({ where: { id: postId, ...available } });

export const findPosts = (userId: string, limit: number, after: {createdAt: Date; id: string} | undefined, authorId: string | undefined, tab: unknown) =>
  prisma.feedPost.findMany({ where: { ...available,
    ...(tab === 'following' ? followingFilter(userId) : {}),
    ...(authorId ? { authorId } : {}),
    ...(after ? { OR: [{ createdAt: { lt: after.createdAt } }, { createdAt: after.createdAt, id: { lt: after.id } }] } : {}) },
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1,
    include: postInclude(userId) });

export const findVisibleListing = (listingId: string) =>
  prisma.listing.findFirst({ where: { id: listingId, status: 'AVAILABLE', owner: { status: 'ACTIVE' } } });

export const createPost = (data: Pick<Prisma.FeedPostUncheckedCreateInput, 'text' | 'imageUrl' | 'listingId'>, userId: string) =>
  prisma.feedPost.create({ data: { ...data, authorId: userId }, include: postInclude(userId) });

export const deletePost = (postId: string) =>
  prisma.feedPost.delete({ where: { id: postId } });

export const findComments = (postId: string, userId: string, limit: number, after: {createdAt: Date; id: string} | undefined) =>
  prisma.feedComment.findMany({
    where: {
      postId,
      ...available,
      ...(after ? {
        OR: [
          { createdAt: { gt: after.createdAt } },
          { createdAt: after.createdAt, id: { gt: after.id } },
        ],
      } : {}),
    },
    orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    take: limit + 1,
    include: {
      author: { select: author },
      likes: { where: { userId } },
      _count: { select: { likes: true } },
    },
  });

export const findParent = (postId: string, parentId: string) =>
  prisma.feedComment.findFirst({ where: { id: parentId, postId: postId, ...available } });

export const createComment = (postId: string, userId: string, data: Pick<Prisma.FeedCommentUncheckedCreateInput, 'text' | 'imageUrl'>, parentId: string | null) =>
  prisma.feedComment.create({ data: { postId: postId, authorId: userId, text: data.text, imageUrl: data.imageUrl, parentId }, include: {author: {select: author}} });

export const findComment = (commentId: string) =>
  prisma.feedComment.findFirst({ where: { id: commentId, ...available, post: available } });

export const addCommentLike = (commentId: string, userId: string) =>
  prisma.feedCommentLike.createMany({ data: [{ commentId: commentId, userId }], skipDuplicates: true });

export const removeCommentLike = (commentId: string, userId: string) =>
  prisma.feedCommentLike.deleteMany({ where: { commentId: commentId, userId } });

export const countCommentLikes = (commentId: string) =>
  prisma.feedCommentLike.count({ where: { commentId: commentId } });
