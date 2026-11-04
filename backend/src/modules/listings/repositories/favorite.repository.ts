import { prisma } from '../../../lib/prisma.js';
import { listingSelect } from '../listing.dto.js';
import { visible } from './listing.repository.js';

export const findVisibleListingId = (id: string) =>
  prisma.listing.findFirst({ where: { ...visible, id }, select: { id: true } });

/** Thêm vào danh sách lưu; gọi nhiều lần vẫn chỉ có một bản ghi */
export const upsertFavorite = (userId: string, listingId: string) =>
  prisma.listingFavorite.upsert({
    where: { userId_listingId: { userId, listingId } },
    create: { userId, listingId },
    update: {},
  });

export const deleteFavorite = (userId: string, listingId: string) =>
  prisma.listingFavorite.deleteMany({ where: { userId, listingId } });

export const existsFavorite = async (userId: string, listingId: string) =>
  !!(await prisma.listingFavorite.findUnique({ where: { userId_listingId: { userId, listingId } } }));

/** Tin đã lưu và vẫn còn hiển thị, mới lưu trước */
export const findFavoriteListings = (userId: string, take: number, skip: number) =>
  prisma.$transaction([
    prisma.listingFavorite.findMany({
      where: { userId, listing: visible },
      select: { listing: { select: listingSelect } },
      orderBy: { createdAt: 'desc' },
      take,
      skip,
    }),
    prisma.listingFavorite.count({ where: { userId, listing: visible } }),
  ]);
