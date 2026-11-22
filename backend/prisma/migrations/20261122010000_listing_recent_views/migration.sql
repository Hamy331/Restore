-- CreateTable
CREATE TABLE "ListingRecentView" (
    "userId" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "viewedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ListingRecentView_pkey" PRIMARY KEY ("userId","listingId")
);

-- CreateIndex
CREATE INDEX "ListingRecentView_userId_viewedAt_idx" ON "ListingRecentView"("userId", "viewedAt");

-- AddForeignKey
ALTER TABLE "ListingRecentView" ADD CONSTRAINT "ListingRecentView_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ListingRecentView" ADD CONSTRAINT "ListingRecentView_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;
