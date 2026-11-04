import bcrypt from 'bcrypt';
import { Prisma, PrismaClient } from '@prisma/client';
import { findWard } from '../src/modules/catalog/catalog.service.js';
import { listingLocation } from '../src/modules/catalog/catalog.validator.js';
import { matchApprovedListing } from '../src/modules/wanted-alerts/wanted-alert.service.js';
import { DEMO_BANNERS, DEMO_LISTINGS, DEMO_PASSWORD, DEMO_SELLERS, DemoListing, demoImages } from './seed/demo.js';
import { DEMO_PENDING_LISTINGS, DEMO_WANTED_ALERTS } from './seed/demo-wanted-alerts.js';

/**
 * Dữ liệu demo: 4 người bán, 30 tin đang bán (6 tin ưu tiên), 3 banner trang chủ,
 * 5 thông báo "Báo khi có hàng" và 7 tin chờ duyệt để thử chấm điểm khớp.
 *
 *   npm run db:seed:demo                                  # thêm / cập nhật dữ liệu demo
 *   npm run db:seed:demo -- --viewer=ban@gmail.com        # thêm: tài khoản này lưu sẵn 5 tin
 *                                                         #   và là chủ các thông báo Báo khi có hàng
 *   npm run db:seed:demo -- --approve                     # duyệt luôn 7 tin chờ, chạy chấm điểm khớp
 *   npm run db:seed:demo -- --remove                      # xóa toàn bộ dữ liệu demo
 *
 * Không có --viewer thì thông báo thuộc người bán demo khoa@demo.restore.vn.
 * Chạy lại thì thông báo và tin chờ duyệt về như mới (chưa khớp tin nào) để thử lại.
 *
 * Chạy lại bao nhiêu lần cũng được: tin giữ nguyên id, ngày đăng và hạn tin ưu tiên
 * được tính lại theo hôm nay. Cần chạy `npm run db:seed` trước (gói tin ưu tiên, danh mục).
 */
const prisma = new PrismaClient();
const args = process.argv.slice(2);
const remove = args.includes('--remove');
const approve = args.includes('--approve');
const viewerEmail = args.find((arg) => arg.startsWith('--viewer='))?.slice('--viewer='.length).trim().toLowerCase();

const DAY = 24 * 60 * 60 * 1000;
const FEATURED_PACKAGE = 'featured-7';
const HOUR = 60 * 60 * 1000;
const ALERT_OWNER_FALLBACK = 'demo-seller-khoa';
const listingId = (key: string) => `demo-listing-${key}`;
const pendingId = (key: string) => `demo-pending-${key}`;
const alertId = (key: string) => `demo-alert-${key}`;
const sellerIds = DEMO_SELLERS.map((seller) => seller.id);

/** Dữ liệu một tin demo (đang bán hoặc chờ duyệt) */
function listingData(item: DemoListing, status: 'AVAILABLE' | 'PENDING', createdAt: Date) {
  const provinceCode = findWard(item.ward)?.parentCode;
  const location = listingLocation({ provinceCode, wardCode: item.ward, streetAddress: '' });
  return {
    ownerId: item.seller,
    categoryId: item.categoryId,
    title: item.title,
    description: item.description,
    price: new Prisma.Decimal(item.price),
    isNegotiable: item.isNegotiable ?? true,
    condition: item.condition,
    status,
    reviewReason: null,
    allowSale: true,
    allowExchange: item.allowExchange ?? false,
    exchangeWish: item.exchangeWish ?? '',
    sellerType: 'PERSONAL',
    attributes: item.attributes,
    location: location as Prisma.InputJsonObject,
    images: demoImages(item.key, item.imageCount),
    createdAt,
    publishedAt: status === 'AVAILABLE' ? createdAt : null,
  };
}

async function removeDemo() {
  // Promotion, ListingFavorite, WantedAlertMatch xóa theo cascade của Listing / User / WantedAlert
  const alerts = await prisma.wantedAlert.deleteMany({ where: { id: { in: DEMO_WANTED_ALERTS.map((alert) => alertId(alert.key)) } } });
  const listings = await prisma.listing.deleteMany({ where: { ownerId: { in: sellerIds } } });
  const users = await prisma.user.deleteMany({ where: { id: { in: sellerIds } } });
  const banners = await prisma.homeBanner.deleteMany({ where: { id: { in: DEMO_BANNERS.map((banner) => banner.id) } } });
  console.log('Đã xóa dữ liệu demo:', { users: users.count, listings: listings.count, banners: banners.count, alerts: alerts.count });
}

/**
 * Thông báo Báo khi có hàng tạo 2 giờ trước (chưa khớp gì) và tin chờ duyệt tạo 1 giờ trước.
 * Xóa tin khớp cũ để chạy lại là thử lại được từ đầu.
 */
async function seedWantedAlerts(ownerId: string) {
  const now = Date.now();
  const createdAt = new Date(now - 2 * HOUR);
  for (const alert of DEMO_WANTED_ALERTS) {
    const id = alertId(alert.key);
    const areaCode = alert.provinceOfWard ? findWard(alert.provinceOfWard)?.parentCode ?? null : null;
    const data = {
      userId: ownerId,
      keywords: alert.keywords,
      categoryId: alert.categoryId,
      minPrice: alert.minPrice != null ? BigInt(alert.minPrice) : null,
      maxPrice: alert.maxPrice != null ? BigInt(alert.maxPrice) : null,
      conditions: alert.conditions ?? [],
      dealTypes: alert.dealTypes ?? [],
      areaCode,
      areaLevel: areaCode ? 'province' : null,
      areaLabel: areaCode ? alert.areaLabel ?? null : null,
      matchLevel: alert.matchLevel,
      seenAt: createdAt,
      lastMatchedAt: null,
      createdAt,
    };
    await prisma.wantedAlert.upsert({ where: { id }, create: { id, ...data }, update: data });
  }
  await prisma.wantedAlertMatch.deleteMany({ where: { alertId: { in: DEMO_WANTED_ALERTS.map((alert) => alertId(alert.key)) } } });

  for (const [index, item] of DEMO_PENDING_LISTINGS.entries()) {
    const id = pendingId(item.key);
    const { expect: _expect, ...listing } = item;
    const data = listingData(listing, 'PENDING', new Date(now - HOUR - index * 60 * 1000));
    await prisma.listing.upsert({ where: { id }, create: { id, ...data }, update: data });
  }
}

/**
 * Duyệt các tin chờ giống admin bấm Duyệt: chuyển AVAILABLE rồi chạy đúng hook chấm điểm
 * matchApprovedListing trong cùng transaction. In ra tin nào khớp thông báo nào.
 */
async function approvePending() {
  for (const item of DEMO_PENDING_LISTINGS) {
    const id = pendingId(item.key);
    const approvedAt = new Date();
    await prisma.$transaction(async (tx) => {
      await tx.listing.update({ where: { id }, data: { status: 'AVAILABLE', publishedAt: approvedAt, reviewReason: null } });
      await matchApprovedListing(tx, id, approvedAt);
    });
    const matches = await prisma.wantedAlertMatch.findMany({ where: { listingId: id }, select: { alertId: true, score: true } });
    const got = matches.map((match) => `${match.alertId.replace('demo-alert-', '')} (${match.score.toFixed(2)})`).join(', ') || 'không khớp';
    console.log(`  ${item.key.padEnd(16)} → ${got.padEnd(28)} mong đợi: ${item.expect}`);
  }
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
    // Lệch vài phút giữa các tin để thứ tự "mới nhất" ổn định
    const publishedAt = new Date(now - item.daysAgo * DAY - index * 7 * 60 * 1000);
    const id = listingId(item.key);
    const data = listingData(item, 'AVAILABLE', publishedAt);
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
  let alertOwner = ALERT_OWNER_FALLBACK;
  if (viewerEmail) {
    const viewer = await prisma.user.findUnique({ where: { email: viewerEmail }, select: { id: true } });
    if (!viewer) throw new Error(`Không tìm thấy tài khoản ${viewerEmail}`);
    alertOwner = viewer.id;
    const picks = DEMO_LISTINGS.filter((item) => item.featured).slice(0, 2)
      .concat(DEMO_LISTINGS.filter((item) => !item.featured).slice(0, 3));
    favorites = (await prisma.listingFavorite.createMany({
      data: picks.map((item) => ({ userId: viewer.id, listingId: listingId(item.key) })),
      skipDuplicates: true,
    })).count;
  }

  for (const item of DEMO_PENDING_LISTINGS) {
    if (!categories.has(item.categoryId)) throw new Error(`Không có danh mục ${item.categoryId}`);
  }
  await seedWantedAlerts(alertOwner);

  console.log('Seed demo xong:', {
    sellers: DEMO_SELLERS.length, listings: DEMO_LISTINGS.length, featured, banners: DEMO_BANNERS.length, favorites,
    wantedAlerts: DEMO_WANTED_ALERTS.length, pending: DEMO_PENDING_LISTINGS.length,
  });
  console.log(`Đăng nhập người bán demo: ${DEMO_SELLERS[0].email} / ${DEMO_PASSWORD}`);
  console.log(`Thông báo Báo khi có hàng thuộc: ${viewerEmail ?? `${ALERT_OWNER_FALLBACK.replace('demo-seller-', '')}@demo.restore.vn`}`);

  if (approve) {
    console.log('Duyệt tin chờ và chấm điểm khớp:');
    await approvePending();
  } else {
    console.log('Duyệt 7 tin "demo-pending-*" trong trang admin (hoặc chạy lại với -- --approve) để xem tin khớp.');
  }
}

(remove ? removeDemo() : seedDemo())
  .catch((error) => { console.error(error); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
