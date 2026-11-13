import { ListingStatus, Prisma } from '@prisma/client';
import { audit } from '../../../common/audit/admin-audit.js';
import { AppError } from '../../../common/errors/app-error.js';
import { ADMIN_PAGE_SIZE, changed, text } from '../../../common/validation/admin-input.js';
import { storePackageForUser, withQuotaTransaction } from '../../commerce/index.js';
import { captureListingHold, releaseListingHold } from '../../credits/index.js';
import { AdminDecisionInput, AdminListingQuery, DecisionInput, toOwnerListingDto, toRevisionDto } from '../listing.dto.js';
import { removeStoredImages, revisionOnlyImages } from './image.service.js';
import { approvalWindow, categoryHasCondition } from '../listing-lifecycle.js';
import { freeDaysFor } from '../display-pricing.js';
import type { ModerationAction } from '../listing.type.js';
import * as listingRepository from '../repositories/listing.repository.js';
import { runApprovalHooks } from './approval-hooks.js';

/**
 * Ra quyết định trên một tin trong transaction [tx], ghi AdminAudit.
 * - PENDING: APPROVE (cần ảnh, danh mục và tình trạng còn dùng), REJECT, REQUEST_CHANGES
 * - AVAILABLE: REMOVE
 * updatedAt phải khớp [expected] lúc admin mở tin (409 ADMIN_STALE nếu không).
 * Dùng ở /listings/admin, /admin/listings và khi xử lý báo cáo vi phạm.
 * Duyệt xong thì chạy các hook onListingApproved (VD chấm điểm thông báo "Báo khi có hàng").
 * Tin đã duyệt có bản sửa chờ duyệt: APPROVE / REJECT / REQUEST_CHANGES áp lên bản sửa (xem moderateRevision).
 * Trả về URL ảnh không còn dùng, để xóa file sau khi transaction xong (removeStoredImages).
 */
export async function moderate(tx: Prisma.TransactionClient, actorId: string, id: string, action: ModerationAction | string,
  reason: string, expected: Date): Promise<string[]> {
  const item = await listingRepository.findForModeration(tx, id);
  if (!item) throw new AppError(404, 'LISTING_NOT_FOUND', 'Không tìm thấy tin.');
  if (item.revision?.status === 'PENDING' && action !== 'REMOVE') {
    return moderateRevision(tx, actorId, { ...item, revision: item.revision }, action, reason, expected);
  }
  const allowed = item.status === 'PENDING' ? ['APPROVE', 'REJECT', 'REQUEST_CHANGES'] : item.status === 'AVAILABLE' ? ['REMOVE'] : [];
  if (!allowed.includes(action)) throw new AppError(409, 'INVALID_DECISION', 'Tin không ở trạng thái cho phép.');
  let expiresAt: Date | undefined;
  let scheduled = false;
  let startsAt: Date | null = null;
  const now = new Date();
  if (action === 'APPROVE') {
    if (!item.images.length) throw new AppError(400, 'INVALID_LISTING', 'Tin cần ít nhất một ảnh.');
    const [category, condition] = await Promise.all([
      listingRepository.findActiveCategory(tx, item.categoryId ?? ''),
      item.condition ? listingRepository.findConditionPolicy(tx, item.condition) : null,
    ]);
    if (!category || (categoryHasCondition(category.metadata) && !item.condition) || condition?.active === false) {
      throw new AppError(409, 'INVALID_LISTING', 'Danh mục hoặc tình trạng không còn được sử dụng.');
    }
    // Bắt đầu tính thời gian hiển thị từ ngày hẹn (hoặc lúc duyệt nếu muộn hơn), đủ số ngày người bán chọn;
    // tin sửa lại lúc còn hạn giữ hạn cũ. Chưa tới ngày hẹn thì tin chờ (HIDDEN + startsAt), job tự hiện.
    const days = item.displayDays ?? freeDaysFor(category, (await storePackageForUser(tx, item.ownerId, now)).package);
    ({ expiresAt, startsAt, scheduled } = approvalWindow(item.expiresAt, item.startsAt, now, days));
  }
  const status = action === 'APPROVE' ? (scheduled ? ListingStatus.HIDDEN : ListingStatus.AVAILABLE) : ListingStatus.REJECTED;
  // Tin bị từ chối / gỡ không còn suất đã trả: sửa lại để đăng thì phải xin suất mới
  changed(await listingRepository.updateWhereVersion(tx, id, item.status, expected,
    { status, reviewReason: action === 'APPROVE' ? null : reason,
      ...(expiresAt ? { expiresAt, startsAt, ...(!scheduled && { publishedAt: now }) } : { paidCredits: 0 }) }));
  await audit(tx, actorId, action, 'LISTING', id, reason, { status: item.status }, { status });
  // Gỡ tin: bản sửa chưa duyệt (nếu có) cũng bỏ
  const removed: string[] = [];
  if (action === 'REMOVE') {
    const revision = await listingRepository.deleteRevision(tx, id);
    removed.push(...revisionOnlyImages(revision?.images ?? [], item.images));
  }
  if (action === 'APPROVE') {
    // Xu giữ khi gửi tin vượt hạn mức được trừ hẳn
    await captureListingHold(tx, id);
    await runApprovalHooks(tx, id, new Date());
  } else {
    // Từ chối khi đang chờ duyệt: hoàn xu đang giữ (đã duyệt rồi bị gỡ thì không hoàn)
    await releaseListingHold(tx, id, `Hoàn xu · tin bị từ chối: ${item.title}`.slice(0, 200));
  }
  return removed;
}

type ModerationItem = NonNullable<Awaited<ReturnType<typeof listingRepository.findForModeration>>>;

/**
 * Duyệt bản sửa của tin đã duyệt (tin vẫn hiện bản cũ trong lúc chờ). updatedAt phải khớp updatedAt
 * của bản sửa lúc admin mở (409 ADMIN_STALE nếu người bán vừa sửa tiếp).
 * - APPROVE: nội dung + ảnh bản sửa thay vào tin; trạng thái, hạn hiển thị, xu đã trả, đẩy tin, Hot sale giữ nguyên.
 * - REJECT / REQUEST_CHANGES: bản sửa thành REJECTED kèm lý do, tin giữ nguyên bản cũ.
 */
async function moderateRevision(tx: Prisma.TransactionClient, actorId: string,
  item: ModerationItem & { revision: NonNullable<ModerationItem['revision']> }, action: string, reason: string,
  expected: Date): Promise<string[]> {
  const { revision } = item;
  if (!['APPROVE', 'REJECT', 'REQUEST_CHANGES'].includes(action)) {
    throw new AppError(409, 'INVALID_DECISION', 'Tin không ở trạng thái cho phép.');
  }
  if (action !== 'APPROVE') {
    changed(await listingRepository.rejectRevision(tx, item.id, expected, reason));
    await audit(tx, actorId, `${action}_EDIT`, 'LISTING', item.id, reason, { edit: 'PENDING' }, { edit: 'REJECTED' });
    return [];
  }
  if (!revision.images.length) throw new AppError(400, 'INVALID_LISTING', 'Tin cần ít nhất một ảnh.');
  const [category, condition] = await Promise.all([
    listingRepository.findActiveCategory(tx, item.categoryId ?? ''),
    revision.condition ? listingRepository.findConditionPolicy(tx, revision.condition) : null,
  ]);
  if (!category || (categoryHasCondition(category.metadata) && !revision.condition) || condition?.active === false) {
    throw new AppError(409, 'INVALID_LISTING', 'Danh mục hoặc tình trạng không còn được sử dụng.');
  }
  changed(await listingRepository.applyRevision(tx, item.id, item.status, expected, {
    title: revision.title, description: revision.description, price: revision.price, originalPrice: revision.originalPrice,
    isNegotiable: revision.isNegotiable, condition: revision.condition, allowSale: revision.allowSale,
    allowExchange: revision.allowExchange, exchangeWish: revision.exchangeWish,
    attributes: revision.attributes as Prisma.InputJsonValue, location: (revision.location ?? Prisma.JsonNull) as Prisma.InputJsonValue,
    images: revision.images,
  }));
  await audit(tx, actorId, 'APPROVE_EDIT', 'LISTING', item.id, reason,
    { title: item.title, edit: 'PENDING' }, { title: revision.title, edit: 'APPROVED' });
  // Ảnh cũ không còn trong bản mới
  return item.images.filter((url) => !revision.images.includes(url));
}

/* ---------- /listings/admin ---------- */

/** Duyệt hoặc từ chối tin đang chờ; updatedAt phải khớp lúc admin mở tin */
export async function decide(actorId: string, id: string, { decision, reason, expectedUpdatedAt }: DecisionInput) {
  const removed = await withQuotaTransaction((tx) => moderate(tx, actorId, id, decision === 'APPROVED' ? 'APPROVE' : 'REJECT',
    text(reason, 'reason', decision === 'APPROVED' ? 0 : 5, 300), expectedUpdatedAt));
  await removeStoredImages(removed);
}

/**
 * Tối đa 100 tin chờ duyệt, gửi sớm trước, rồi tối đa 100 bản sửa của tin đã duyệt.
 * Bản sửa: nội dung là bản sửa, edit = true (tin mới không có trường này), current = nội dung đang hiển thị để so sánh,
 * updatedAt = updatedAt của bản sửa (gửi lại khi ra quyết định).
 */
export async function listPending() {
  const [listings, edits] = await Promise.all([listingRepository.findPending(), listingRepository.findPendingRevisions()]);
  return [
    ...listings.map(toOwnerListingDto),
    ...edits.map(({ revision, ...listing }) => {
      const current = toOwnerListingDto(listing);
      const { status: _status, submittedAt, updatedAt, reviewReason: _reason, ...content } = toRevisionDto(revision!);
      return { ...current, ...content, updatedAt, submittedAt, edit: true,
        current: { title: current.title, description: current.description, price: current.price, originalPrice: current.originalPrice,
          isNegotiable: current.isNegotiable, condition: current.condition, allowSale: current.allowSale,
          allowExchange: current.allowExchange, exchangeWish: current.exchangeWish, attributes: current.attributes,
          location: current.location, images: current.images } };
    }),
  ];
}

/* ---------- /admin/listings ---------- */

/**
 * Mọi tin, lọc trạng thái / tiêu đề, 25 tin mỗi trang. Tin đã duyệt có bản sửa thì thêm
 * pendingEdit { status, title, price, ..., updatedAt } (ra quyết định trên bản sửa thì gửi updatedAt của bản sửa).
 */
export async function listForAdmin({ status, q, page }: AdminListingQuery) {
  const [rows, total] = await listingRepository.findAdminPage({ status, q }, (page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  const items = rows.map(({ revision, ...item }) => ({ ...item, ...(revision && { pendingEdit: toRevisionDto(revision) }) }));
  return { items, total, page };
}

/** Quyết định của admin trên một tin bất kỳ */
export async function adminDecide(actorId: string, id: string, { action, reason, expectedUpdatedAt }: AdminDecisionInput) {
  const removed = await withQuotaTransaction((tx) => moderate(tx, actorId, id, action, reason, expectedUpdatedAt));
  await removeStoredImages(removed);
  return { updated: true };
}

/** Tin cho trang quản trị (null nếu không có) */
export const getAdminListing = (id: string) => listingRepository.findAdminListing(id);
