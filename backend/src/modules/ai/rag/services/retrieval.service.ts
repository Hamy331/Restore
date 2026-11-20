import type { AiProvider } from '../../assistant/assistant.type.js';
import { validChunks } from '../repositories/rag.repository.js';
import { configuredVectorStore } from '../repositories/qdrant.repository.js';
import type { VectorStore } from '../rag.type.js';
import { AppError } from '../../../../common/errors/app-error.js';
import { rankChunks } from './ranking.service.js';
import { buildContext } from './context.service.js';

export async function retrieve(query: string, provider: AiProvider, signal: AbortSignal, store: VectorStore = configuredVectorStore()) {
  const vector = await provider.embed(query, signal);
  const candidates: Array<Awaited<ReturnType<typeof validChunks>>[number] & { score: number }> = [];
  for (let offset = 0; offset < 200; offset += 40) {
    const hits = await store.search(vector, provider.embeddingModel, offset, signal, query);
    const scores = new Map(hits.map((hit) => [hit.id, hit.score]));
    const rows = await validChunks(hits.map((hit) => hit.id), provider.embeddingModel, store.collection);
    candidates.push(...rows.map((row) => ({ ...row, score: scores.get(row.id)! })));
    if (candidates.length >= 20 || hits.length < 40) return buildContext(rankChunks(candidates));
  }
  if (candidates.length) return buildContext(rankChunks(candidates));
  throw new AppError(503, 'QDRANT_STALE_INDEX', 'Chỉ mục cần dọn dữ liệu cũ và đồng bộ lại.');
}
