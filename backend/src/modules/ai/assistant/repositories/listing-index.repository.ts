import { Prisma } from '@prisma/client';
import { prisma } from '../../../../lib/prisma.js';
import { AppError } from '../../../../common/errors/app-error.js';
import { withQuotaTransaction } from '../../../commerce/index.js';
import { listingSelect } from '../../../listings/listing.dto.js';
import { visible } from '../../../listings/repositories/listing.repository.js';
import { listingHash } from '../services/listing-source.service.js';
import { SEARCH_LIMITS } from '../../ai.config.js';

export type ListingSearchInput = { q: string; minPrice?: string; maxPrice?: string; categoryId?: string; brand?: string };
const filters = (input: ListingSearchInput): Prisma.ListingWhereInput => ({
  ...visible,
  shopOnly: false,
  price: { ...(input.minPrice ? { gte: new Prisma.Decimal(input.minPrice) } : {}), ...(input.maxPrice ? { lte: new Prisma.Decimal(input.maxPrice) } : {}) },
  ...(input.categoryId ? { categoryId: input.categoryId } : {}),
});
export const findPublicListing = (id: string) => prisma.listing.findFirst({ where: { id, ...visible }, select: listingSelect });
export const browse = (input: ListingSearchInput) => prisma.listing.findMany({ where: filters(input), select: listingSelect, orderBy: [{ publishedAt: 'desc' }, { id: 'asc' }], take: SEARCH_LIMITS.candidates });
export const findCurrentCandidates = (pointIds: string[], model: string, collection: string, input: ListingSearchInput) =>
  prisma.aiListingIndex.findMany({ where: { pointId: { in: pointIds }, model, collection, listing: filters(input) }, include: { listing: { select: listingSelect } } });

export const retireHidden = () => prisma.aiListingIndex.deleteMany({ where: {
  OR: [{ listing: { status: { not: 'AVAILABLE' } } }, { listing: { shopOnly: true } }, { listing: { owner: { status: { not: 'ACTIVE' } } } }],
} });
export const pendingListings = (model: string, collection: string, limit: number) => prisma.$queryRaw<{ id: string }[]>`
  SELECT l.id FROM "Listing" l JOIN "User" u ON u.id=l."ownerId"
  LEFT JOIN "AiListingIndex" i ON i."listingId"=l.id
  WHERE l.status='AVAILABLE' AND u.status='ACTIVE' AND l."shopOnly"=false
    AND (i."listingId" IS NULL OR i.model <> ${model} OR i.collection <> ${collection})
  ORDER BY l.id LIMIT ${limit}`;

export async function publishIndex(listingId: string, pointId: string, sourceHash: string, model: string, collection: string) {
  await withQuotaTransaction(async (tx) => {
    const current = await tx.listing.findFirst({ where: { id: listingId, ...visible, shopOnly: false }, select: listingSelect });
    if (!current || listingHash(current) !== sourceHash) throw new AppError(409, 'LISTING_CHANGED', 'Tin đã thay đổi trong lúc lập chỉ mục.');
    const data = { pointId, sourceHash, model, collection, indexedAt: new Date() };
    await tx.aiListingIndex.upsert({ where: { listingId }, create: { listingId, ...data }, update: data });
  });
}

export async function queueUnpublishedPoint(pointId: string, collection: string) {
  // A commit acknowledgement may be lost. Never delete a published point.
  if (!await prisma.aiListingIndex.findUnique({ where: { pointId } })) {
    await prisma.aiVectorDeletion.upsert({ where: { pointId_collection: { pointId, collection } }, create: { pointId, collection }, update: {} });
  }
}
