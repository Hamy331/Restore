import { Prisma } from '@prisma/client';
import { postInclude } from './repositories/feed.repository.js';
type PostRow = Prisma.FeedPostGetPayload<{ include: ReturnType<typeof postInclude> }>;
/** Tác giả bài viết: shop { id, name } khi là cửa hàng Đối tác (đã duyệt / đã xác minh), isAdmin khi là admin ReStore */
function toAuthor({ id, fullName, avatarUrl, role, shop }: PostRow['author']) {
  const partner = !!shop && (shop.status === 'APPROVED' || shop.verificationType !== null);
  return { id, fullName, avatarUrl, shop: partner ? { id: shop.id, name: shop.name } : null, isAdmin: role === 'ADMIN' };
}
export function serialize(p: PostRow, userId: string) {
  return { id: p.id, text: p.text, imageUrl: p.imageUrl, createdAt: p.createdAt, author: toAuthor(p.author), isMine: p.authorId === userId, isFollowingAuthor: !!p.author.followers.length, likedByMe: !!p.likes.length, likeCount: p._count.likes, commentCount: p._count.comments, listing: p.listing?.status === 'AVAILABLE' && p.listing.owner.status === 'ACTIVE' ? { id: p.listing.id, title: p.listing.title, price: p.listing.price.toString(), imageUrl: p.listing.images[0] ?? null } : null };
}
export function slice<T extends { id: string; createdAt: Date }>(rows: T[], limit: number) {
  const items = rows.slice(0, limit), last = items.at(-1);
  return { items, nextCursor: rows.length > limit && last ? Buffer.from(JSON.stringify({ id: last.id, createdAt: last.createdAt })).toString('base64url') : null };
}
