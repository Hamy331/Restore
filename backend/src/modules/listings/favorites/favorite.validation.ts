import { parsePagination } from '../../../common/http/pagination.js';
import { requiredString } from '../../../common/validation/parsers.js';

export const parseListingId = (params: Record<string, unknown>) => ({
  id: requiredString(params.id, 'id', { max: 64 }),
});

export const parseFavoritesQuery = (query: Record<string, unknown>) =>
  parsePagination(query, { defaultLimit: 20, maxLimit: 100 });
