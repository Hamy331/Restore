-- Poster shop: shop gói Cửa hàng tự gửi poster, admin duyệt; hạn mức theo gói
ALTER TYPE "ShopBannerStatus" ADD VALUE 'STOPPED';

CREATE TYPE "ShopBannerRejectReason" AS ENUM ('WRONG_SIZE', 'MISLEADING_PRICE', 'BRAND_MISUSE', 'PROHIBITED', 'TOO_MUCH_TEXT', 'OTHER');

ALTER TABLE "ShopBanner"
ADD COLUMN "listingId" TEXT,
ADD COLUMN "rejectReason" "ShopBannerRejectReason",
ADD COLUMN "rejectNote" TEXT,
ADD COLUMN "reviewedAt" TIMESTAMP(3),
ADD COLUMN "reviewedById" TEXT,
ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

CREATE INDEX "ShopBanner_status_createdAt_idx" ON "ShopBanner"("status", "createdAt");
ALTER TABLE "ShopBanner" ADD CONSTRAINT "ShopBanner_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "StorePackage"
ADD COLUMN "posterActiveLimit" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "posterMonthlyLimit" INTEGER NOT NULL DEFAULT 0;

-- Gói Cửa hàng: 2 poster cùng lúc, gửi tối đa 4 poster mỗi tháng
UPDATE "StorePackage" SET "posterActiveLimit" = 2, "posterMonthlyLimit" = 4 WHERE "tier" = 'PRO';
