import { AppError } from '../../../../common/errors/app-error.js';
import { randomUUID } from 'node:crypto';
import type { AiProvider } from '../../assistant/assistant.type.js';
import * as repository from '../repositories/rag.repository.js';
import { configuredVectorStore } from '../repositories/qdrant.repository.js';
import type { VectorPoint, VectorStore } from '../rag.type.js';
import { ingestDocument } from './ingestion.service.js';
import { chunkText } from './chunking.service.js';
import { embedChunks } from './embedding.service.js';
import { cleanupVectors } from './cleanup.service.js';
import { lexicalVector } from './lexical.service.js';

export async function indexDocument(actorId: string, id: string, provider: AiProvider, store: VectorStore = configuredVectorStore()) {
  const document = await ingestDocument(id);
  const chunks = chunkText(document.text);
  if (chunks.length > 40) throw new AppError(400, 'KNOWLEDGE_TOO_LARGE', 'Chia tài liệu thành các tài liệu nhỏ hơn trước khi tạo embedding.');
  const lease = await repository.beginIndex(id, document.version);
  let points: VectorPoint[] = [];
  try {
    const signal = AbortSignal.timeout(150_000);
    await store.ensureCollection(signal);
    const rows = await embedChunks(chunks, provider, signal);
    points = rows.map((row, ordinal) => ({ id: randomUUID(), vector: row.embedding, lexical: lexicalVector(row.text),
      payload: { documentId: id, generation: lease, model: provider.embeddingModel, version: document.version.toISOString(), ordinal },
    }));
    await store.upsert(points, signal);
    // Publish only after Qdrant acknowledges all points. Old generation stays readable until commit.
    const published = await repository.publishIndex(actorId, id, document.version, provider.embeddingModel, store.collection, lease,
      rows.map((row, ordinal) => ({ id: points[ordinal].id, text: row.text })));
    try {
      const cleanup = await cleanupVectors(store);
      return { ...published, cleanupPending: cleanup.remaining > 0 };
    } catch {
      // A cleanup outage must not roll back or hide the successfully published generation.
      return { ...published, cleanupPending: true };
    }
  } catch (error) {
    try {
      // Handles ambiguous DB commit: never queue points referenced by the committed index.
      await repository.queueUnpublished(points.map((point) => point.id), store.collection);
      await repository.failIndex(id, lease, error instanceof AppError ? error.code : 'AI_INDEX_FAILED');
    } catch { /* A DB outage leaves unreferenced points, which are never used for answers. */ }
    if (error instanceof AppError) throw error;
    throw new AppError(503, 'AI_INDEX_FAILED', 'Chưa lập được chỉ mục tài liệu. Vui lòng thử lại.');
  }
}
