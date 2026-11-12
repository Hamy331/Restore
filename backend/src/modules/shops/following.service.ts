import { prisma } from '../../lib/prisma.js';
import { visible } from '../listings/repositories/listing.repository.js';
import { cards, shopDtos } from './shop.service.js';
import * as shopRepository from './shop.repository.js';
import { shopSelect, trusted } from './shop.repository.js';

const DAY = 86_400_000;
/** "Tin mới" của shop đang theo dõi: đăng trong 7 ngày gần đây */
const NEW_LISTING_DAYS = 7;

type Page = { page: number; limit: number; skip: number };

/**
 * Shop uy tín [userId] đang theo dõi, theo dõi gần nhất trước:
 * items [Shop + isFollowing (luôn true) + followedAt + newListingCount (tin đăng 7 ngày qua)], page info
 */
export async function listFollowedShops(userId: string, { page, limit, skip }: Page, now = new Date()) {
  const where = { userId, shop: trusted };
  const [rows, totalItems] = await Promise.all([
    prisma.shopFollow.findMany({
      where, orderBy: [{ createdAt: 'desc' }, { shopId: 'asc' }], skip, take: limit,
      select: { createdAt: true, shop: { select: shopSelect } },
    }),
    prisma.shopFollow.count({ where }),
  ]);
  const shops = rows.map((row) => row.shop);
  const [dtos, fresh] = await Promise.all([
    shopDtos(userId, shops),
    prisma.listing.groupBy({
      by: ['ownerId'],
      where: { ...visible, ownerId: { in: shops.map((shop) => shop.ownerId) }, publishedAt: { gte: new Date(now.getTime() - NEW_LISTING_DAYS * DAY) } },
      _count: true,
    }),
  ]);
  const freshByOwner = new Map(fresh.map((row) => [row.ownerId, row._count]));
  const items = dtos.map((dto, index) => ({
    ...dto, followedAt: rows[index].createdAt, newListingCount: freshByOwner.get(dto.ownerId) ?? 0,
  }));
  return { items, page: { page, limit, totalItems } };
}

/** Tin mới nhất của các shop uy tín [userId] đang theo dõi (thẻ tin như trang chủ) */
export async function listFollowedListings(userId: string, { page, limit, skip }: Page) {
  const follows = await prisma.shopFollow.findMany({
    where: { userId, shop: trusted }, select: { shop: { select: { ownerId: true } } },
  });
  const where = { ...visible, ownerId: { in: follows.map((row) => row.shop.ownerId) } };
  const [listings, totalItems] = await Promise.all([
    shopRepository.findListings(where, limit, skip),
    shopRepository.countListings(where),
  ]);
  return { items: await cards(userId, listings), page: { page, limit, totalItems } };
}

/**
 * Người đang theo dõi shop của [ownerId] (trang Quản lý shop), theo dõi gần nhất trước:
 * items [{ id, fullName, username, avatarUrl, followedAt }], page info. Chưa có shop thì danh sách rỗng.
 */
export async function listMyShopFollowers(ownerId: string, { page, limit, skip }: Page) {
  const where = { shop: { ownerId }, user: { status: 'ACTIVE' as const } };
  const [rows, totalItems] = await Promise.all([
    prisma.shopFollow.findMany({
      where, orderBy: [{ createdAt: 'desc' }, { userId: 'asc' }], skip, take: limit,
      select: { createdAt: true, user: { select: { id: true, fullName: true, username: true, avatarUrl: true } } },
    }),
    prisma.shopFollow.count({ where }),
  ]);
  return {
    items: rows.map((row) => ({ ...row.user, followedAt: row.createdAt })),
    page: { page, limit, totalItems },
  };
}
