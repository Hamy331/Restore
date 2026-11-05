import { Router, Response, NextFunction } from 'express';
import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { AuthRequest, verifyToken } from '../../middlewares/auth.middleware.js';
import { AppError } from '../../common/errors/app-error.js';
import { id, input, page } from './feed.input.js';
export const feedRouter = Router();
feedRouter.use(verifyToken);
const handle = (fn: (r: AuthRequest) => Promise<unknown>, status = 200) => async (r: AuthRequest, s: Response, n: NextFunction) => { try { s.status(status).json({ success: true, data: await fn(r) }); } catch(e) { n(e); } };
const author = { id: true, fullName: true, avatarUrl: true } as const;
const available = { author: { status: 'ACTIVE' as const } };
export async function post(postId: string) {
  const p = await prisma.feedPost.findFirst({ where: { id: id(postId), ...available } });
  if (!p) throw new AppError(404, 'POST_NOT_FOUND', 'Post unavailable');
  return p;
}
export const postInclude = (userId: string) => ({ author: { select: { ...author, followers: { where: { followerId: userId }, select: { followerId: true } } } }, listing: { include: { owner: { select: { status: true } } } }, likes: { where: { userId }, select: { userId: true } }, _count: { select: { likes: true, comments: { where: available } } } }) satisfies Prisma.FeedPostInclude;
type PostRow = Prisma.FeedPostGetPayload<{ include: ReturnType<typeof postInclude> }>;
export function serialize(p: PostRow, userId: string) {
  return { id: p.id, text: p.text, imageUrl: p.imageUrl, createdAt: p.createdAt, author: { id: p.author.id, fullName: p.author.fullName, avatarUrl: p.author.avatarUrl }, isMine: p.authorId === userId, isFollowingAuthor: !!p.author.followers.length, likedByMe: !!p.likes.length, likeCount: p._count.likes, commentCount: p._count.comments, listing: p.listing?.status === 'AVAILABLE' && p.listing.owner.status === 'ACTIVE' ? { id: p.listing.id, title: p.listing.title, price: p.listing.price.toString(), imageUrl: p.listing.images[0] ?? null } : null };
}
export function slice<T extends { id: string; createdAt: Date }>(rows: T[], limit: number) {
  const items = rows.slice(0, limit), last = items.at(-1);
  return { items, nextCursor: rows.length > limit && last ? Buffer.from(JSON.stringify({ id: last.id, createdAt: last.createdAt })).toString('base64url') : null };
}
feedRouter.get('/feeds', handle(async r => {
  if (r.query.tab !== undefined && !['for-you', 'following'].includes(String(r.query.tab))) throw new AppError(400, 'INVALID_TAB', 'Invalid tab');
  const { limit, after } = page(r.query), userId = r.user!.userId;
  const authorId = r.query.authorId === undefined ? undefined : id(r.query.authorId);
  const rows = await prisma.feedPost.findMany({ where: { ...available,
    ...(r.query.tab === 'following' ? followingFilter(userId) : {}),
    ...(authorId ? { authorId } : {}),
    ...(after ? { OR: [{ createdAt: { lt: after.createdAt } }, { createdAt: after.createdAt, id: { lt: after.id } }] } : {}) },
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }], take: limit + 1,
    include: postInclude(userId) });
  const result = slice(rows, limit);
  return { ...result, items: result.items.map(p => serialize(p, userId)) };
}));
feedRouter.post('/feeds', handle(async r => {
  const data = input(r.body), userId = r.user!.userId;
  if (data.listingId && !await prisma.listing.findFirst({ where: { id: data.listingId, status: 'AVAILABLE', owner: { status: 'ACTIVE' } } })) throw new AppError(404, 'LISTING_NOT_FOUND', 'Listing unavailable');
  return serialize(await prisma.feedPost.create({ data: { ...data, authorId: userId }, include: postInclude(userId) }), userId);
}, 201));
feedRouter.delete('/feeds/:id', handle(async r => {
  const p = await post(r.params.id as string);
  if (p.authorId !== r.user!.userId) throw new AppError(403, 'NOT_POST_AUTHOR', 'Only the author can delete this post');
  await prisma.feedPost.delete({ where: { id: p.id } });
  return { deleted: true };
}));
feedRouter.get('/feeds/:id/comments', handle(async r => {
  await post(r.params.id as string);
  const { limit, after } = page(r.query);
  const rows = await prisma.feedComment.findMany({ where: { postId: r.params.id as string, ...available, ...(after ? { OR: [{ createdAt: { gt: after.createdAt } }, { createdAt: after.createdAt, id: { gt: after.id } }] } : {}) }, orderBy: [{ createdAt: 'asc' }, { id: 'asc' }], take: limit + 1, include: { author: { select: author }, likes: { where: { userId: r.user!.userId } }, _count: { select: { likes: true } } } });
  const result = slice(rows, limit);
  return { ...result, items: result.items.map(c => ({ id: c.id, postId: c.postId, author: c.author, text: c.text, createdAt: c.createdAt, likedByMe: !!c.likes.length, likeCount: c._count.likes })) };
}));
feedRouter.post('/feeds/:id/comments', handle(async r => {
  await post(r.params.id as string);
  const comment = await prisma.feedComment.create({ data: { postId: r.params.id as string, authorId: r.user!.userId, text: input(r.body, true).text }, include: {author: {select: author}} });
  return {...comment, likedByMe:false, likeCount:0};
}, 201));
for (const like of [true, false]) {
  feedRouter[like ? 'put' : 'delete']('/feeds/:id/like', handle(async r => {
    const p = await post(r.params.id as string), userId = r.user!.userId;
    return setPostLike(p.id, userId, like);
  }));
  feedRouter[like ? 'put' : 'delete']('/feed-comments/:id/like', handle(async r => {
    const c = await prisma.feedComment.findFirst({ where: { id: id(r.params.id), ...available, post: available } });
    if (!c) throw new AppError(404, 'COMMENT_NOT_FOUND', 'Comment unavailable');
    const userId = r.user!.userId;
    if (like) await prisma.feedCommentLike.createMany({ data: [{ commentId: c.id, userId }], skipDuplicates: true });
    else await prisma.feedCommentLike.deleteMany({ where: { commentId: c.id, userId } });
    return { likedByMe: like, likeCount: await prisma.feedCommentLike.count({ where: { commentId: c.id } }) };
  }));
}

export async function setPostLike(postId: string, userId: string, like: boolean, db = prisma.feedPostLike) {
  if (like) await db.createMany({ data: [{ postId, userId }], skipDuplicates: true });
  else await db.deleteMany({ where: { postId, userId } });
  return { likedByMe: like, likeCount: await db.count({ where: { postId } }) };
}


export function followingFilter(userId: string) {
  return { author: { status: 'ACTIVE' as const, followers: { some: { followerId: userId } } } };
}
