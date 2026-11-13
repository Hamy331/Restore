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

/** Số tin xem trước trên mỗi thẻ gợi ý shop */
const PREVIEW_SIZE = 3;

/** Trọng số sở thích theo từng kiểu tương tác với một danh mục */
const INTEREST_WEIGHT = { favorite: 2, wantedAlert: 3, followedShop: 1 } as const;

/**
 * Mức quan tâm của [userId] với từng danh mục: tin đã lưu, thẻ "Báo khi có hàng" và danh mục của các shop
 * đang theo dõi. Danh mục tương tác nhiều thì điểm cao.
 */
async function interestByCategory(userId: string) {
  const [favorites, alerts, followed] = await Promise.all([
    prisma.listingFavorite.findMany({
      where: { userId }, orderBy: { createdAt: 'desc' }, take: 100, select: { listing: { select: { categoryId: true } } },
    }),
    prisma.wantedAlert.findMany({ where: { userId, categoryId: { not: null } }, take: 50, select: { categoryId: true } }),
    prisma.shopFollow.findMany({ where: { userId }, select: { shop: { select: { categoryIds: true } } } }),
  ]);
  const interest = new Map<string, number>();
  const add = (id: string | null, weight: number) => {
    if (id) interest.set(id, (interest.get(id) ?? 0) + weight);
  };
  favorites.forEach((row) => add(row.listing.categoryId, INTEREST_WEIGHT.favorite));
  alerts.forEach((row) => add(row.categoryId, INTEREST_WEIGHT.wantedAlert));
  followed.forEach((row) => row.shop.categoryIds.forEach((id) => add(id, INTEREST_WEIGHT.followedShop)));
  return interest;
}

/**
 * Gợi ý shop uy tín để theo dõi (trang Đang theo dõi): shop chưa theo dõi, không phải shop của mình.
 * Xếp theo: hợp danh mục mình tương tác nhiều (tin đã lưu, Báo khi có hàng, shop đang theo dõi) → đối tác
 * (shop đang có gói Cửa hàng còn hạn, hoặc thương hiệu chính hãng) → số người theo dõi.
 * items [Shop + isFollowing + isPartner + reason (MATCHES_INTEREST | PARTNER | POPULAR) + previews (≤ 3 thẻ tin)]
 */
export async function listSuggestedShops(userId: string, limit: number, now = new Date()) {
  const [shops, interest] = await Promise.all([
    prisma.shop.findMany({
      where: { ...trusted, ownerId: { not: userId }, followers: { none: { userId } } },
      select: {
        ...shopSelect,
        owner: { select: { ...shopSelect.owner.select, storeSubscription: { select: { endsAt: true, startsAt: true, package: { select: { tier: true } } } } } },
      },
    }),
    interestByCategory(userId),
  ]);
  const ranked = shops
    .map((shop) => {
      const sub = shop.owner.storeSubscription;
      const storePlan = !!sub && sub.package.tier === 'PRO' && sub.startsAt <= now && sub.endsAt > now;
      const partner = storePlan || shop.verificationType === 'OFFICIAL_BRAND';
      const score = shop.categoryIds.reduce((sum, id) => sum + (interest.get(id) ?? 0), 0);
      return { shop, partner, score };
    })
    .sort((a, b) => b.score - a.score || Number(b.partner) - Number(a.partner)
      || b.shop._count.followers - a.shop._count.followers || a.shop.name.localeCompare(b.shop.name))
    .slice(0, limit);
  const dtos = await shopDtos(userId, ranked.map((row) => row.shop));
  return Promise.all(dtos.map(async (dto, index) => {
    const { score, partner } = ranked[index];
    return {
      ...dto,
      isPartner: partner,
      reason: score > 0 ? 'MATCHES_INTEREST' : partner ? 'PARTNER' : 'POPULAR',
      previews: await cards(userId, await shopRepository.findListings({ ...visible, ownerId: dto.ownerId }, PREVIEW_SIZE)),
    };
  }));
}
