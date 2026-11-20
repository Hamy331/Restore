import { createHash } from 'node:crypto';
import { normalizeKnowledge } from '../../../content/content.validator.js';
import type { SparseVector } from '../rag.type.js';

// Version the vector name whenever tokenization/weighting changes; existing points need reindexing.
export const LEXICAL_VECTOR = 'lexical_v1';
const stopwords = new Set('va la cua cho nhung cac mot nhieu nay do thi ma voi toi ban minh co duoc khong the nao gi khi de o in the a an and or is to of for'.split(' '));

/** Local log-TF weights; Qdrant adds corpus IDF at query time. This is TF-IDF, not BM25. */
export function lexicalVector(text: string): SparseVector {
  const words = normalizeKnowledge(text).match(/[a-z0-9]+/g) ?? [];
  const counts = new Map<number, number>();
  for (const word of words) {
    if (stopwords.has(word)) continue;
    const id = createHash('sha256').update(word).digest().readUInt32BE(0);
    counts.set(id, (counts.get(id) ?? 0) + 1);
  }
  const terms = [...counts].sort(([a], [b]) => a - b);
  return { indices: terms.map(([id]) => id), values: terms.map(([, count]) => 1 + Math.log(count)) };
}
