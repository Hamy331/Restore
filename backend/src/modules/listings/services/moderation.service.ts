import { text as adminText, moderate } from '../../admin/admin.service.js';
import { withQuotaTransaction } from '../../stores/store.service.js';
import { DecisionInput, toOwnerListingDto } from '../listing.dto.js';
import * as listingRepository from '../repositories/listing.repository.js';

// Logic duyệt tin (moderate) còn nằm trong admin.service vì /admin/listings cũng dùng; chuyển về đây ở C19–C21.

/** Duyệt hoặc từ chối tin đang chờ; updatedAt phải khớp lúc admin mở tin */
export async function decide(actorId: string, id: string, { decision, reason, expectedUpdatedAt }: DecisionInput) {
  await withQuotaTransaction((tx) => moderate(tx, actorId, id, decision === 'APPROVED' ? 'APPROVE' : 'REJECT',
    adminText(reason, 'reason', decision === 'APPROVED' ? 0 : 5, 300), expectedUpdatedAt));
}

/** Tối đa 100 tin chờ duyệt, gửi sớm trước */
export async function listPending() {
  return (await listingRepository.findPending()).map(toOwnerListingDto);
}
