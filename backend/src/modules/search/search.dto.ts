import type { z } from 'zod';
import type { accountSearchQuery, suggestionsQuery } from './search.validator.js';

export type SuggestionsQuery = z.output<typeof suggestionsQuery>;

/** Một từ khoá trong lịch sử tìm kiếm */
export type SearchHistoryDto = { id: string; keyword: string; searchedAt: string };

export type AccountSearchQuery = z.output<typeof accountSearchQuery>;

/**
 * Người dùng trong kết quả tìm kiếm. shopId: id shop uy tín của người này (null nếu không có),
 * để app gắn nhãn "Cửa hàng" và mở trang shop.
 */
export type UserSearchItemDto = {
  id: string; fullName: string; username: string; avatarUrl: string | null; bio: string | null;
  ratingAverage: number; ratingCount: number; followerCount: number; listingCount: number;
  isFollowing: boolean; shopId: string | null;
};
