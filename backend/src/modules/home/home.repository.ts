import { Prisma } from '@prisma/client';
import { prisma } from '../../lib/prisma.js';

/** Banner đang hiển thị: active và nằm trong khung startsAt/endsAt (nếu có). */
export const findVisibleBanners = (now: Date) =>
  prisma.homeBanner.findMany({
    where: {
      active: true,
      AND: [
        { OR: [{ startsAt: null }, { startsAt: { lte: now } }] },
        { OR: [{ endsAt: null }, { endsAt: { gt: now } }] },
      ],
    },
    orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }],
  });

export const findAllBanners = () =>
  prisma.homeBanner.findMany({ orderBy: [{ sortOrder: 'asc' }, { createdAt: 'desc' }] });

export const findBannerById = (id: string) => prisma.homeBanner.findUnique({ where: { id } });

/** Ghi thay đổi banner kèm một dòng AdminAudit trong cùng transaction. */
export const saveBannerWithAudit = (
  write: (tx: Prisma.TransactionClient) => Promise<Prisma.HomeBannerGetPayload<{}>>,
  audit: (banner: Prisma.HomeBannerGetPayload<{}>) => Prisma.AdminAuditUncheckedCreateInput,
) =>
  prisma.$transaction(async (tx) => {
    const banner = await write(tx);
    await tx.adminAudit.create({ data: audit(banner) });
    return banner;
  });
