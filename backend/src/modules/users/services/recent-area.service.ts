import { AppError } from '../../../common/errors/app-error.js';
import { prisma } from '../../../lib/prisma.js';
import { findArea } from '../../catalog/index.js';

/** Mỗi người giữ tối đa 8 khu vực gần đây, chọn thêm thì bỏ khu vực lâu nhất */
export const MAX_RECENT_AREAS = 8;

/** Khu vực đã chọn gần đây, mới nhất trước, cùng dạng kết quả GET /catalog/locations/search */
export async function listRecentAreas(userId: string) {
  const rows = await prisma.recentArea.findMany({
    where: { userId }, orderBy: { usedAt: 'desc' }, take: MAX_RECENT_AREAS,
  });
  return rows.flatMap((row) => findArea(row.code) ?? []);
}

/** Body { code }: đưa khu vực lên đầu danh sách gần đây */
export async function saveRecentArea(userId: string, body: unknown) {
  const code = (body as { code?: unknown } | undefined)?.code;
  const area = typeof code === 'string' ? findArea(code) : undefined;
  if (!area) throw new AppError(400, 'INVALID_AREA', 'Khu vực không hợp lệ.', 'code');
  await prisma.$transaction(async (tx) => {
    const usedAt = new Date();
    await tx.recentArea.upsert({
      where: { userId_code: { userId, code: area.code } },
      create: { userId, code: area.code, usedAt },
      update: { usedAt },
    });
    const stale = await tx.recentArea.findMany({
      where: { userId }, orderBy: { usedAt: 'desc' }, skip: MAX_RECENT_AREAS, select: { code: true },
    });
    if (stale.length) {
      await tx.recentArea.deleteMany({ where: { userId, code: { in: stale.map((row) => row.code) } } });
    }
  });
  return area;
}

export const deleteRecentArea = (userId: string, code: string) =>
  prisma.recentArea.deleteMany({ where: { userId, code } });
