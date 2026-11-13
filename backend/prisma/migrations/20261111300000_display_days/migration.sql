-- Chọn thời gian hiển thị và gia hạn tuỳ số ngày: mỗi chuyên mục có số ngày miễn phí, thời gian tối đa
-- và giá 30 ngày thêm; mua theo mốc 30 / 60 / 90 ngày rẻ hơn; gói cao được thêm ngày, giảm giá, tự gia hạn

-- AlterTable
ALTER TABLE "Category" ADD COLUMN "maxDisplayDays" INTEGER NOT NULL DEFAULT 120,
ADD COLUMN "dayPackCredits" INTEGER NOT NULL DEFAULT 4;

-- Ngày miễn phí / tối đa / giá 30 ngày theo từng chuyên mục
UPDATE "Category" AS c SET "displayDays" = v.free, "maxDisplayDays" = v.max, "dayPackCredits" = v.price
FROM (VALUES
  ('phones', 30, 120, 15),
  ('vehicles', 30, 180, 15),
  ('electronics', 45, 120, 12),
  ('appliances', 45, 180, 8),
  ('pets', 21, 60, 8),
  ('furniture', 60, 180, 6),
  ('fashion', 30, 90, 4),
  ('sports', 45, 120, 4),
  ('books', 60, 180, 3),
  ('other', 45, 120, 4)
) AS v(id, free, max, price)
WHERE c."id" = v.id;

-- AlterTable
ALTER TABLE "StorePackage" ADD COLUMN "freeDaysPercent" INTEGER NOT NULL DEFAULT 100,
ADD COLUMN "extendDiscountPercent" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "autoExtend" BOOLEAN NOT NULL DEFAULT false;

-- Bán chuyên: gấp rưỡi ngày miễn phí, giảm 20%; Cửa hàng: gấp đôi, giảm 30%, tự gia hạn
UPDATE "StorePackage" SET "freeDaysPercent" = 150, "extendDiscountPercent" = 20 WHERE "tier" = 'BASIC';
UPDATE "StorePackage" SET "freeDaysPercent" = 200, "extendDiscountPercent" = 30, "autoExtend" = true WHERE "tier" = 'PRO';

-- AlterTable
ALTER TABLE "Listing" ADD COLUMN "startsAt" TIMESTAMP(3),
ADD COLUMN "displayDays" INTEGER,
ADD COLUMN "paidDays" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN "autoExtend" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX "Listing_status_startsAt_idx" ON "Listing"("status", "startsAt");

-- CreateTable
CREATE TABLE "DisplayDayPack" (
    "days" INTEGER NOT NULL,
    "discountPercent" INTEGER NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "DisplayDayPack_pkey" PRIMARY KEY ("days")
);

INSERT INTO "DisplayDayPack" ("days", "discountPercent") VALUES (30, 10), (60, 20), (90, 30)
ON CONFLICT ("days") DO NOTHING;
