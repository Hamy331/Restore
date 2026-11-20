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

/**
 * Một quyết định của admin trên tin (hoặc bản sửa của tin), sau khi ghi xong trong transaction.
 * action: APPROVE | REJECT | REQUEST_CHANGES | REMOVE; edit = true khi quyết định áp lên bản sửa.
 */
export type ListingModeration = {
  listingId: string;
  ownerId: string;
  title: string;
  image: string | null;
  action: string;
  reason: string;
  edit: boolean;
  /** Duyệt nhưng chưa tới ngày hẹn đăng (tin chờ, job tự hiện) */
  scheduled: boolean;
  /** Số xu đã hoàn vào ví khi tin chờ duyệt bị từ chối (2.3 gộp vào thông báo từ chối) */
  refunded?: number;
  /** Bản sửa được duyệt làm giá giảm khi tin đang hiển thị (3.7): giá cũ, giá mới (VND) */
  priceDrop?: { from: string; to: string };
};

export type ListingModeratedHook = (tx: Prisma.TransactionClient, event: ListingModeration) => Promise<void>;

const moderatedHooks: ListingModeratedHook[] = [];

/** Đăng ký việc chạy sau mỗi quyết định duyệt / từ chối / gỡ tin (VD gửi thông báo cho người bán) */
export function onListingModerated(hook: ListingModeratedHook) {
  if (!moderatedHooks.includes(hook)) moderatedHooks.push(hook);
}

export async function runModeratedHooks(tx: Prisma.TransactionClient, event: ListingModeration) {
  for (const hook of moderatedHooks) await hook(tx, event);
}

export async function runApprovalHooks(tx: Prisma.TransactionClient, listingId: string, approvedAt: Date) {
  for (const hook of hooks) await hook(tx, listingId, approvedAt);
}
