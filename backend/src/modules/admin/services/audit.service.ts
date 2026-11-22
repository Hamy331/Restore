import { ADMIN_PAGE_SIZE } from '../../../common/validation/admin-input.js';
import type { AuditQuery } from '../admin.dto.js';
import * as auditRepository from '../repositories/audit.repository.js';

/** Nhật ký quản trị, 25 dòng mỗi trang */
export async function listLogs({ page, ...filters }: AuditQuery) {
  const [logs, total] = await auditRepository.findPage((page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE, filters);
  return { items: await withActors(logs), total, page };
}

/** Gắn tên, email người xử lý vào từng dòng nhật ký (AdminAudit chỉ lưu actorId) */
export async function withActors<T extends { actorId: string }>(logs: T[]) {
  const actors = new Map((await auditRepository.findActors([...new Set(logs.map((l) => l.actorId))])).map((u) => [u.id, u]));
  return logs.map((log) => ({ ...log, actor: actors.get(log.actorId) ?? null }));
}
