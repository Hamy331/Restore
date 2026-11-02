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
