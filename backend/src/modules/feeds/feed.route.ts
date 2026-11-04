import { Router, Response, NextFunction, raw } from 'express';
import { Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { prisma } from '../../lib/prisma.js';
import { AuthRequest, verifyToken } from '../../middlewares/auth.middleware.js';
import { AppError } from '../../errors/app-error.js';
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
feedRouter.post('/media/images', raw({ type: ['image/jpeg', 'image/png', 'image/webp'], limit: '5mb' }), handle(async r => {
  const b = r.body;
  if (!Buffer.isBuffer(b) || !b.length || !(b.subarray(0,3).equals(Buffer.from([255,216,255])) || b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])) || (b.toString('ascii',0,4) === 'RIFF' && b.toString('ascii',8,12) === 'WEBP'))) throw new AppError(415, 'INVALID_IMAGE', 'JPEG, PNG or WebP required');
  const cloud = process.env.CLOUDINARY_CLOUD_NAME, key = process.env.CLOUDINARY_API_KEY, secret = process.env.CLOUDINARY_API_SECRET;
  if (!cloud || !key || !secret) throw new AppError(503, 'UPLOAD_NOT_CONFIGURED', 'Image upload is not configured');
  const timestamp = String(Math.floor(Date.now()/1000)), folder = 'restore/feeds';
  const signature = createHash('sha1').update(`folder=${folder}&timestamp=${timestamp}${secret}`).digest('hex');
  const form = new FormData();
  form.append('file', new Blob([new Uint8Array(b)]));
  for (const [k,v] of Object.entries({ timestamp, folder, signature, api_key: key })) form.append(k,v);
  const response = await fetch(`https://api.cloudinary.com/v1_1/${cloud}/image/upload`, { method: 'POST', body: form, signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new AppError(502, 'UPLOAD_FAILED', 'Image upload failed');
  const data = await response.json() as { secure_url: string };
  return { imageUrl: data.secure_url };
}, 201));

export async function setPostLike(postId: string, userId: string, like: boolean, db = prisma.feedPostLike) {
  if (like) await db.createMany({ data: [{ postId, userId }], skipDuplicates: true });
  else await db.deleteMany({ where: { postId, userId } });
  return { likedByMe: like, likeCount: await db.count({ where: { postId } }) };
}


export function followingFilter(userId: string) {
  return { author: { status: 'ACTIVE' as const, followers: { some: { followerId: userId } } } };
}
