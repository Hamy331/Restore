import { audit } from '../../admin/admin.service.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import type { KnowledgeSearchQuery } from '../content.dto.js';
import * as knowledgeRepository from '../repositories/knowledge.repository.js';

/**
 * Tìm tài liệu kiến thức theo từ khóa (đã bỏ dấu).
 * ponytail: lexical retrieval, not a generative LLM; replace with embeddings when an AI provider is configured.
 */
export async function search({ q }: KnowledgeSearchQuery) {
  const documents = await knowledgeRepository.searchIndexed(q.split(/\s+/).slice(0, 10));
  return { mode: 'lexical', documents };
}

/** Tải lên tài liệu văn bản, ghi AdminAudit */
export function upload(actorId: string, title: string, content: string) {
  return withQuotaTransaction(async (tx) => {
    const doc = await knowledgeRepository.createDocument(tx, { title, content, active: true });
    await audit(tx, actorId, 'UPLOAD', 'KNOWLEDGE', doc.id, title);
    return doc;
  });
}
