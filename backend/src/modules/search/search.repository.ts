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
