import { PrismaClient } from '@prisma/client';
import { seedUuid } from './seed/seed-id.js';

/**
 * Đổi id dạng chữ của dữ liệu seed cũ (VD shop-samsung, demo-listing-galaxy-s23, pro-seller-*) sang UUID.
 * UUID mới = seedUuid(id cũ), trùng với id mà các script seed bây giờ sinh ra, nên chạy seed lại vẫn cập nhật đúng bản ghi.
 *
 *   npx tsx prisma/remap-seed-ids.ts            # chạy thử: chỉ in ra sẽ đổi gì, không ghi
 *   npx tsx prisma/remap-seed-ids.ts --apply    # đổi thật (một transaction, lỗi thì không đổi gì)
 *
 * Chạy TRƯỚC khi chạy lại `npm run db:seed:shops` / `db:seed:demo` (seed mới tạo bản ghi UUID, trùng email với bản ghi cũ).
 *
 * Cách đổi:
 *  - Khoá chính: mọi khoá ngoại trong schema là ON UPDATE CASCADE, nên đổi id ở bảng gốc thì các bảng tham chiếu
 *    (tin, shop, gói, theo dõi, chat, Xu, thông báo...) tự đổi theo.
 *  - Cột tham chiếu không có khoá ngoại: AdminAudit.actorId/targetId, ViolationReport.reporterId/targetId,
 *    SupportTicket.userId, SupportMessage.authorId, ShopBanner.reviewedById: đổi theo bảng id cũ → mới.
 *  - Conversation.pairKey (hai userId xếp tăng dần, nối bằng ":"): tính lại từ thành viên.
 *  - Notification.link / data / dedupeKey có chứa id: thay chuỗi id cũ bằng id mới.
 * Danh mục, gói (basic, pro, p100, featured-7...) là mã cố định, không đổi.
 */
const prisma = new PrismaClient();
const apply = process.argv.slice(2).includes('--apply');

/** Bảng có id sinh UUID mặc định: bản ghi nào id không phải UUID là dữ liệu seed cũ */
const TABLES = [
  'User', 'Shop', 'Listing', 'ShopBanner', 'HomeBanner', 'WantedAlert', 'Promotion', 'PromotionOrder', 'StoreSubscription',
  'StoreOrder', 'FeedPost', 'FeedComment', 'Conversation', 'Message', 'Notification', 'PushDevice', 'SearchHistory',
  'AdminAudit', 'ViolationReport', 'SupportTicket', 'SupportMessage', 'KnowledgeDocument', 'CreditTopupOrder',
  'CreditTransaction', 'CreditHold',
] as const;

/** Cột tham chiếu id nhưng không có khoá ngoại */
const LOOSE_COLUMNS: [table: string, column: string][] = [
  ['AdminAudit', 'actorId'], ['AdminAudit', 'targetId'], ['ViolationReport', 'reporterId'], ['ViolationReport', 'targetId'],
  ['SupportTicket', 'userId'], ['SupportMessage', 'authorId'], ['ShopBanner', 'reviewedById'],
];

const UUID = '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

type Change = { table: string; old: string; next: string };

async function plan() {
  const changes: Change[] = [];
  const skipped: Change[] = [];
  for (const table of TABLES) {
    const rows = await prisma.$queryRawUnsafe<{ id: string }[]>(`SELECT id FROM "${table}" WHERE id !~* '${UUID}' ORDER BY id`);
    for (const { id } of rows) {
      const change = { table, old: id, next: seedUuid(id) };
      const taken = await prisma.$queryRawUnsafe<unknown[]>(`SELECT 1 FROM "${table}" WHERE id = $1`, change.next);
      (taken.length ? skipped : changes).push(change);
    }
  }
  return { changes, skipped };
}

async function main() {
  const { changes, skipped } = await plan();
  const byTable = new Map<string, Change[]>();
  for (const change of changes) byTable.set(change.table, [...(byTable.get(change.table) ?? []), change]);
  console.log(apply ? 'Đổi id seed sang UUID:' : 'Chạy thử (thêm --apply để đổi thật):');
  for (const [table, list] of byTable) {
    console.log(`  ${table}: ${list.length}`);
    for (const change of list.slice(0, 5)) console.log(`    ${change.old} → ${change.next}`);
    if (list.length > 5) console.log(`    ... và ${list.length - 5} bản ghi khác`);
  }
  if (!changes.length) console.log('  Không còn id dạng chữ nào cần đổi.');
  for (const change of skipped) {
    console.warn(`  BỎ QUA ${change.table} ${change.old}: đã có bản ghi id ${change.next} (seed mới chạy trước?). Xử lý tay.`);
  }
  if (!apply || !changes.length) return;

  // Khoá ngoại khác (schema public của app, bỏ qua auth/storage của Supabase) không ON UPDATE CASCADE thì dừng
  const strict = await prisma.$queryRawUnsafe<{ name: string }[]>(
    `SELECT c.conname AS name FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace
     WHERE n.nspname = 'public' AND c.contype = 'f' AND c.confupdtype <> 'c' AND c.conrelid <> '"ListingFavorite"'::regclass`);
  if (strict.length) throw new Error(`Khoá ngoại không ON UPDATE CASCADE: ${strict.map((row) => row.name).join(', ')}`);

  // Mọi id cũ → mới (id seed là duy nhất giữa các bảng: shop dùng chung id với chủ shop nên cùng UUID)
  const mapping = new Map(changes.map((change) => [change.old, change.next]));
  const olds = [...mapping.keys()];
  const nexts = olds.map((old) => mapping.get(old)!);

  await prisma.$transaction(async (tx) => {
    // ListingFavorite tạo bằng SQL tay (migration 20261014120000), khoá ngoại không có ON UPDATE CASCADE:
    // tách các dòng liên quan ra, đổi id xong thì ghi lại với id mới
    await tx.$executeRawUnsafe(`
      CREATE TEMP TABLE remap_favorite ON COMMIT DROP AS
      SELECT * FROM "ListingFavorite" WHERE "userId" = ANY($1::text[]) OR "listingId" = ANY($1::text[])`, olds);
    await tx.$executeRawUnsafe(`DELETE FROM "ListingFavorite" WHERE "userId" = ANY($1::text[]) OR "listingId" = ANY($1::text[])`, olds);
    for (const [table, list] of byTable) {
      await tx.$executeRawUnsafe(
        `UPDATE "${table}" t SET id = m.next FROM unnest($1::text[], $2::text[]) AS m(old, next) WHERE t.id = m.old`,
        list.map((change) => change.old), list.map((change) => change.next));
    }
    for (const [table, column] of LOOSE_COLUMNS) {
      await tx.$executeRawUnsafe(
        `UPDATE "${table}" t SET "${column}" = m.next FROM unnest($1::text[], $2::text[]) AS m(old, next) WHERE t."${column}" = m.old`,
        olds, nexts);
    }
    await tx.$executeRawUnsafe(`
      INSERT INTO "ListingFavorite" ("userId", "listingId", "createdAt")
      SELECT coalesce(u.next, f."userId"), coalesce(l.next, f."listingId"), f."createdAt"
      FROM remap_favorite f
      LEFT JOIN unnest($1::text[], $2::text[]) AS u(old, next) ON u.old = f."userId"
      LEFT JOIN unnest($1::text[], $2::text[]) AS l(old, next) ON l.old = f."listingId"
      ON CONFLICT DO NOTHING`, olds, nexts);
    // pairKey giống chat.service: hai userId xếp tăng dần (so theo byte như Array.sort của JS)
    await tx.$executeRawUnsafe(`
      UPDATE "Conversation" c SET "pairKey" = k.key
      FROM (SELECT "conversationId", string_agg("userId", ':' ORDER BY "userId" COLLATE "C") AS key
            FROM "ConversationMember" GROUP BY "conversationId") k
      WHERE k."conversationId" = c.id AND c."pairKey" <> k.key`);
    // Id dài thay trước (shop-samsung-listing-1 trước shop-samsung) để không thay nhầm một phần
    for (const old of [...olds].sort((a, b) => b.length - a.length)) {
      const next = mapping.get(old)!;
      await tx.$executeRawUnsafe(`
        UPDATE "Notification" SET
          link = replace(link, $1, $2),
          "dedupeKey" = replace("dedupeKey", $1, $2),
          data = replace(data::text, $1, $2)::jsonb
        WHERE link LIKE '%' || $1 || '%' OR "dedupeKey" LIKE '%' || $1 || '%' OR data::text LIKE '%' || $1 || '%'`, old, next);
    }
  }, { timeout: 120_000, maxWait: 10_000 });
  console.log(`Đã đổi ${changes.length} id. Giờ có thể chạy lại npm run db:seed:shops / db:seed:demo.`);
}

main()
  .catch((error) => { console.error(error); process.exitCode = 1; })
  .finally(() => prisma.$disconnect());
