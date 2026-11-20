import { randomUUID } from 'node:crypto';
import { AppError } from '../../../../common/errors/app-error.js';
import type { AiProvider } from '../assistant.type.js';
import type { VectorStore } from '../../rag/rag.type.js';
import { lexicalVector } from '../../rag/services/lexical.service.js';
import { cleanupVectors } from '../../rag/services/cleanup.service.js';
import { INDEX_TIMEOUT_MS, listingIndexConfig } from '../../ai.config.js';
import { listingVectorStore } from '../repositories/listing-vector.repository.js';
import * as repository from '../repositories/listing-index.repository.js';
import { listingHash, listingText } from './listing-source.service.js';

export async function syncListingIndex(provider: AiProvider, store: VectorStore = listingVectorStore()) {
  const signal = AbortSignal.timeout(INDEX_TIMEOUT_MS);
  await store.ensureCollection(signal);
  await repository.retireHidden();
  await cleanupVectors(store);
  const ids = await repository.pendingListings(provider.embeddingModel, store.collection, listingIndexConfig().AI_LISTING_INDEX_BATCH_SIZE);
  let indexed = 0;
  for (const { id } of ids) {
    const listing = await repository.findPublicListing(id);
    if (!listing) continue;
    const text = listingText(listing), sourceHash = listingHash(listing), pointId = randomUUID();
    try {
      await store.upsert([{ id: pointId, vector: await provider.embed(text, signal), lexical: lexicalVector(text), payload: {
        documentId: id, generation: pointId, version: sourceHash, ordinal: 0, model: provider.embeddingModel,
        price: Number(listing.price), categoryId: listing.categoryId ?? '',
      } }], signal);
      await repository.publishIndex(id, pointId, sourceHash, provider.embeddingModel, store.collection);
      indexed++;
    } catch (error) {
      await repository.queueUnpublishedPoint(pointId, store.collection);
      if (!(error instanceof AppError) || error.code !== 'LISTING_CHANGED') throw error;
    }
  }
  await cleanupVectors(store);
  return { indexed, scanned: ids.length, collection: store.collection };
}
