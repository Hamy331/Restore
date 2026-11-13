-- Hạn mức đăng tin theo chuyên mục (tài khoản Cá nhân) và giữ xu khi đăng tin vượt hạn mức

-- AlterTable
ALTER TABLE "Category" ADD COLUMN "freeListingLimit" INTEGER NOT NULL DEFAULT 2,
ADD COLUMN "extraListingCredits" INTEGER NOT NULL DEFAULT 5;

-- Bảng hạn mức (tài liệu "Hạn mức đăng tin và hệ thống credit", mục 2 và 6)
UPDATE "Category" SET "freeListingLimit" = 1, "extraListingCredits" = 15 WHERE "id" IN ('phones', 'vehicles', 'electronics');
UPDATE "Category" SET "freeListingLimit" = 1, "extraListingCredits" = 10 WHERE "id" IN ('appliances', 'pets');
UPDATE "Category" SET "freeListingLimit" = 2, "extraListingCredits" = 10 WHERE "id" = 'furniture';
UPDATE "Category" SET "freeListingLimit" = 2, "extraListingCredits" = 5 WHERE "id" IN ('fashion', 'sports', 'other');
UPDATE "Category" SET "freeListingLimit" = 3, "extraListingCredits" = 5 WHERE "id" = 'books';

-- Tài khoản Cá nhân: tối đa 5 tin miễn phí trên toàn tài khoản
UPDATE "StorePackage" SET "activeListingLimit" = 5 WHERE "tier" = 'PERSONAL';

-- AlterTable
ALTER TABLE "Listing" ADD COLUMN "paidCredits" INTEGER NOT NULL DEFAULT 0;

-- CreateIndex
CREATE INDEX "Listing_ownerId_categoryId_status_idx" ON "Listing"("ownerId", "categoryId", "status");

-- CreateEnum
CREATE TYPE "CreditHoldStatus" AS ENUM ('HELD', 'CAPTURED', 'RELEASED');

-- CreateTable
CREATE TABLE "CreditHold" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "listingId" TEXT,
    "amount" INTEGER NOT NULL,
    "bonusAmount" INTEGER NOT NULL,
    "paidAmount" INTEGER NOT NULL,
    "status" "CreditHoldStatus" NOT NULL DEFAULT 'HELD',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CreditHold_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "CreditHold_userId_status_idx" ON "CreditHold"("userId", "status");
CREATE INDEX "CreditHold_listingId_status_idx" ON "CreditHold"("listingId", "status");

-- AddForeignKey
ALTER TABLE "CreditHold" ADD CONSTRAINT "CreditHold_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CreditHold" ADD CONSTRAINT "CreditHold_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AlterTable
ALTER TABLE "CreditTransaction" ADD COLUMN "holdId" TEXT;

-- AddForeignKey
ALTER TABLE "CreditTransaction" ADD CONSTRAINT "CreditTransaction_holdId_fkey" FOREIGN KEY ("holdId") REFERENCES "CreditHold"("id") ON DELETE SET NULL ON UPDATE CASCADE;
