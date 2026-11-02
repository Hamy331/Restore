import { execFileSync } from 'node:child_process';
import bcrypt from 'bcrypt';
import { TEST_DATABASE_URL } from './env.js';

export const PASSWORD = 'Password@123';

/** Xóa và tạo lại database thử từ migrations (giống production, có cả dữ liệu mặc định trong migration). */
export function resetDatabase() {
  execFileSync('npx', ['prisma', 'migrate', 'reset', '--force', '--skip-seed', '--skip-generate'], {
    env: { ...process.env, DATABASE_URL: TEST_DATABASE_URL, DIRECT_URL: TEST_DATABASE_URL },
    stdio: 'pipe',
    shell: process.platform === 'win32',
  });
}

const location = (provinceCode: string, wardCode: string, provinceName: string, wardName: string, latitude: number, longitude: number) => ({
  provinceCode, wardCode, streetAddress: '1 Đường Thử',
  province: { code: provinceCode, name: provinceName, level: 'province' },
  ward: { code: wardCode, name: wardName, level: 'ward', parentCode: provinceCode, center: { latitude, longitude } },
  latitude, longitude, geoSource: 'ward_center',
});
export const SAIGON = location('79', '79-SG', 'TP. Hồ Chí Minh', 'Phường Sài Gòn', 10.7769, 106.7009);

/** Dữ liệu cố định cho mọi file test: id cố định để snapshot ổn định. */
export async function seedFixtures() {
  const { prisma } = await import('../../../src/lib/prisma.js');
  const password = await bcrypt.hash(PASSWORD, 4);
  const base = new Date('2026-10-01T00:00:00.000Z');
  const at = (minutes: number) => new Date(base.getTime() + minutes * 60_000);

  for (const [id, role, status] of [
    ['user-buyer', 'USER', 'ACTIVE'],
    ['user-seller', 'USER', 'ACTIVE'],
    ['user-admin', 'ADMIN', 'ACTIVE'],
    ['user-banned', 'USER', 'BANNED'],
  ] as const) {
    await prisma.user.create({
      data: { id, email: `${id}@restore.test`, username: id.replace('-', '_'), fullName: id, password, role, status, createdAt: base },
    });
  }

  const listings = [
    { id: 'listing-1', title: 'Bàn gỗ sồi thật', categoryId: 'furniture', allowExchange: false, minutes: 10 },
    { id: 'listing-2', title: 'Ghế xoay văn phòng', categoryId: 'furniture', allowExchange: true, minutes: 20 },
    { id: 'listing-3', title: 'Đèn bàn học cũ', categoryId: 'furniture', allowExchange: false, minutes: 30 },
  ];
  for (const item of listings) {
    await prisma.listing.create({
      data: {
        id: item.id, ownerId: 'user-seller', categoryId: item.categoryId, title: item.title,
        description: 'Mô tả sản phẩm dùng để kiểm thử API.', price: 1_200_000, condition: 'USED_GOOD',
        status: 'AVAILABLE', allowExchange: item.allowExchange, images: [], location: SAIGON,
        createdAt: at(item.minutes), publishedAt: at(item.minutes),
      },
    });
  }
  const featured = await prisma.promotionPackage.findFirst({ where: { kind: 'FEATURED' } });
  if (featured) {
    await prisma.promotion.create({
      data: { id: 'promotion-1', userId: 'user-seller', listingId: 'listing-3', packageId: featured.id,
        startsAt: at(0), endsAt: new Date('2099-01-01T00:00:00.000Z') },
    });
  }
  await prisma.homeBanner.create({
    data: { id: 'banner-1', title: 'Banner thử', imageUrl: 'https://cdn.restore.test/b1.jpg', route: '/trusted-shops', sortOrder: 1 },
  });
  await prisma.$disconnect();
}
