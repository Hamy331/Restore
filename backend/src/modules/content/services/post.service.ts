import { AppError } from '../../../common/errors/app-error.js';
import type { PageQuery } from '../content.dto.js';
import { PAGE_SIZE } from '../content.type.js';
import * as postRepository from '../repositories/post.repository.js';

/** Bài viết đã đăng, mới trước */
export async function listPublished({ page }: PageQuery) {
  return { items: await postRepository.findPublishedPage((page - 1) * PAGE_SIZE, PAGE_SIZE) };
}

/** Một bài viết đã đăng, kèm các tin liên quan còn hiển thị */
export async function getPublished(slug: string) {
  const post = await postRepository.findPublishedBySlug(slug);
  if (!post) throw new AppError(404, 'POST_NOT_FOUND', 'Không tìm thấy bài viết.');
  const listings = await postRepository.findVisibleListings(post.listingIds);
  return { ...post, listings };
}
