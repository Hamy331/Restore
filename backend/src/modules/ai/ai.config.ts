import { z } from 'zod';

// Technical bounds, not business quotas. Keep query and prefetch pagination consistent.
export const SEARCH_LIMITS = { results: 5, candidates: 200, pageSize: 40 } as const;
const indexingEnvironment = z.object({
  AI_LISTING_INDEX_BATCH_SIZE: z.coerce.number().int().min(1).max(50).default(10),
  AI_LISTING_INDEX_INTERVAL_MS: z.coerce.number().int().min(10000).max(3600000).default(60000),
});
export const listingIndexConfig = () => indexingEnvironment.parse(process.env);
export const INDEX_TIMEOUT_MS = 150000;
