import { AppError } from '../../../common/errors/app-error.js';
import { withQuotaTransaction } from '../../commerce/index.js';
import type { PageQuery, ReportInput } from '../content.dto.js';
import { PAGE_SIZE } from '../content.type.js';
import * as reportRepository from '../repositories/report.repository.js';

/** Báo cáo tin đang hiển thị hoặc thành viên; không tự báo cáo mình, mỗi đối tượng một báo cáo đang mở */
export function create(reporterId: string, { targetType, targetId, reason, evidence }: ReportInput) {
  return withQuotaTransaction(async (tx) => {
    const target = targetType === 'USER'
      ? await reportRepository.findUserMember(tx, targetId)
      : await reportRepository.findAvailableListing(tx, targetId);
    if (!target) throw new AppError(404, 'TARGET_NOT_FOUND', 'Đối tượng không tồn tại.');
    if (targetId === reporterId || (targetType === 'LISTING' && (target as { ownerId?: string }).ownerId === reporterId)) {
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
