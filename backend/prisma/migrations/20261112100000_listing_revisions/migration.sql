-- Bản sửa của tin đã duyệt, chờ duyệt lại (tin vẫn hiện bản cũ tới khi duyệt)
CREATE TYPE "ListingRevisionStatus" AS ENUM ('PENDING', 'REJECTED');

CREATE TABLE "ListingRevision" (
    "listingId" TEXT NOT NULL,
    "status" "ListingRevisionStatus" NOT NULL DEFAULT 'PENDING',
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "price" DECIMAL(65,30) NOT NULL,
    "originalPrice" DECIMAL(65,30),
    "isNegotiable" BOOLEAN NOT NULL,
    "condition" "ListingCondition",
    "allowSale" BOOLEAN NOT NULL,
    "allowExchange" BOOLEAN NOT NULL,
    "exchangeWish" TEXT NOT NULL,
    "attributes" JSONB NOT NULL DEFAULT '{}',
    "location" JSONB,
    "images" TEXT[],
    "reviewReason" TEXT,
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ListingRevision_pkey" PRIMARY KEY ("listingId")
);

CREATE INDEX "ListingRevision_status_submittedAt_idx" ON "ListingRevision"("status", "submittedAt");

ALTER TABLE "ListingRevision" ADD CONSTRAINT "ListingRevision_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;
