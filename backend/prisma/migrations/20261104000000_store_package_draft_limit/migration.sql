-- Giới hạn số tin nháp giữ cùng lúc theo gói: Cá nhân 3, Cửa hàng Basic 10, Cửa hàng Pro 30

-- AlterTable
ALTER TABLE "StorePackage" ADD COLUMN "draftLimit" INTEGER NOT NULL DEFAULT 3;

UPDATE "StorePackage" SET "draftLimit" = 10 WHERE "tier" = 'BASIC';
UPDATE "StorePackage" SET "draftLimit" = 30 WHERE "tier" = 'PRO';
