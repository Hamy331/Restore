import { ADMIN_PAGE_SIZE } from '../../../common/validation/admin-input.js';
import type { PageQuery } from '../admin.dto.js';
import * as auditRepository from '../repositories/audit.repository.js';

/** Nhật ký quản trị, 25 dòng mỗi trang */
export async function listLogs({ page }: PageQuery) {
  const [items, total] = await auditRepository.findPage((page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  return { items, total, page };
}
