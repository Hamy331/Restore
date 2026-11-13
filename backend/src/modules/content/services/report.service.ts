import { AppError } from '../../../common/errors/app-error.js';
import { audit } from '../../../common/audit/admin-audit.js';
import { ADMIN_PAGE_SIZE, changed, integer, version } from '../../../common/validation/admin-input.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import { getAdminListing, moderate } from '../../listings/index.js';
import { getAdminUser, sanctionUser } from '../../users/index.js';
import {
  findReportableFeedPost,
  getAdminReportTarget,
  removeFeedPostForAdmin,
} from '../../feeds/index.js';
import type { AdminReportQuery, PageQuery, ReportInput, ResolveReportInput } from '../content.dto.js';
import {
  FEED_POST_REPORT_ACTIONS,
  LISTING_REPORT_ACTIONS,
  PAGE_SIZE,
  USER_REPORT_ACTIONS,
} from '../content.type.js';
import * as reportRepository from '../repositories/report.repository.js';

/** Báo cáo tin đang hiển thị hoặc thành viên; không tự báo cáo mình, mỗi đối tượng một báo cáo đang mở */
export function create(reporterId: string, { targetType, targetId, reason, evidence }: ReportInput) {
  return withQuotaTransaction(async (tx) => {
    const target = targetType === 'USER'
      ? await reportRepository.findUserMember(tx, targetId)
      : targetType === 'LISTING'
        ? await reportRepository.findAvailableListing(tx, targetId)
        : await findReportableFeedPost(tx, targetId);
    if (!target) throw new AppError(404, 'TARGET_NOT_FOUND', 'Đối tượng không tồn tại.');
    if (
      (targetType === 'USER' && targetId === reporterId) ||
      (targetType === 'LISTING' && (target as { ownerId?: string }).ownerId === reporterId) ||
      (targetType === 'FEED_POST' && (target as { authorId?: string }).authorId === reporterId)
    ) {
      throw new AppError(400, 'INVALID_REPORT', 'Không tự báo cáo mình.');
    }
    if (await reportRepository.findOpenReport(tx, reporterId, targetType, targetId)) {
      throw new AppError(409, 'REPORT_EXISTS', 'Bạn đã có báo cáo đang chờ xử lý.');
    }
    return reportRepository.createReport(tx, { reporterId, targetType, targetId, reason, evidence });
  });
}

export const listMine = (reporterId: string, { page }: PageQuery) =>
  reportRepository.findMine(reporterId, (page - 1) * PAGE_SIZE, PAGE_SIZE);

/* ---------- Quản trị (/admin/reports) ---------- */

/** Báo cáo, mới trước, 25 mỗi trang */
export async function listForAdmin({ page, status }: AdminReportQuery) {
  const [items, total] = await reportRepository.findPage(status, (page - 1) * ADMIN_PAGE_SIZE, ADMIN_PAGE_SIZE);
  return { items, total, page };
}

/**
 * Xử lý báo cáo đang mở (updatedAt phải khớp), ghi AdminAudit.
 * REMOVE gỡ tin hoặc bài viết bảng tin; WARN / SUSPEND (days, mặc định 7) / BAN xử lý thành viên.
 * Mọi quyết định thay đổi đối tượng đều cần targetUpdatedAt.
 */
export function resolve(actorId: string, id: string, { action, reason, expected, days, targetUpdatedAt }: ResolveReportInput) {
  return withQuotaTransaction(async (tx) => {
    const report = await reportRepository.findByIdOrThrow(id, tx);
    if (report.status !== 'OPEN') throw new AppError(409, 'REPORT_CLOSED', 'Báo cáo đã được xử lý.');
    const allowed = report.targetType === 'LISTING'
      ? LISTING_REPORT_ACTIONS
      : report.targetType === 'USER'
        ? USER_REPORT_ACTIONS
        : report.targetType === 'FEED_POST'
          ? FEED_POST_REPORT_ACTIONS
          : null;
    if (!allowed || !allowed.includes(action)) {
      throw new AppError(400, 'INVALID_DECISION', 'Hành động không phù hợp đối tượng.');
    }
    if (action === 'REMOVE' && report.targetType === 'LISTING') {
      await moderate(tx, actorId, report.targetId, 'REMOVE', reason, version(targetUpdatedAt));
    }
    if (action === 'REMOVE' && report.targetType === 'FEED_POST') {
      await removeFeedPostForAdmin(tx, actorId, report.targetId, reason, version(targetUpdatedAt));
    }
    if (action === 'WARN' || action === 'SUSPEND' || action === 'BAN') {
      await sanctionUser(tx, actorId, report.targetId, action, reason, integer(days ?? 7, 1, 365), version(targetUpdatedAt));
    }
    changed(await reportRepository.closeWhereVersion(tx, report.id, expected,
      { status: action === 'DISMISS' ? 'DISMISSED' : 'RESOLVED', decision: action, resolution: reason }));
    await audit(tx, actorId, action, 'REPORT', report.id, reason);
    return { updated: true };
  });
}

/** Đối tượng bị báo cáo: hồ sơ thành viên hoặc tin (null nếu đã mất) */
export async function getTarget(id: string) {
  const report = await reportRepository.findByIdOrThrow(id);
  if (report.targetType === 'USER') return getAdminUser(report.targetId);
  if (report.targetType === 'LISTING') return getAdminListing(report.targetId);
  if (report.targetType === 'FEED_POST') return getAdminReportTarget(report.targetId);
  return null;
}
