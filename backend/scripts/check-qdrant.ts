import 'dotenv/config';
import { randomUUID } from 'node:crypto';
import { GeminiProvider } from '../src/modules/ai/assistant/services/gemini.provider.js';
import { configuredVectorStore } from '../src/modules/ai/rag/repositories/qdrant.repository.js';
import { AppError } from '../src/common/errors/app-error.js';
import { lexicalVector } from '../src/modules/ai/rag/services/lexical.service.js';

// An explicit smoke test: creates the configured collection if missing, leaves no test points.
if (process.env.AI_LIVE_EVAL !== 'true' || !process.env.GEMINI_API_KEY) throw new Error('Set AI_LIVE_EVAL=true and configure Gemini/Qdrant first.');
const store = configuredVectorStore();
const provider = new GeminiProvider(process.env.GEMINI_API_KEY);
const id = randomUUID(), modelTag = `${provider.embeddingModel}:smoke:${id}`;
try {
  const signal = AbortSignal.timeout(60_000);
  await store.ensureCollection(signal);
  const vector = await provider.embed('Connection test only. This is not a ReStore policy document.', signal);
  await store.upsert([{ id, vector, lexical: lexicalVector('Restore connection test'), payload: { documentId: `smoke-${id}`, generation: id, model: modelTag, version: new Date().toISOString(), ordinal: 0 } }], signal);
  const found = await store.search(vector, modelTag, 0, signal, 'Restore connection test');
  if (!found.some((point) => point.id === id)) throw new Error('Hybrid round trip failed');
  // Negating the dense vector gives cosine -1: only the independent sparse branch can recover this point.
  const lexicalOnly = await store.search(vector.map((value) => -value), modelTag, 0, signal, 'Restore connection test');
  if (!lexicalOnly.some((point) => point.id === id)) throw new Error('Sparse branch failed to recover a dense miss');
  const noMatches = await store.search(vector.map((value) => -value), modelTag, 0, signal, 'zzzxxyy987654321');
  if (noMatches.length) throw new Error('Unrelated sparse query returned results');
  console.log(JSON.stringify({ collection: store.collection, dimensions: vector.length, hybridSearch: 'passed', lexicalOnlyRecovery: 'passed', unrelatedQuery: 'passed' }));
} catch (error) {
  console.error(JSON.stringify({ code: error instanceof AppError ? error.code : 'SMOKE_FAILED' }));
  process.exitCode = 1;
} finally {
  try { await store.remove([id], AbortSignal.timeout(20_000)); console.log('Test point cleanup completed.'); }
  catch { console.error(`Test point cleanup pending: ${id}`); process.exitCode = 1; }
}
