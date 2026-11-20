import { AppError } from '../../../../common/errors/app-error.js';
import { findDocument } from '../repositories/rag.repository.js';

/** Only admin-managed, active and explicitly indexed knowledge is eligible. */
export async function ingestDocument(id: string) {
  const document = await findDocument(id);
  if (!document) throw new AppError(404, 'KNOWLEDGE_NOT_READY', 'Tài liệu phải đang bật và đã được lập chỉ mục nội dung.');
  return { id: document.id, version: document.updatedAt, text: document.title + '\n' + document.content };
}
