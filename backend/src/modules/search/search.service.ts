import { normalizeTitle } from '../listings/index.js';
import { prisma } from '../../lib/prisma.js';
import { shopDtos, shopSelect } from '../shops/index.js';
import type { AccountSearchQuery, SearchHistoryDto, SuggestionsQuery, UserSearchItemDto } from './search.dto.js';
import * as searchRepository from './search.repository.js';
import { TRENDING_DAYS, TRENDING_LIMIT, TRENDING_MIN } from './search.type.js';

const DAY_MS = 24 * 60 * 60 * 1000;

/** Bỏ trùng theo dạng bỏ dấu, giữ thứ tự, lấy tối đa [limit] */
export function distinctTexts(texts: string[], limit: number) {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const text of texts) {
    const key = normalizeTitle(text);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    result.push(text.trim());
    if (result.length === limit) break;
  }
  return result;
}

/** Lưu từ khoá vào lịch sử của [userId]. Bỏ qua khi từ khoá không có chữ/số nào */
export async function recordSearch(userId: string, query: string, now = new Date()) {
  const keyword = query.trim().replace(/\s+/g, ' ').slice(0, 100);
  const normalized = normalizeTitle(keyword);
  if (!normalized) return;
  await searchRepository.record(userId, keyword, normalized, now);
}

export async function listHistory(userId: string): Promise<SearchHistoryDto[]> {
  const rows = await searchRepository.findHistory(userId);
  return rows.map((row) => ({ ...row, searchedAt: row.searchedAt.toISOString() }));
}

export async function deleteHistory(userId: string, id: string) {
  await searchRepository.deleteOne(userId, id);
}

export async function clearHistory(userId: string) {
  await searchRepository.deleteAll(userId);
}

/**
 * "Tìm nhiều": từ khoá nhiều người tìm trong TRENDING_DAYS ngày qua.
 * Chưa đủ TRENDING_MIN từ khoá (app mới, ít người dùng) thì bù bằng tên chuyên mục.
 */
export async function listTrending(now = new Date()) {
  const rows = await searchRepository.findTrending(new Date(now.getTime() - TRENDING_DAYS * DAY_MS), TRENDING_LIMIT);
  const keywords = rows.map((row) => row.keyword);
  if (keywords.length >= TRENDING_MIN) return distinctTexts(keywords, TRENDING_LIMIT);
  const categories = await searchRepository.findCategoryNames(TRENDING_LIMIT);
  return distinctTexts([...keywords, ...categories.map((row) => row.name)], TRENDING_LIMIT);
}

/** Gợi ý theo nội dung đang gõ; rỗng khi chưa gõ chữ/số nào */
export async function listSuggestions({ words, limit }: SuggestionsQuery) {
  if (!words.length) return [];
  return distinctTexts(await searchRepository.findSuggestions(words, limit), limit);
}

const emptyPage = ({ page, limit }: AccountSearchQuery['pagination']) => ({ items: [], page: { page, limit, totalItems: 0 } });

/** Sắp [rows] theo thứ tự [ids] (kết quả SQL đã xếp hạng) */
const inOrder = <T extends { id: string }>(ids: string[], rows: T[]) => {
  const byId = new Map(rows.map((row) => [row.id, row]));
  return ids.map((id) => byId.get(id)).filter((row): row is T => !!row);
};

/** Tìm shop uy tín theo tên (hoặc username chủ shop); mỗi shop như GET /shops/:id */
export async function searchShops(viewerId: string | undefined, { words, handle, usernameOnly, pagination }: AccountSearchQuery) {
  if (!words.length) return emptyPage(pagination);
  const { ids, totalItems } = await searchRepository.findShopIds(words, handle, usernameOnly, pagination);
  const shops = inOrder(ids, await prisma.shop.findMany({ where: { id: { in: ids } }, select: shopSelect }));
  return { items: await shopDtos(viewerId, shops), page: { page: pagination.page, limit: pagination.limit, totalItems } };
}

/** Tìm người dùng theo tên hiển thị hoặc username */
export async function searchUsers(viewerId: string | undefined, { words, handle, usernameOnly, pagination }: AccountSearchQuery) {
  if (!words.length) return emptyPage(pagination);
  const { ids, totalItems } = await searchRepository.findUserIds(words, handle, usernameOnly, pagination);
  const [users, listingCounts, followed] = await Promise.all([
    searchRepository.findUsers(ids),
    searchRepository.countVisibleListings(ids),
    searchRepository.findFollowedUserIds(viewerId, ids),
  ]);
  const items: UserSearchItemDto[] = inOrder(ids, users).map(({ _count, shop, ...user }) => ({
    ...user,
    followerCount: _count.followers,
    listingCount: listingCounts.get(user.id) ?? 0,
    isFollowing: followed.has(user.id),
    shopId: shop?.verificationType ? shop.id : null,
  }));
  return { items, page: { page: pagination.page, limit: pagination.limit, totalItems } };
}
