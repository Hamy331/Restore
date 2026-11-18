import { createHash } from 'node:crypto';

/** Namespace cố định của dữ liệu seed ReStore (UUID v5) */
const NAMESPACE = 'b3c0f1d2-5e4a-4c8b-9a7d-2f6e1c3b8a90';

/**
 * UUID cố định cho bản ghi seed, sinh từ tên của nó (VD "shop-samsung", "demo-listing-galaxy-s23").
 * Cùng tên luôn ra cùng UUID (UUID v5), nên chạy seed lại vẫn cập nhật đúng bản ghi cũ,
 * và script đổi id (prisma/remap-seed-ids.ts) biết id cũ dạng chữ ứng với UUID nào.
 */
export function seedUuid(name: string): string {
  const namespace = Buffer.from(NAMESPACE.replace(/-/g, ''), 'hex');
  const hash = createHash('sha1').update(namespace).update(name, 'utf8').digest();
  const bytes = hash.subarray(0, 16);
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
