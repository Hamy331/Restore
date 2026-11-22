-- CreateEnum
CREATE TYPE "ShopStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- AlterTable
ALTER TABLE "Shop" ADD COLUMN "status" "ShopStatus" NOT NULL DEFAULT 'PENDING',
ADD COLUMN "submittedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN "reviewedAt" TIMESTAMP(3),
ADD COLUMN "rejectNote" TEXT;

-- Shop mở trước khi có bước duyệt coi như đã duyệt
UPDATE "Shop" SET "status" = 'APPROVED', "submittedAt" = "createdAt", "reviewedAt" = "createdAt";

-- CreateIndex
CREATE INDEX "Shop_status_submittedAt_idx" ON "Shop"("status", "submittedAt");
