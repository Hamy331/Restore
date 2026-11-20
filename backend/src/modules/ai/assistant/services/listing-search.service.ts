import { toListingDto, type ListingRecord } from '../../../listings/listing.dto.js';
import type { VectorStore } from '../../rag/rag.type.js';
import type { AiProvider } from '../assistant.type.js';
import { SEARCH_LIMITS } from '../../ai.config.js';
import { listingVectorStore } from '../repositories/listing-vector.repository.js';
import * as repository from '../repositories/listing-index.repository.js';
import type { ListingSearchInput } from '../repositories/listing-index.repository.js';
import { listingHash, matchesListingBrand } from './listing-source.service.js';

export async function searchListings(input: ListingSearchInput, provider: AiProvider, signal: AbortSignal, store?: VectorStore) {
  // Browse remains available without a vector service; never embed an empty query.
  if (!input.q.trim()) {
    const rows = await repository.browse(input);
    return rows.filter((row) => matchesListingBrand(row, input.brand)).slice(0, SEARCH_LIMITS.results).map((row) => toListingDto(row));
  }
  store ??= listingVectorStore();
  const vector = await provider.embed(input.q, signal);
  const found: ListingRecord[] = [];
  for (let offset = 0; offset < SEARCH_LIMITS.candidates; offset += SEARCH_LIMITS.pageSize) {
    const hits = await store.search(vector, provider.embeddingModel, offset, signal, input.q, {
      minPrice: input.minPrice ? Number(input.minPrice) : undefined,
      maxPrice: input.maxPrice ? Number(input.maxPrice) : undefined,
      categoryId: input.categoryId,
    });
    const rows = await repository.findCurrentCandidates(hits.map((hit) => hit.id), provider.embeddingModel, store.collection, input);
    const byPoint = new Map(rows.map((row) => [row.pointId, row]));
    for (const hit of hits) {
      const row = byPoint.get(hit.id);
      if (row && listingHash(row.listing) === row.sourceHash && matchesListingBrand(row.listing, input.brand)) found.push(row.listing);
      if (found.length === SEARCH_LIMITS.results) break;
    }
    if (found.length >= SEARCH_LIMITS.results || hits.length < SEARCH_LIMITS.pageSize) break;
  }
  return found.map((row) => toListingDto(row));
}
