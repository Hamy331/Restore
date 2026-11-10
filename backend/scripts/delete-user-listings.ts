// Xoá toàn bộ tin của một tài khoản (dùng khi test hạn mức đăng tin).
//
//   npx tsx scripts/delete-user-listings.ts <userId>                 # chỉ đếm, không xoá
//   npx tsx scripts/delete-user-listings.ts <userId> --yes           # xoá thật, cả tin nháp
//   npx tsx scripts/delete-user-listings.ts <userId> --yes --keep-drafts
//
// Xu đang giữ cho tin trả phí được hoàn lại trước khi xoá. Ảnh trên storage không bị xoá.
import { ListingStatus, Prisma, PrismaClient } from '@prisma/client';
import { releaseListingHold } from '../src/modules/credits/credit.hold.js';

const [userId, ...flags] = process.argv.slice(2);
if (!userId) throw new Error('Thiếu userId: npx tsx scripts/delete-user-listings.ts <userId> [--yes] [--keep-drafts]');
const confirmed = flags.includes('--yes');
const keepDrafts = flags.includes('--keep-drafts');

const prisma = new PrismaClient();
try {
  const user = await prisma.user.findUnique({ where: { id: userId }, select: { id: true, email: true } });
  if (!user) throw new Error(`Không tìm thấy user ${userId}`);
  const where: Prisma.ListingWhereInput = { ownerId: userId, ...(keepDrafts ? { status: { not: ListingStatus.DRAFT } } : {}) };
  const byStatus = await prisma.listing.groupBy({ by: ['status'], where, _count: true });
  const total = byStatus.reduce((sum, row) => sum + row._count, 0);
  console.log(`Tài khoản ${user.email ?? user.id}: ${total} tin`, Object.fromEntries(byStatus.map((row) => [row.status, row._count])));
  if (!confirmed) {
    console.log('Chưa xoá gì. Thêm --yes để xoá thật.');
  } else if (total > 0) {
    const ids = (await prisma.listing.findMany({ where, select: { id: true } })).map((row) => row.id);
    const deleted = await prisma.$transaction(async (tx) => {
      for (const id of ids) await releaseListingHold(tx, id, 'Hoàn xu · tin bị xoá khi dọn dữ liệu test');
      return tx.listing.deleteMany({ where: { id: { in: ids } } });
    }, { timeout: 60_000 });
    console.log(`Đã xoá ${deleted.count} tin.`);
  }
} finally {
  await prisma.$disconnect();
}
