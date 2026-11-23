import { audit } from '../../../common/audit/admin-audit.js';
import { AppError } from '../../../common/errors/app-error.js';
import { prisma } from '../../../lib/prisma.js';
import { setExtraTerms, type ExtraTermCode } from '../content-flags.js';

const select = { id: true, term: true, code: true, createdAt: true } as const;

/** Từ admin thêm vào bộ lọc nội dung, mới trước */
export const listBannedTerms = () => prisma.bannedTerm.findMany({ select, orderBy: { createdAt: 'desc' } });

/** Nạp lại từ vào bộ lọc của tiến trình này */
export async function refreshBannedTerms() {
  setExtraTerms((await prisma.bannedTerm.findMany({ select })) as { term: string; code: ExtraTermCode }[]);
}

/**
 * Nạp ngay khi khởi động rồi mỗi phút, để mọi máy chủ thấy từ admin vừa sửa trên máy khác.
 * ponytail: máy khác trễ tối đa 1 phút; cần tức thì thì phát sự kiện qua Redis / LISTEN.
 */
export function startBannedTermsJob(intervalMs = 60_000) {
  const run = () => refreshBannedTerms().catch((error) => console.error('[jobs] refreshBannedTerms failed', error));
  void run();
  const timer = setInterval(run, intervalMs);
  timer.unref();
  return timer;
}

/** Thêm từ (chữ thường, gộp khoảng trắng); trùng thì 409 TERM_EXISTS */
export async function addBannedTerm(actorId: string, input: { term: string; code: ExtraTermCode }) {
  const term = input.term.normalize('NFC').trim().replace(/\s+/g, ' ').toLowerCase();
  if (await prisma.bannedTerm.findUnique({ where: { term } })) {
    throw new AppError(409, 'TERM_EXISTS', 'Từ này đã có trong bộ lọc.', 'term');
  }
  const created = await prisma.$transaction(async (tx) => {
    const row = await tx.bannedTerm.create({ data: { term, code: input.code }, select });
    await audit(tx, actorId, 'TERM_ADD', 'BANNED_TERM', row.id, `Thêm "${term}" vào bộ lọc`, null, { term, code: input.code });
    return row;
  });
  await refreshBannedTerms();
  return created;
}

/** Bỏ từ khỏi bộ lọc; không có thì 404 TERM_NOT_FOUND */
export async function removeBannedTerm(actorId: string, id: string) {
  await prisma.$transaction(async (tx) => {
    const row = await tx.bannedTerm.findUnique({ where: { id }, select });
    if (!row) throw new AppError(404, 'TERM_NOT_FOUND', 'Không tìm thấy từ này.');
    await tx.bannedTerm.delete({ where: { id } });
    await audit(tx, actorId, 'TERM_REMOVE', 'BANNED_TERM', id, `Bỏ "${row.term}" khỏi bộ lọc`, { term: row.term, code: row.code }, null);
  });
  await refreshBannedTerms();
}
