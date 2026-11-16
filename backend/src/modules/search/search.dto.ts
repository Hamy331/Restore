import type { z } from 'zod';
import type { suggestionsQuery } from './search.validator.js';

export type SuggestionsQuery = z.output<typeof suggestionsQuery>;

/** Một từ khoá trong lịch sử tìm kiếm */
export type SearchHistoryDto = { id: string; keyword: string; searchedAt: string };
