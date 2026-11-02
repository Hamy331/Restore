import bcrypt from 'bcrypt';
import { Prisma, PrismaClient } from '@prisma/client';
import { listingLocation } from '../src/modules/catalog/catalog.validator.js';
import { DEMO_BANNERS, DEMO_LISTINGS, DEMO_PASSWORD, DEMO_SELLERS, demoImages } from './seed/demo.js';

/**
 * Dữ liệu demo: 4 người bán, 30 tin đang bán (6 tin ưu tiên), 3 banner trang chủ.
 *
 *   npm run db:seed:demo                                  # thêm / cập nhật dữ liệu demo
 *   npm run db:seed:demo -- --viewer=ban@gmail.com        # thêm: tài khoản này lưu sẵn 5 tin
 *   npm run db:seed:demo -- --remove                      # xóa toàn bộ dữ liệu demo
 *
 * Chạy lại bao nhiêu lần cũng được: tin giữ nguyên id, ngày đăng và hạn tin ưu tiên
 * được tính lại theo hôm nay. Cần chạy `npm run db:seed` trước (gói tin ưu tiên, danh mục).
 */
const prisma = new PrismaClient();
const args = process.argv.slice(2);
const remove = args.includes('--remove');
const viewerEmail = args.find((arg) => arg.startsWith('--viewer='))?.slice('--viewer='.length).trim().toLowerCase();

const DAY = 24 * 60 * 60 * 1000;
const FEATURED_PACKAGE = 'featured-7';
const listingId = (key: string) => `demo-listing-${key}`;
const sellerIds = DEMO_SELLERS.map((seller) => seller.id);

async function removeDemo() {
  // Promotion, ListingFavorite xóa theo cascade của Listing / User
  const listings = await prisma.listing.deleteMany({ where: { ownerId: { in: sellerIds } } });
  const users = await prisma.user.deleteMany({ where: { id: { in: sellerIds } } });
  const banners = await prisma.homeBanner.deleteMany({ where: { id: { in: DEMO_BANNERS.map((banner) => banner.id) } } });
  console.log('Đã xóa dữ liệu demo:', { users: users.count, listings: listings.count, banners: banners.count });
}

async function seedDemo() {
  const missingPackage = !await prisma.promotionPackage.findUnique({ where: { id: FEATURED_PACKAGE } });
  const categories = new Set((await prisma.category.findMany({ select: { id: true } })).map((category) => category.id));
  if (missingPackage || !categories.size) {
    throw new Error('Chưa có danh mục / gói tin ưu tiên. Chạy `npm run db:seed` trước.');
  }

  const password = await bcrypt.hash(DEMO_PASSWORD, 12);
  for (const seller of DEMO_SELLERS) {
    const data = { ...seller, password, status: 'ACTIVE' as const, role: 'USER' as const };
    await prisma.user.upsert({ where: { id: seller.id }, create: data, update: data });
  }

  const now = Date.now();
  let featured = 0;
  for (const [index, item] of DEMO_LISTINGS.entries()) {
    if (!categories.has(item.categoryId)) throw new Error(`Không có danh mục ${item.categoryId}`);
    const [provinceCode] = item.ward.split('-');
    const location = listingLocation({ provinceCode, wardCode: item.ward, streetAddress: '' });
    // Lệch vài phút giữa các tin để thứ tự "mới nhất" ổn định
    const publishedAt = new Date(now - item.daysAgo * DAY - index * 7 * 60 * 1000);
    const id = listingId(item.key);
    const data = {
      ownerId: item.seller,
      categoryId: item.categoryId,
      title: item.title,
      description: item.description,
      price: new Prisma.Decimal(item.price),
      isNegotiable: item.isNegotiable ?? true,
      condition: item.condition,
      status: 'AVAILABLE' as const,
      allowSale: true,
      allowExchange: item.allowExchange ?? false,
      exchangeWish: item.exchangeWish ?? '',
      sellerType: 'PERSONAL',
      attributes: item.attributes,
      location: location as Prisma.InputJsonObject,
      images: demoImages(item.key, item.imageCount),
      createdAt: publishedAt,
      publishedAt,
    };
    await prisma.listing.upsert({ where: { id }, create: { id, ...data }, update: data });

    const promotionId = `demo-promo-${item.key}`;
    if (item.featured) {
      const promotion = {
        userId: item.seller, listingId: id, packageId: FEATURED_PACKAGE,
        startsAt: new Date(now - DAY), endsAt: new Date(now + 7 * DAY),
      };
      await prisma.promotion.upsert({ where: { id: promotionId }, create: { id: promotionId, ...promotion }, update: promotion });
      featured++;
    } else {
      await prisma.promotion.deleteMany({ where: { id: promotionId } });
    }
  }

  for (const banner of DEMO_BANNERS) {
    await prisma.homeBanner.upsert({ where: { id: banner.id }, create: { ...banner, active: true }, update: { ...banner, active: true } });
  }

  let favorites = 0;
  if (viewerEmail) {
    const viewer = await prisma.user.findUnique({ where: { email: viewerEmail }, select: { id: true } });
    if (!viewer) throw new Error(`Không tìm thấy tài khoản ${viewerEmail}`);
    const picks = DEMO_LISTINGS.filter((item) => item.featured).slice(0, 2)
      .concat(DEMO_LISTINGS.filter((item) => !item.featured).slice(0, 3));
    favorites = (await prisma.listingFavorite.createMany({
      data: picks.map((item) => ({ userId: viewer.id, listingId: listingId(item.key) })),
      skipDuplicates: true,
    })).count;
  }

  console.log('Seed demo xong:', {
    sellers: DEMO_SELLERS.length, listings: DEMO_LISTINGS.length, featured, banners: DEMO_BANNERS.length, favorites,
  });
  console.log(`Đăng nhập người bán demo: ${DEMO_SELLERS[0].email} / ${DEMO_PASSWORD}`);
}

(remove ? removeDemo() : seedDemo())
  .catch((error) => { console.error(error); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
