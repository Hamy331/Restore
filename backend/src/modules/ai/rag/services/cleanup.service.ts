import { configuredVectorStore } from '../repositories/qdrant.repository.js';
import * as repository from '../repositories/rag.repository.js';
import type { VectorStore } from '../rag.type.js';

/** Safe to retry: Qdrant deletes are idempotent; the outbox is removed only after acknowledgement. */
export async function cleanupVectors(store: VectorStore = configuredVectorStore()) {
  await repository.retireStale(store.collection);
  const pending = await repository.pendingDeletions(store.collection);
  const ids = pending.map((row) => row.pointId);
  await store.remove(ids, AbortSignal.timeout(20_000));
  await repository.completeDeletions(store.collection, ids);
  return { deleted: ids.length, remaining: await repository.remainingDeletions(store.collection) };
}
