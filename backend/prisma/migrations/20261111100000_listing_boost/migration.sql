-- Đẩy tin bằng xu: giá theo chuyên mục, giảm giá và lượt tặng theo gói

-- AlterTable
ALTER TABLE "Category" ADD COLUMN "boostCredits" INTEGER NOT NULL DEFAULT 5;

-- Nhóm A 10 xu, nhóm B 6 xu, nhóm C 4 xu
UPDATE "Category" SET "boostCredits" = 10 WHERE "id" IN ('phones', 'vehicles', 'electronics');
UPDATE "Category" SET "boostCredits" = 6 WHERE "id" IN ('appliances', 'pets', 'furniture');
UPDATE "Category" SET "boostCredits" = 4 WHERE "id" IN ('fashion', 'sports', 'other', 'books');

-- AlterTable
ALTER TABLE "StorePackage" ADD COLUMN "boostDiscountPercent" INTEGER NOT NULL DEFAULT 0;

-- Bán chuyên: 5 lượt tặng / tháng, giảm 20%; Cửa hàng: 20 lượt, giảm 30%
UPDATE "StorePackage" SET "monthlyPromotionQuota" = 5, "boostDiscountPercent" = 20 WHERE "tier" = 'BASIC';
UPDATE "StorePackage" SET "monthlyPromotionQuota" = 20, "boostDiscountPercent" = 30 WHERE "tier" = 'PRO';
