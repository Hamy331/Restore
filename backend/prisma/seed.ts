import { Prisma, PrismaClient } from '@prisma/client';
import { CATEGORY_ORDER } from '../src/modules/catalog/catalog.type.js';
import { CATEGORIES } from './seed/categories.js';
import { CONDITION_POLICIES, PROMOTION_PACKAGES, STORE_PACKAGES } from './seed/reference.js';

/**
 * Seed dữ liệu tham chiếu: danh mục, tình trạng sản phẩm, gói cửa hàng, gói đẩy tin.
 *
 *   npm run db:seed              # chỉ thêm bản ghi còn thiếu, không đụng bản ghi admin đã sửa
 *   npm run db:seed -- --sync    # ghi đè tên + metadata danh mục theo prisma/seed/categories.ts
 *                                  (dùng khi sửa thuộc tính danh mục trong code)
 *
 * Chạy lại bao nhiêu lần cũng được. Dữ liệu thử nghiệm (user, tin) không nằm ở đây.
 */
const prisma = new PrismaClient();
const sync = process.argv.includes('--sync');

async function main() {
  const ids = CATEGORIES.map((item) => item.id).join(',');
  if (ids !== CATEGORY_ORDER.join(',')) {
    throw new Error(`prisma/seed/categories.ts (${ids}) phải cùng thứ tự với CATEGORY_ORDER trong catalog.type.ts`);
  }
  const counts = { categories: 0, conditions: 0, storePackages: 0, promotionPackages: 0 };

  for (const category of CATEGORIES) {
    const data = { name: category.name.vi, metadata: category as Prisma.InputJsonObject };
    const existing = await prisma.category.findUnique({ where: { id: category.id }, select: { id: true } });
    if (!existing) await prisma.category.create({ data: { id: category.id, ...data } });
    else if (sync) await prisma.category.update({ where: { id: category.id }, data });
    else continue;
    counts.categories++;
  }
  for (const item of CONDITION_POLICIES) {
    const created = await prisma.conditionPolicy.createMany({ data: [item], skipDuplicates: true });
    counts.conditions += created.count;
  }
  for (const item of STORE_PACKAGES) {
    counts.storePackages += (await prisma.storePackage.createMany({ data: [item], skipDuplicates: true })).count;
  }
  for (const item of PROMOTION_PACKAGES) {
    counts.promotionPackages += (await prisma.promotionPackage.createMany({ data: [{ ...item, active: true }], skipDuplicates: true })).count;
  }
  console.log(`Seed xong${sync ? ' (--sync)' : ''}:`, counts);
}

main()
  .catch((error) => { console.error(error); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
