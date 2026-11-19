import type { Prisma } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { audit } from '../../../common/audit/admin-audit.js';
import { changed } from '../../../common/validation/admin-input.js';
import * as repository from '../repositories/feed.repository.js';

export const findReportableFeedPost = repository.findReportablePost;
export const getAdminReportTarget = repository.findAdminReportTarget;

export async function removeFeedPostForAdmin(
  tx: Prisma.TransactionClient,
  actorId: string,
  postId: string,
  reason: string,
  updatedAt: Date,
) {
  const before = await tx.feedPost.findUnique({
    where: { id: postId },
    select: {
      id: true,
      text: true,
      imageUrl: true,
      createdAt: true,
      updatedAt: true,
      author: { select: { id: true, fullName: true, status: true } },
    },
  });
  if (!before) throw new AppError(409, 'ADMIN_STALE', 'Bài viết đã được gỡ. Tải lại báo cáo.');
  changed((await tx.feedPost.deleteMany({ where: { id: postId, updatedAt } })).count);
  await audit(tx, actorId, 'REMOVE', 'FEED_POST', postId, reason, before);
}
