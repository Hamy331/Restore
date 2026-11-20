import { AppError } from '../../../common/errors/app-error.js';
import type { ReportInput } from '../content.dto.js';

type ConfiguredReason = { code: string; labelVi: string; active: boolean; requiresDescription: boolean };

/** Rules come from the current database row, never a client-provided label or a code allowlist. */
export function applyReportReason(input: ReportInput, reason?: ConfiguredReason | null) {
  if (input.reasonCode === undefined) return { ...input, reason: input.reason! };
  if (!reason || !reason.active || reason.code !== input.reasonCode) {
    throw new AppError(409, 'REPORT_REASON_UNAVAILABLE', 'Lý do báo cáo đã thay đổi. Vui lòng chọn lại.', 'reasonCode');
  }
  return { ...input, reason: reason.labelVi };
}
