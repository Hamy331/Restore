import { Prisma } from '@prisma/client';
import { AppError } from '../../../common/errors/app-error.js';
import { prisma } from '../../../lib/prisma.js';

export async function createUserReview(reviewerId: string, listingId: string, input: { rating: number; comment: string | null }) {
  try {
    return await prisma.$transaction(async (tx) => {
      const deal = await tx.listingDeal.findUnique({ where: { listingId } });
      if (!deal) throw new AppError(409, 'DEAL_NOT_RECORDED', 'Tin chưa ghi nhận người giao dịch cho giao dịch này.');
      const targetId = reviewerId === deal.sellerId ? deal.counterpartyId
        : reviewerId === deal.counterpartyId ? deal.sellerId : null;
      if (!targetId) throw new AppError(403, 'REVIEW_NOT_ALLOWED', 'Chỉ hai bên trong giao dịch được đánh giá nhau.');

      const review = await tx.userReview.create({
        data: { listingId, reviewerId, targetId, ...input },
        select: { id: true, listingId: true, reviewerId: true, targetId: true, rating: true, comment: true, createdAt: true },
      });
      const aggregate = await tx.userReview.aggregate({ where: { targetId }, _avg: { rating: true }, _count: true });
      await tx.user.update({ where: { id: targetId }, data: {
        ratingAverage: aggregate._avg.rating ?? 0,
        ratingCount: aggregate._count,
      } });
      return review;
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      throw new AppError(409, 'REVIEW_ALREADY_EXISTS', 'Bạn đã đánh giá giao dịch này rồi.');
    }
    throw error;
  }
}

export async function listListingReviews(listingId: string) {
  const deal = await prisma.listingDeal.findUnique({ where: { listingId }, select: { listingId: true } });
  if (!deal) throw new AppError(404, 'DEAL_NOT_FOUND', 'Không tìm thấy giao dịch đã hoàn tất.');
  const [items, totalItems] = await prisma.$transaction([
    prisma.userReview.findMany({
      where: { listingId }, orderBy: { createdAt: 'desc' }, take: 50,
      select: { id: true, rating: true, comment: true, createdAt: true,
        reviewer: { select: { id: true, fullName: true, avatarUrl: true } } },
    }),
    prisma.userReview.count({ where: { listingId } }),
  ]);
  return { items, totalItems };
}
