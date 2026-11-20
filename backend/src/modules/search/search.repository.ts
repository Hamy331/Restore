import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';
import { foldedText } from '../listings/index.js';
import { HISTORY_LIMIT, MIN_SHARED_USERS } from './search.type.js';

/** Đưa từ khoá lên đầu lịch sử (gộp bản trùng theo [normalized]), chỉ giữ HISTORY_LIMIT từ khoá mới nhất */
export async function record(userId: string, keyword: string, normalized: string, now: Date) {
  await prisma.$transaction(async (tx) => {
    await tx.searchHistory.upsert({
      where: { userId_normalized: { userId, normalized } },
      create: { userId, keyword, normalized, searchedAt: now },
      update: { keyword, searchedAt: now },
    });
    const stale = await tx.searchHistory.findMany({
      where: { userId },
      orderBy: [{ searchedAt: 'desc' }, { id: 'desc' }],
      skip: HISTORY_LIMIT,
      select: { id: true },
    });
    if (stale.length) await tx.searchHistory.deleteMany({ where: { id: { in: stale.map((row) => row.id) } } });
  });
}

export const findHistory = (userId: string) =>
  prisma.searchHistory.findMany({
    where: { userId },
    orderBy: [{ searchedAt: 'desc' }, { id: 'desc' }],
    take: HISTORY_LIMIT,
    select: { id: true, keyword: true, searchedAt: true },
  });

export const deleteOne = (userId: string, id: string) => prisma.searchHistory.deleteMany({ where: { userId, id } });

export const deleteAll = (userId: string) => prisma.searchHistory.deleteMany({ where: { userId } });

/** Từ khoá được nhiều người (≥ MIN_SHARED_USERS) tìm nhất từ [since], kèm cách viết gần nhất */
export const findTrending = (since: Date, limit: number) => prisma.$queryRaw<{ keyword: string }[]>`
  SELECT (array_agg(keyword ORDER BY "searchedAt" DESC))[1] AS keyword
  FROM "SearchHistory"
  WHERE "searchedAt" >= ${since}
  GROUP BY normalized
  HAVING COUNT(DISTINCT "userId") >= ${MIN_SHARED_USERS}
  ORDER BY COUNT(DISTINCT "userId") DESC, MAX("searchedAt") DESC, normalized
  LIMIT ${limit}`;

/** Tên chuyên mục đang mở, để bù khi chưa đủ từ khoá "Tìm nhiều" */
export const findCategoryNames = (limit: number) =>
  prisma.category.findMany({ where: { active: true }, orderBy: { id: 'asc' }, take: limit, select: { name: true } });

const containsAll = (column: Prisma.Sql, words: string[]) =>
  Prisma.join(words.map((word) => Prisma.sql`POSITION(${word} IN ${column}) > 0`), ' AND ');

/**
 * Gợi ý khi gõ: từ khoá nhiều người tìm (trong lịch sử), tên chuyên mục, rồi tới tiêu đề tin đang hiển thị,
 * cùng chứa đủ mọi từ đã gõ (không phân biệt dấu); cái bắt đầu bằng cụm từ khoá lên trước.
 */
export async function findSuggestions(words: string[], limit: number) {
  const phrase = words.join(' ');
  const [keywords, categories, titles] = await Promise.all([
    prisma.$queryRaw<{ text: string }[]>`
      SELECT (array_agg(keyword ORDER BY "searchedAt" DESC))[1] AS text
      FROM "SearchHistory"
      WHERE ${containsAll(Prisma.sql`normalized`, words)}
      GROUP BY normalized
      HAVING COUNT(DISTINCT "userId") >= ${MIN_SHARED_USERS}
      ORDER BY (POSITION(${phrase} IN normalized) = 1) DESC, COUNT(DISTINCT "userId") DESC, MAX("searchedAt") DESC, normalized
      LIMIT ${limit}`,
    prisma.$queryRaw<{ text: string }[]>`
      SELECT c.name AS text FROM "Category" c
      WHERE c.active AND ${containsAll(foldedText(Prisma.sql`c.name`), words)}
      ORDER BY c.name`,
    prisma.$queryRaw<{ text: string }[]>`
      SELECT t.title AS text FROM (
        SELECT l.id, l.title, ${foldedText(Prisma.sql`l.title`)} AS f, COALESCE(l."publishedAt", l."createdAt") AS at
        FROM "Listing" l JOIN "User" u ON u.id = l."ownerId" AND u.status = 'ACTIVE'
        WHERE l.status = 'AVAILABLE'
      ) t
      WHERE ${containsAll(Prisma.sql`t.f`, words)}
      ORDER BY (POSITION(${phrase} IN t.f) = 1) DESC, t.at DESC, t.id
      LIMIT ${limit}`,
  ]);
  return [...keywords, ...categories, ...titles].map((row) => row.text);
}

/* ---------- Tìm cửa hàng, người dùng ---------- */

/** Username bỏ ký tự đặc biệt (VD "tu_lanh.99" → "tulanh99") để so với từ khoá ghép liền */
const usernameKey = (column: Prisma.Sql) => Prisma.sql`regexp_replace(lower(${column}), '[^a-z0-9]', '', 'g')`;

type Page = { limit: number; skip: number };

/**
 * Shop uy tín (đã xác minh, chủ shop còn hoạt động) có tên shop hoặc tên chủ shop chứa đủ mọi từ đã gõ, hoặc
 * username chủ shop chứa [handle]; [usernameOnly] (gõ "@...") thì chỉ xét username. Chủ shop không hiện lại
 * trong kết quả người dùng: shop và chủ shop là một mục. Xếp: trùng tên → tên bắt đầu bằng từ khoá →
 * nhiều người theo dõi (chủ shop) → tên. Trả về id theo thứ tự, kèm tổng số.
 */
export async function findShopIds(words: string[], handle: string, usernameOnly: boolean, { limit, skip }: Page) {
  const phrase = words.join(' ');
  const name = foldedText(Prisma.sql`s.name`);
  const byUsername = Prisma.sql`POSITION(${handle} IN ${usernameKey(Prisma.sql`u.username`)}) > 0`;
  const match = usernameOnly ? byUsername
    : Prisma.sql`(${containsAll(name, words)} OR ${containsAll(foldedText(Prisma.sql`u."fullName"`), words)} OR ${byUsername})`;
  const where = Prisma.sql`s."verificationType" IS NOT NULL AND u.status = 'ACTIVE' AND ${match}`;
  const [rows, total] = await Promise.all([
    prisma.$queryRaw<{ id: string }[]>`
      SELECT s.id FROM "Shop" s JOIN "User" u ON u.id = s."ownerId"
      WHERE ${where}
      ORDER BY (${name} = ${phrase}) DESC, (POSITION(${phrase} IN ${name}) = 1) DESC,
        (SELECT COUNT(*) FROM "UserFollow" f WHERE f."followingId" = s."ownerId") DESC, s.name, s.id
      LIMIT ${limit} OFFSET ${skip}`,
    prisma.$queryRaw<{ count: bigint }[]>`
      SELECT COUNT(*) AS count FROM "Shop" s JOIN "User" u ON u.id = s."ownerId" WHERE ${where}`,
  ]);
  return { ids: rows.map((row) => row.id), totalItems: Number(total[0]?.count ?? 0) };
}

/**
 * Người dùng (đang hoạt động, không phải admin, không có shop uy tín: người có shop hiện ở kết quả shop) có tên hiển thị chứa đủ mọi từ đã gõ, hoặc username chứa
 * [handle]; [usernameOnly] (gõ "@...") thì chỉ xét username. Xếp: trùng username → username bắt đầu bằng
 * từ khoá → tên bắt đầu bằng từ khoá → nhiều người theo dõi → tên. Trả về id theo thứ tự, kèm tổng số.
 */
export async function findUserIds(words: string[], handle: string, usernameOnly: boolean, { limit, skip }: Page) {
  const phrase = words.join(' ');
  const name = foldedText(Prisma.sql`u."fullName"`);
  const key = usernameKey(Prisma.sql`u.username`);
  const byUsername = Prisma.sql`POSITION(${handle} IN ${key}) > 0`;
  const match = usernameOnly ? byUsername : Prisma.sql`(${containsAll(name, words)} OR ${byUsername})`;
  const where = Prisma.sql`u.status = 'ACTIVE' AND u.role = 'USER' AND ${match}
    AND NOT EXISTS (SELECT 1 FROM "Shop" s WHERE s."ownerId" = u.id AND s."verificationType" IS NOT NULL)`;
  const [rows, total] = await Promise.all([
    prisma.$queryRaw<{ id: string }[]>`
      SELECT u.id FROM "User" u
      WHERE ${where}
      ORDER BY (${key} = ${handle}) DESC, (POSITION(${handle} IN ${key}) = 1) DESC,
        (POSITION(${phrase} IN ${name}) = 1) DESC,
        (SELECT COUNT(*) FROM "UserFollow" f WHERE f."followingId" = u.id) DESC, u."fullName", u.id
      LIMIT ${limit} OFFSET ${skip}`,
    prisma.$queryRaw<{ count: bigint }[]>`SELECT COUNT(*) AS count FROM "User" u WHERE ${where}`,
  ]);
  return { ids: rows.map((row) => row.id), totalItems: Number(total[0]?.count ?? 0) };
}

/** Thông tin hiển thị của các người dùng [ids] (chưa theo thứ tự) */
export const findUsers = (ids: string[]) =>
  prisma.user.findMany({
    where: { id: { in: ids } },
    select: {
      id: true, fullName: true, username: true, avatarUrl: true, bio: true, ratingAverage: true, ratingCount: true,
      _count: { select: { followers: true } },
      shop: { select: { id: true, verificationType: true } },
    },
  });

/** Số tin đang bán theo người đăng */
export async function countVisibleListings(ownerIds: string[]) {
  if (!ownerIds.length) return new Map<string, number>();
  const rows = await prisma.listing.groupBy({
    by: ['ownerId'], where: { status: 'AVAILABLE', ownerId: { in: ownerIds } }, _count: true,
  });
  return new Map(rows.map((row) => [row.ownerId, row._count]));
}

/** Những người trong [ids] mà [viewerId] đang theo dõi */
export async function findFollowedUserIds(viewerId: string | undefined, ids: string[]) {
  if (!viewerId || !ids.length) return new Set<string>();
  const rows = await prisma.userFollow.findMany({
    where: { followerId: viewerId, followingId: { in: ids } }, select: { followingId: true },
  });
  return new Set(rows.map((row) => row.followingId));
}
