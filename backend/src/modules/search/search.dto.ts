import type { z } from 'zod';
import type { accountSearchQuery, suggestionsQuery } from './search.validator.js';

export type SuggestionsQuery = z.output<typeof suggestionsQuery>;

/** Một từ khoá trong lịch sử tìm kiếm */
export type SearchHistoryDto = { id: string; keyword: string; searchedAt: string };

export type AccountSearchQuery = z.output<typeof accountSearchQuery>;

/**
 * Người dùng trong kết quả tìm kiếm. Người có shop uy tín không nằm ở đây mà hiện một lần ở kết quả shop,
 * nên shopId hiện luôn null (giữ khoá cho app cũ).
 */
export type UserSearchItemDto = {
  id: string; fullName: string; username: string; avatarUrl: string | null; bio: string | null;
  ratingAverage: number; ratingCount: number; followerCount: number; listingCount: number;
  isFollowing: boolean; shopId: string | null;
};
