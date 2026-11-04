import type { Prisma } from '@prisma/client';
import { prisma } from '../../../lib/prisma.js';

export const findPublishedPage = (skip: number, take: number) =>
  prisma.blogPost.findMany({
    where: { status: 'PUBLISHED' },
    skip,
    take,
    orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    select: { id: true, slug: true, title: true, category: true, coverUrl: true, createdAt: true },
  });

export const findPublishedBySlug = (slug: string) => prisma.blogPost.findFirst({ where: { slug, status: 'PUBLISHED' } });

/** Tin liên quan của bài viết, chỉ tin đang hiển thị */
export const findVisibleListings = (ids: string[]) =>
  prisma.listing.findMany({
    where: { id: { in: ids }, status: 'AVAILABLE', owner: { status: 'ACTIVE' } },
    select: { id: true, title: true, price: true, images: true },
  });

/** Có bài viết đang đăng dùng ảnh bìa [coverUrl] không */
export const isPublishedCover = async (coverUrl: string) =>
  !!(await prisma.blogPost.findFirst({ where: { status: 'PUBLISHED', coverUrl }, select: { id: true } }));

/* ---------- Quản trị ---------- */

type Db = Prisma.TransactionClient;
type PostData = Pick<Prisma.BlogPostUncheckedCreateInput, 'title' | 'slug' | 'category' | 'content' | 'coverUrl' | 'listingIds' | 'status'>;

/** Mọi bài viết, cập nhật gần nhất trước */
export const findPage = (skip: number, take: number) =>
  prisma.$transaction([
    prisma.blogPost.findMany({ skip, take, orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }] }),
    prisma.blogPost.count(),
  ]);

/** Số tin trong [ids] đang hiển thị (chủ tin còn hoạt động) */
export const countVisibleListings = (tx: Db, ids: string[]) =>
  tx.listing.count({ where: { id: { in: ids }, status: 'AVAILABLE', owner: { status: 'ACTIVE' } } });

export const createPost = (tx: Db, data: PostData) => tx.blogPost.create({ data });

/** Sửa khi updatedAt vẫn như lúc đọc; trả về số dòng đổi */
export async function updateWhereVersion(tx: Db, id: string, updatedAt: Date, data: PostData) {
  return (await tx.blogPost.updateMany({ where: { id, updatedAt }, data })).count;
}

export const findByIdOrThrow = (tx: Db, id: string) => tx.blogPost.findUniqueOrThrow({ where: { id } });
