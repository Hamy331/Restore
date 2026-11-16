import { z } from 'zod';
import { AppError } from '../../common/errors/app-error.js';
import { idParam, int } from '../../common/validation/schemas.js';
import { searchWords } from '../listings/index.js';

/** Query GET /search/suggestions: q (tối đa 100 ký tự), limit 1-20 (mặc định 8) */
export const suggestionsQuery = z.object({
  q: z.unknown().optional(),
  limit: int('limit', { min: 1, max: 20, fallback: 8 }),
}).transform(({ q, limit }) => {
  if (q !== undefined && (typeof q !== 'string' || q.trim().length > 100)) {
    throw new AppError(400, 'INVALID_QUERY', 'Từ khóa tìm kiếm không hợp lệ.', 'q');
  }
  return { words: typeof q === 'string' ? searchWords(q) : [], limit };
});

/** Params DELETE /search/history/:id */
export const historyIdParams = idParam();
