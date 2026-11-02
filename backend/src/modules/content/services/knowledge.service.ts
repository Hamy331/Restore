import { audit } from '../../../common/audit/admin-audit.js';
import { ADMIN_PAGE_SIZE, changed, version } from '../../../common/validation/admin-input.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import type { KnowledgeInput, KnowledgeSearchQuery, PageQuery } from '../content.dto.js';
import { normalizeKnowledge } from '../content.validator.js';
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

/* ---------- Quản trị (/admin/knowledge) ---------- */

/** Tài liệu hệ thống chứa danh mục và thuộc tính, đồng bộ từ bảng Category */
const CATALOG_DOCUMENT_ID = 'system-catalog';

/** Mọi tài liệu, 25 mỗi trang */
export async function listForAdmin({ page }: PageQuery) {
  const [items, total] = await knowledgeRepository.findPage((page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  return { items, total, page };
}

/** Ghi danh mục đang dùng vào tài liệu hệ thống và lập chỉ mục ngay */
export function syncCatalog(actorId: string) {
  return withQuotaTransaction(async (tx) => {
    const categories = await knowledgeRepository.findActiveCategories(tx);
    const content = categories.map((item) => `${item.id}: ${item.name}\n${JSON.stringify(item.metadata)}`).join('\n\n');
    const item = await knowledgeRepository.upsertById(tx, CATALOG_DOCUMENT_ID, {
      title: 'Danh mục và thuộc tính sản phẩm', content, indexedText: normalizeKnowledge(content), syncedAt: new Date(), active: true,
    });
    await audit(tx, actorId, 'CATALOG_SYNC', 'KNOWLEDGE', item.id, `Đồng bộ ${categories.length} danh mục từ database`);
    return { categories: categories.length, syncedAt: item.syncedAt };
  });
}

/** Tạo (không có [id]) hoặc sửa tài liệu (updatedAt phải khớp); tài liệu cần lập chỉ mục lại sau khi lưu */
export function save(actorId: string, id: string | undefined, { data: input, updatedAt }: KnowledgeInput) {
  const data = { ...input, indexedText: null, syncedAt: null };
  return withQuotaTransaction(async (tx) => {
    if (id) {
      changed(await knowledgeRepository.updateWhereVersion(tx, id, version(updatedAt), data));
      await audit(tx, actorId, 'UPDATE', 'KNOWLEDGE', id, data.title);
      return knowledgeRepository.findByIdOrThrow(tx, id);
    }
    const item = await knowledgeRepository.create(tx, data);
    await audit(tx, actorId, 'CREATE', 'KNOWLEDGE', item.id, item.title);
    return item;
  });
}

/** Lập chỉ mục tìm kiếm cho tài liệu (updatedAt phải khớp) */
export function index(actorId: string, id: string, updatedAt: unknown) {
  return withQuotaTransaction(async (tx) => {
    const doc = await knowledgeRepository.findByIdOrThrow(tx, id);
    changed(await knowledgeRepository.updateWhereVersion(tx, id, version(updatedAt),
      { indexedText: normalizeKnowledge(doc.title + '\n' + doc.content), syncedAt: new Date() }));
    await audit(tx, actorId, 'INDEX', 'KNOWLEDGE', id, 'Lập chỉ mục tìm kiếm nội dung');
    return { indexed: true };
  });
}

/** Xóa tài liệu và chỉ mục (updatedAt phải khớp) */
export function remove(actorId: string, id: string, updatedAt: unknown) {
  return withQuotaTransaction(async (tx) => {
    changed(await knowledgeRepository.deleteWhereVersion(tx, id, version(updatedAt)));
    await audit(tx, actorId, 'DELETE', 'KNOWLEDGE', id, 'Xóa tài liệu và chỉ mục');
    return { deleted: true };
  });
}
