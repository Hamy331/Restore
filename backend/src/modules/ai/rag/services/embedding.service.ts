import type { AiProvider } from '../../assistant/assistant.type.js';

/** Sequential calls bound concurrency and respect the indexing operation deadline. */
export async function embedChunks(texts: string[], provider: AiProvider, signal: AbortSignal) {
  const rows: Array<{ text: string; embedding: number[] }> = [];
  for (const text of texts) {
    signal.throwIfAborted();
    rows.push({ text, embedding: await provider.embed(text, signal) });
  }
  return rows;
}
