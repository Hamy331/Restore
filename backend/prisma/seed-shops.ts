import bcrypt from 'bcrypt';
import { Prisma, PrismaClient } from '@prisma/client';
import { findWard } from '../src/modules/catalog/catalog.service.js';
import { listingLocation } from '../src/modules/catalog/catalog.validator.js';
import { DEMO_PASSWORD, demoImages } from './seed/demo.js';
import { PRO_SELLERS, SHOPS, type SeedListing } from './seed/shops.js';

/**
 * Shop uy tín và tài khoản Bán chuyên để test trang Shop uy tín:
 * 20 shop (gói Cửa hàng PRO, đã xác minh, logo + ảnh bìa, 3-4 tin, vài banner đã duyệt, vài tin giảm giá)
 * và 5 tài khoản Bán chuyên (gói BASIC, 1-2 tin). Mật khẩu chung Password@123.
 *
 *   npm run db:seed:shops                 # thêm / cập nhật
 *   npm run db:seed:shops -- --remove     # xóa toàn bộ
 *
 * Chạy lại bao nhiêu lần cũng được: giữ nguyên id, ngày đăng, hạn gói và hạn tin tính lại theo hôm nay.
 * Cần chạy `npm run db:seed` trước (danh mục, gói cửa hàng).
 */
const prisma = new PrismaClient();
const remove = process.argv.slice(2).includes('--remove');

const DAY = 24 * 60 * 60 * 1000;
const shopUserId = (key: string) => `shop-${key}`;
const proUserId = (key: string) => `pro-seller-${key}`;
const userIds = [...SHOPS.map((shop) => shopUserId(shop.key)), ...PRO_SELLERS.map((seller) => proUserId(seller.key))];

/** "Phường, Tỉnh" của mã phường */
function areaOf(ward: string) {
  const location = listingLocation({ provinceCode: findWard(ward)?.parentCode, wardCode: ward, streetAddress: '' });
  return { location, label: [location.ward?.name, location.province?.name].filter(Boolean).join(', ') };
}

async function removeAll() {
  // Shop, ShopFollow, ShopBanner, StoreSubscription, ListingFavorite xóa theo cascade của User / Listing
  const listings = await prisma.listing.deleteMany({ where: { ownerId: { in: userIds } } });
  const users = await prisma.user.deleteMany({ where: { id: { in: userIds } } });
  console.log('Đã xóa shop và tài khoản Bán chuyên:', { users: users.count, listings: listings.count });
}

async function upsertListings(ownerId: string, key: string, ward: string, sellerType: string, listings: SeedListing[], now: number,
  displayDays: (categoryId: string) => number) {
  const { location } = areaOf(ward);
  for (const [index, item] of listings.entries()) {
    const id = `${ownerId}-listing-${index + 1}`;
    const publishedAt = new Date(now - item.daysAgo * DAY - index * 11 * 60 * 1000);
    const data = {
      ownerId, categoryId: item.categoryId, title: item.title, description: item.description,
      price: new Prisma.Decimal(item.price),
      originalPrice: item.originalPrice ? new Prisma.Decimal(item.originalPrice) : null,
      isNegotiable: false, condition: item.condition, status: 'AVAILABLE' as const, reviewReason: null,
      allowSale: true, allowExchange: item.allowExchange ?? false, exchangeWish: item.exchangeWish ?? '',
      sellerType, attributes: item.attributes, location: location as Prisma.InputJsonObject,
      images: demoImages(`${key}-${index + 1}`, 3),
      createdAt: publishedAt, publishedAt,
      expiresAt: new Date(publishedAt.getTime() + displayDays(item.categoryId) * DAY),
      startsAt: null, displayDays: null, paidDays: 0, paidCredits: 0,
    };
    await prisma.listing.upsert({ where: { id }, create: { id, ...data }, update: data });
  }
  // Bớt tin trong dữ liệu thì xóa tin thừa của lần chạy trước
  await prisma.listing.deleteMany({ where: { ownerId, id: { notIn: listings.map((_, index) => `${ownerId}-listing-${index + 1}`) } } });
}

async function seedAll() {
  const categories = await prisma.category.findMany({ select: { id: true, displayDays: true, maxDisplayDays: true } });
  const packages = new Map((await prisma.storePackage.findMany()).map((item) => [item.id, item]));
  const pro = packages.get('pro');
  const basic = packages.get('basic');
  if (!categories.length || !pro || !basic) throw new Error('Chưa có danh mục / gói cửa hàng. Chạy `npm run db:seed` trước.');
  const rules = new Map(categories.map((category) => [category.id, category]));
  for (const item of [...SHOPS.flatMap((shop) => shop.listings), ...PRO_SELLERS.flatMap((seller) => seller.listings)]) {
    if (!rules.has(item.categoryId)) throw new Error(`Không có danh mục ${item.categoryId}`);
  }
  // Số ngày hiển thị miễn phí theo gói, không quá tối đa của danh mục
  const daysFor = (percent: number) => (categoryId: string) => {
    const rule = rules.get(categoryId)!;
    return Math.min(rule.maxDisplayDays, Math.round(rule.displayDays * percent / 100));
  };

  const password = await bcrypt.hash(DEMO_PASSWORD, 12);
  const now = Date.now();
  const subscription = (userId: string, packageId: string, categoryId: string) => {
    const data = { packageId, categoryId, startsAt: new Date(now - 5 * DAY), endsAt: new Date(now + 25 * DAY) };
    return prisma.storeSubscription.upsert({ where: { userId }, create: { userId, ...data }, update: data });
  };

  for (const shop of SHOPS) {
    const id = shopUserId(shop.key);
    const user = {
      email: `${shop.key}@shop.restore.vn`, fullName: shop.name, username: shop.username, phone: shop.phone,
      avatarUrl: `assets/images/shops/${shop.key}.png`, bio: shop.tagline,
      ratingAverage: shop.ratingAverage, ratingCount: shop.ratingCount,
      password, status: 'ACTIVE' as const, role: 'USER' as const,
    };
    await prisma.user.upsert({ where: { id }, create: { id, ...user }, update: user });
    await subscription(id, pro.id, shop.categoryIds[0]);
    const verifiedAt = new Date(now - shop.verifiedDaysAgo * DAY);
    const data = {
      ownerId: id, name: shop.name, tagline: shop.tagline, description: shop.description,
      logoUrl: `assets/images/shops/${shop.key}.png`, coverUrl: `https://picsum.photos/seed/restore-shop-${shop.key}/1200/600`,
      accentColor: shop.accentColor, verificationType: shop.verificationType, verifiedAt,
      certificateCode: `RS-${verifiedAt.getFullYear()}-${String(SHOPS.indexOf(shop) + 101).padStart(5, '0')}`,
      categoryIds: shop.categoryIds, address: areaOf(shop.ward).label, createdAt: new Date(verifiedAt.getTime() - 7 * DAY),
    };
    await prisma.shop.upsert({ where: { id }, create: { id, ...data }, update: data });
    await upsertListings(id, shop.key, shop.ward, 'BUSINESS', shop.listings, now, daysFor(pro.freeDaysPercent));

    const bannerId = `${id}-banner`;
    if (shop.banner) {
      const banner = {
        shopId: id, title: shop.banner.title, imageUrl: shop.banner.image, status: 'APPROVED' as const,
        startsAt: new Date(now - 2 * DAY), endsAt: new Date(now + 30 * DAY),
      };
      await prisma.shopBanner.upsert({ where: { id: bannerId }, create: { id: bannerId, ...banner }, update: banner });
    } else {
      await prisma.shopBanner.deleteMany({ where: { id: bannerId } });
    }
  }

  for (const seller of PRO_SELLERS) {
    const id = proUserId(seller.key);
    const user = {
      email: `${seller.key}@pro.restore.vn`, fullName: seller.fullName, username: seller.username, phone: seller.phone,
      ratingAverage: seller.ratingAverage, ratingCount: seller.ratingCount,
      password, status: 'ACTIVE' as const, role: 'USER' as const,
    };
    await prisma.user.upsert({ where: { id }, create: { id, ...user }, update: user });
    await subscription(id, basic.id, seller.categoryId);
    await upsertListings(id, seller.key, seller.ward, 'BUSINESS', seller.listings, now, daysFor(basic.freeDaysPercent));
  }

  // Người theo dõi: các tài khoản Bán chuyên rồi các shop khác, theo số followers của từng shop
  await prisma.shopFollow.deleteMany({ where: { shopId: { in: SHOPS.map((shop) => shopUserId(shop.key)) } } });
  const followers = [...PRO_SELLERS.map((seller) => proUserId(seller.key)), ...SHOPS.map((shop) => shopUserId(shop.key))];
  const follows = SHOPS.flatMap((shop) => followers
    .filter((userId) => userId !== shopUserId(shop.key))
    .slice(0, shop.followers)
    .map((userId) => ({ userId, shopId: shopUserId(shop.key) })));
  await prisma.shopFollow.createMany({ data: follows, skipDuplicates: true });

  console.log('Seed shop xong:', {
    shops: SHOPS.length, shopListings: SHOPS.reduce((sum, shop) => sum + shop.listings.length, 0),
    banners: SHOPS.filter((shop) => shop.banner).length, proSellers: PRO_SELLERS.length,
    proListings: PRO_SELLERS.reduce((sum, seller) => sum + seller.listings.length, 0), follows: follows.length,
  });
  console.log(`Đăng nhập shop: ${SHOPS[0].key}@shop.restore.vn / ${DEMO_PASSWORD}`);
  console.log(`Đăng nhập Bán chuyên: ${PRO_SELLERS[0].key}@pro.restore.vn / ${DEMO_PASSWORD}`);
}

(remove ? removeAll() : seedAll())
  .catch((error) => { console.error(error); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
