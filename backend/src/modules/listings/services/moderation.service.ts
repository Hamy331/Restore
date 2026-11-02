import { ListingStatus, Prisma } from '@prisma/client';
import { audit } from '../../../common/audit/admin-audit.js';
import { AppError } from '../../../common/errors/app-error.js';
import { ADMIN_PAGE_SIZE, changed, text } from '../../../common/validation/admin-input.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import { AdminDecisionInput, AdminListingQuery, DecisionInput, toOwnerListingDto } from '../listing.dto.js';
import type { ModerationAction } from '../listing.type.js';
import * as listingRepository from '../repositories/listing.repository.js';

/**
 * Ra quyết định trên một tin trong transaction [tx], ghi AdminAudit.
 * - PENDING: APPROVE (cần ảnh, danh mục và tình trạng còn dùng), REJECT, REQUEST_CHANGES
 * - AVAILABLE: REMOVE
 * updatedAt phải khớp [expected] lúc admin mở tin (409 ADMIN_STALE nếu không).
 * Dùng ở /listings/admin, /admin/listings và khi xử lý báo cáo vi phạm.
 */
export async function moderate(tx: Prisma.TransactionClient, actorId: string, id: string, action: ModerationAction | string,
  reason: string, expected: Date) {
  const item = await listingRepository.findForModeration(tx, id);
  if (!item) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin.');
  const allowed = item.status === 'PENDING' ? ['APPROVE', 'REJECT', 'REQUEST_CHANGES'] : item.status === 'AVAILABLE' ? ['REMOVE'] : [];
  if (!allowed.includes(action)) throw new AppError(409, 'INVALID_DECISION', 'Tin không ở trạng thái cho phép.');
  if (action === 'APPROVE') {
    if (!item.images.length) throw new AppError(400, 'INVALID_LISTING', 'Tin cần ít nhất một ảnh.');
    const [category, condition] = await Promise.all([
      listingRepository.findActiveCategory(tx, item.categoryId ?? ''),
      item.condition ? listingRepository.findConditionPolicy(tx, item.condition) : null,
    ]);
    if (!category || !item.condition || condition?.active === false) {
      throw new AppError(409, 'INVALID_LISTING', 'Danh mục hoặc tình trạng không còn được sử dụng.');
    }
  }
  const status = action === 'APPROVE' ? ListingStatus.AVAILABLE : ListingStatus.REJECTED;
  changed(await listingRepository.updateWhereVersion(tx, id, item.status, expected,
    { status, reviewReason: action === 'APPROVE' ? null : reason }));
  await audit(tx, actorId, action, 'LISTING', id, reason, { status: item.status }, { status });
}

/* ---------- /listings/admin ---------- */

/** Duyệt hoặc từ chối tin đang chờ; updatedAt phải khớp lúc admin mở tin */
export async function decide(actorId: string, id: string, { decision, reason, expectedUpdatedAt }: DecisionInput) {
  await withQuotaTransaction((tx) => moderate(tx, actorId, id, decision === 'APPROVED' ? 'APPROVE' : 'REJECT',
    text(reason, 'reason', decision === 'APPROVED' ? 0 : 5, 300), expectedUpdatedAt));
}

/** Tối đa 100 tin chờ duyệt, gửi sớm trước */
export async function listPending() {
  return (await listingRepository.findPending()).map(toOwnerListingDto);
}

/* ---------- /admin/listings ---------- */

/** Mọi tin, lọc trạng thái / tiêu đề, 25 tin mỗi trang */
export async function listForAdmin({ status, q, page }: AdminListingQuery) {
  const [items, total] = await listingRepository.findAdminPage({ status, q }, (page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  return { items, total, page };
}

/** Quyết định của admin trên một tin bất kỳ */
export async function adminDecide(actorId: string, id: string, { action, reason, expectedUpdatedAt }: AdminDecisionInput) {
  return withQuotaTransaction(async (tx) => {
    await moderate(tx, actorId, id, action, reason, expectedUpdatedAt);
    return { updated: true };
  });
}

/** Tin cho trang quản trị (null nếu không có) */
export const getAdminListing = (id: string) => listingRepository.findAdminListing(id);
