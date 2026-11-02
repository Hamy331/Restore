import { AppError } from '../../../common/errors/app-error.js';
import { audit } from '../../../common/audit/admin-audit.js';
import { ADMIN_PAGE_SIZE, changed, version } from '../../../common/validation/admin-input.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import type { PageQuery, PostInput } from '../content.dto.js';
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

/* ---------- Quản trị (/admin/posts) ---------- */

/** Mọi bài viết, 25 bài mỗi trang */
export async function listForAdmin({ page }: PageQuery) {
  const [items, total] = await postRepository.findPage((page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  return { items, total, page };
}

/**
 * Tạo bài viết (không có [id]) hoặc sửa bài (có [id], updatedAt phải khớp). Tin liên quan phải đang hiển thị.
 * Ghi AdminAudit.
 */
export function save(actorId: string, id: string | undefined, { data, updatedAt }: PostInput) {
  return withQuotaTransaction(async (tx) => {
    if (await postRepository.countVisibleListings(tx, data.listingIds) !== data.listingIds.length) {
      throw new AppError(400, 'INVALID_LISTINGS', 'Tin liên quan phải đang hiển thị.');
    }
    if (id) {
      changed(await postRepository.updateWhereVersion(tx, id, version(updatedAt), data));
      await audit(tx, actorId, 'UPDATE', 'POST', id, data.title);
      return postRepository.findByIdOrThrow(tx, id);
    }
    const item = await postRepository.createPost(tx, data);
    await audit(tx, actorId, 'CREATE', 'POST', item.id, data.title);
    return item;
  });
}
