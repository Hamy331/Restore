-- AlterTable
ALTER TABLE "Shop" ADD COLUMN "openingHours" JSONB;

-- CreateTable
CREATE TABLE "ShopVerification" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "status" "ShopStatus" NOT NULL DEFAULT 'PENDING',
    "businessName" TEXT NOT NULL,
    "taxCode" TEXT NOT NULL,
    "documentUrls" TEXT[],
    "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reviewedAt" TIMESTAMP(3),
    "reviewedById" TEXT,
    "rejectNote" TEXT,

    CONSTRAINT "ShopVerification_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ShopVerification_shopId_key" ON "ShopVerification"("shopId");

-- CreateIndex
CREATE INDEX "ShopVerification_status_submittedAt_idx" ON "ShopVerification"("status", "submittedAt");

-- AddForeignKey
ALTER TABLE "ShopVerification" ADD CONSTRAINT "ShopVerification_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;
