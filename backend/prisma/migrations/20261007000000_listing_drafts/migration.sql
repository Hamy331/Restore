ALTER TYPE "ListingStatus" ADD VALUE 'DRAFT';

ALTER TABLE "Listing" ADD COLUMN "publishedAt" TIMESTAMP(3);
UPDATE "Listing" SET "publishedAt" = "createdAt";
CREATE INDEX "Listing_ownerId_publishedAt_idx" ON "Listing"("ownerId", "publishedAt");
