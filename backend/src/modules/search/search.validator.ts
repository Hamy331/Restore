import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { idParam, int, pageQuery, parse } from '../../common/validation/schemas.js';
import { exactSearchWords, searchWords } from '../listings/index.js';

/** Query GET /search/suggestions: q (tối đa 100 ký tự), limit 1-20 (mặc định 8) */
export const suggestionsQuery = z.object({
  q: z.unknown().optional(),
  limit: int('limit', { min: 1, max: 20, fallback: 8 }),
}).transform(({ q, limit }) => {
  if (q !== undefined && (typeof q !== 'string' || q.trim().length > 100)) {
    throw new AppError(400, 'INVALID_QUERY', 'Từ khóa tìm kiếm không hợp lệ.', 'q');
  }
  return {
    words: typeof q === 'string' ? searchWords(q) : [],
    exactWords: typeof q === 'string' ? exactSearchWords(q) : [],
    limit,
  };
});

/** Params DELETE /search/history/:id */
export const historyIdParams = idParam();

/**
 * Query GET /search/shops, /search/users: q (tối đa 100 ký tự), page, limit (1-30, mặc định 10).
 * Gõ "@abc" thì chỉ tìm theo username. Kết quả: { words, handle, usernameOnly, pagination }
 *  - words: các từ đã bỏ dấu; handle: các từ ghép liền (so với username đã bỏ ký tự đặc biệt)
 */
export const accountSearchQuery = z.object({
  q: z.unknown().optional(), page: z.unknown().optional(), limit: z.unknown().optional(),
}).transform(({ q, page, limit }) => {
  if (q !== undefined && (typeof q !== 'string' || q.trim().length > 100)) {
    throw new AppError(400, 'INVALID_QUERY', 'Từ khóa tìm kiếm không hợp lệ.', 'q');
  }
  const text = typeof q === 'string' ? q.trim() : '';
  const words = searchWords(text);
  return {
    words,
    handle: words.join(''),
    usernameOnly: text.startsWith('@'),
    pagination: parse(pageQuery({ defaultLimit: 10, maxLimit: 30 }), { page, limit }),
  };
});
