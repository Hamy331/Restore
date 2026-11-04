import { Prisma } from '@prisma/client';

/** Việc chạy thêm khi admin duyệt một tin, trong cùng transaction với quyết định duyệt */
export type ListingApprovedHook = (tx: Prisma.TransactionClient, listingId: string, approvedAt: Date) => Promise<void>;

const hooks: ListingApprovedHook[] = [];

/**
 * Đăng ký việc chạy khi tin chuyển PENDING → AVAILABLE (VD wanted-alerts chấm điểm tin mới).
 * Module khác đăng ký qua index.ts của nó, nên listings không phải import ngược module đó.
 */
export function onListingApproved(hook: ListingApprovedHook) {
  if (!hooks.includes(hook)) hooks.push(hook);
}

export async function runApprovalHooks(tx: Prisma.TransactionClient, listingId: string, approvedAt: Date) {
  for (const hook of hooks) await hook(tx, listingId, approvedAt);
}
