CREATE TABLE "ListingDeal" (
    "id" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "sellerId" TEXT NOT NULL,
    "counterpartyId" TEXT NOT NULL,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ListingDeal_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "UserReview" (
    "id" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "reviewerId" TEXT NOT NULL,
    "targetId" TEXT NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" VARCHAR(1000),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "UserReview_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "ListingDeal_listingId_key" ON "ListingDeal"("listingId");
CREATE INDEX "ListingDeal_counterpartyId_completedAt_idx" ON "ListingDeal"("counterpartyId", "completedAt");
CREATE UNIQUE INDEX "UserReview_listingId_reviewerId_key" ON "UserReview"("listingId", "reviewerId");
CREATE INDEX "UserReview_targetId_createdAt_idx" ON "UserReview"("targetId", "createdAt");
ALTER TABLE "UserReview" ADD CONSTRAINT "UserReview_rating_check" CHECK ("rating" BETWEEN 1 AND 5);

ALTER TABLE "ListingDeal" ADD CONSTRAINT "ListingDeal_listingId_fkey"
  FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ListingDeal" ADD CONSTRAINT "ListingDeal_sellerId_fkey"
  FOREIGN KEY ("sellerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ListingDeal" ADD CONSTRAINT "ListingDeal_counterpartyId_fkey"
  FOREIGN KEY ("counterpartyId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "UserReview" ADD CONSTRAINT "UserReview_reviewerId_fkey"
  FOREIGN KEY ("reviewerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UserReview" ADD CONSTRAINT "UserReview_targetId_fkey"
  FOREIGN KEY ("targetId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "UserReview" ADD CONSTRAINT "UserReview_listingId_fkey"
  FOREIGN KEY ("listingId") REFERENCES "ListingDeal"("listingId") ON DELETE CASCADE ON UPDATE CASCADE;
