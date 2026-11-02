import { integerInRange } from '../validation/parsers.js';

export type Pagination = { page: number; limit: number; skip: number };

/**
 * Đọc `page` (từ 1) và `limit` từ query.
 * `pageSize` được nhận như tên cũ của `limit`.
 */
export function parsePagination(
  query: Record<string, unknown>,
  { defaultLimit = 10, maxLimit = 50 } = {},
): Pagination {
  const page = integerInRange(query.page, 'page', { min: 1, max: 100_000, fallback: 1 });
  const limit = integerInRange(query.limit ?? query.pageSize, 'limit', { min: 1, max: maxLimit, fallback: defaultLimit });
  return { page, limit, skip: (page - 1) * limit };
}
