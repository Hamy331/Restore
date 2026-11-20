import type { Source } from '../../assistant/assistant.type.js';

/** Sources are built from server records, never from model-provided links. */
export function buildContext(chunks: Array<{ documentId: string; document: { title: string }; text: string }>): Source[] {
  return chunks.map((chunk) => ({ id: chunk.documentId, title: chunk.document.title, text: chunk.text }));
}
