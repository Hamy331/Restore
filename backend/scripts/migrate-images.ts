// Chép ảnh cũ từ ổ đĩa (uploads/listings, uploads/admin) lên Supabase Storage.
//
//   npm run storage:migrate -- --dry-run   # chỉ đếm và báo cáo, không upload
//   npm run storage:migrate                # upload; chạy lại an toàn (file đã có trên bucket thì bỏ qua)
//
// Cần SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (và SUPABASE_STORAGE_BUCKET nếu khác "media") trong .env,
// cùng DATABASE_URL để đối chiếu ảnh đang được tin / bài viết dùng.
//
// Không cần sửa URL trong DB: URL ảnh là đường dẫn API (/api/v1/listings/media/<file>,
// /api/v1/content/media/<file>) và object trên bucket giữ đúng tên file, nên sau khi chép xong
// chỉ cần đặt STORAGE_DRIVER=supabase rồi khởi động lại server. Script không xóa file trên ổ đĩa;
// xóa uploads/ sau khi đã kiểm tra app hiển thị ảnh bình thường.
import 'dotenv/config';
import { prisma } from '../src/lib/prisma.js';
import { MEDIA_PREFIX } from '../src/modules/content/content.type.js';
import { IMAGE_PREFIX } from '../src/modules/listings/listing.type.js';
import { drivers, listDiskObjects, StorageArea, validateStorageEnvironment } from '../src/services/storage.service.js';

const dryRun = process.argv.includes('--dry-run');
const AREAS: { area: StorageArea; prefix: string; label: string }[] = [
  { area: 'listings', prefix: IMAGE_PREFIX, label: 'ảnh tin' },
  { area: 'admin', prefix: MEDIA_PREFIX, label: 'ảnh nội dung' },
];

/** Tên file đang được DB dùng, theo khu */
async function referencedNames() {
  const [listings, posts] = await Promise.all([
    prisma.listing.findMany({ select: { images: true } }),
    prisma.blogPost.findMany({ where: { coverUrl: { not: null } }, select: { coverUrl: true } }),
  ]);
  const pick = (urls: string[], prefix: string) =>
    new Set(urls.filter((url) => url.startsWith(prefix)).map((url) => url.slice(prefix.length)));
  return {
    listings: pick(listings.flatMap((item) => item.images), IMAGE_PREFIX),
    admin: pick(posts.map((item) => item.coverUrl!), MEDIA_PREFIX),
  } satisfies Record<StorageArea, Set<string>>;
}

async function main() {
  if (!dryRun) validateStorageEnvironment('supabase');
  const used = await referencedNames();
  let failed = 0;

  for (const { area, label } of AREAS) {
    const names = await listDiskObjects(area);
    const stats = { uploaded: 0, skipped: 0, failed: 0 };
    for (const name of names) {
      if (dryRun) continue;
      try {
        const bytes = await drivers.disk.get(area, name);
        if (!bytes) continue;
        await drivers.supabase.put(area, name, bytes);
        stats.uploaded++;
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code === 'EEXIST') stats.skipped++;
        else {
          stats.failed++;
          console.error(`  ✗ ${area}/${name}: ${(error as Error).message}`);
        }
      }
    }
    failed += stats.failed;
    const onDisk = new Set(names);
    const missing = [...used[area]].filter((name) => !onDisk.has(name));
    const unused = names.filter((name) => !used[area].has(name)).length;
    console.log(`${label} (${area}/): ${names.length} file trên ổ đĩa, ${used[area].size} đang được dùng, ${unused} không còn dùng`);
    if (!dryRun) console.log(`  đã upload ${stats.uploaded}, đã có sẵn ${stats.skipped}, lỗi ${stats.failed}`);
    if (missing.length) {
      console.log(`  ⚠ ${missing.length} ảnh DB đang dùng nhưng không có trên ổ đĩa (đã mất từ trước):`);
      for (const name of missing.slice(0, 20)) console.log(`    - ${name}`);
      if (missing.length > 20) console.log(`    ... và ${missing.length - 20} file khác`);
    }
  }

  if (dryRun) console.log('\n--dry-run: chưa upload gì. Bỏ --dry-run để chép lên bucket.');
  else if (failed) console.log(`\n${failed} file lỗi. Sửa lỗi rồi chạy lại (file đã upload sẽ được bỏ qua).`);
  else console.log('\nXong. Đặt STORAGE_DRIVER=supabase và khởi động lại server.');
  process.exitCode = failed ? 1 : 0;
}

main()
  .catch((error) => { console.error(error); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
