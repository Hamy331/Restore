import * as repository from '../repositories/feed.repository.js';
import { AppError } from '../../../common/errors/app-error.js';
import { id, input, page } from '../feed.validator.js';
import { setPostLike } from '../repositories/feed.repository.js';
import { serialize, slice } from '../feed.dto.js';
export { slice } from '../feed.dto.js';
export { followingFilter, setPostLike } from '../repositories/feed.repository.js';

export async function post(postId: string) {
  const existing = await repository.findPost(id(postId));
  if (!existing) throw new AppError(404, 'POST_NOT_FOUND', 'Post unavailable');
  return existing;
}
export async function listPosts(userId: string, query: Record<string, unknown>) {
  if (query.tab !== undefined && !['for-you', 'following'].includes(String(query.tab))) throw new AppError(400, 'INVALID_TAB', 'Invalid tab');
  const { limit, after } = page(query);
  const authorId = query.authorId === undefined ? undefined : id(query.authorId);
  const rows = await repository.findPosts(userId, limit, after, authorId, query.tab);
  const result = slice(rows, limit);
  return { ...result, items: result.items.map(item => serialize(item, userId)) };
}

export async function createPost(userId: string, body: unknown) {
  const data = input(body);
  if (data.listingId && !await repository.findVisibleListing(data.listingId)) {
    throw new AppError(404, 'LISTING_NOT_FOUND', 'Listing unavailable');
  }
  return serialize(await repository.createPost(data, userId), userId);
}

export async function deletePost(userId: string, postId: string) {
  const existing = await post(postId);
  if (existing.authorId !== userId) {
    throw new AppError(403, 'NOT_POST_AUTHOR', 'Only the author can delete this post');
  }
  await repository.deletePost(existing.id);
  return { deleted: true };
}

export async function listComments(userId: string, postId: string, query: Record<string, unknown>) {
  await post(postId);
  const { limit, after } = page(query);
  const rows = await repository.findComments(postId, userId, limit, after);
  const result = slice(rows, limit);
  return {
    ...result,
    items: result.items.map(comment => ({
      id: comment.id,
      postId: comment.postId,
      author: comment.author,
      text: comment.text,
      imageUrl: comment.imageUrl,
      parentId: comment.parentId,
      createdAt: comment.createdAt,
      likedByMe: !!comment.likes.length,
      likeCount: comment._count.likes,
    })),
  };
}

export async function createComment(userId: string, postId: string, body: unknown) {
  await post(postId);
  const data = input(body, true);
  const parentId = data.parentId ?? null;
  if (parentId) {
    const parent = await repository.findParent(postId, parentId);
    if (!parent || parent.parentId) {
      throw new AppError(404, 'COMMENT_NOT_FOUND', 'Reply to an available top-level comment');
    }
  }
  const comment = await repository.createComment(postId, userId, data, parentId);
  return { ...comment, likedByMe: false, likeCount: 0 };
}

export async function likePost(userId: string, postId: string, like: boolean) {
  const existing = await post(postId);
  return setPostLike(existing.id, userId, like);
}

export async function likeComment(userId: string, commentId: string, like: boolean) {
  const comment = await repository.findComment(id(commentId));
  if (!comment) throw new AppError(404, 'COMMENT_NOT_FOUND', 'Comment unavailable');
  if (like) await repository.addCommentLike(comment.id, userId);
  else await repository.removeCommentLike(comment.id, userId);
  return { likedByMe: like, likeCount: await repository.countCommentLikes(comment.id) };
}
