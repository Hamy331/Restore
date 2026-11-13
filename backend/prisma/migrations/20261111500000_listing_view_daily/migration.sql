-- Lượt xem tin theo ngày (giờ Việt Nam) cho trang Thống kê của người bán

CREATE TABLE "ListingViewDaily" (
    "listingId" TEXT NOT NULL,
    "day" DATE NOT NULL,
    "views" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "ListingViewDaily_pkey" PRIMARY KEY ("listingId", "day")
);
CREATE INDEX "ListingViewDaily_day_idx" ON "ListingViewDaily"("day");
ALTER TABLE "ListingViewDaily" ADD CONSTRAINT "ListingViewDaily_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;
