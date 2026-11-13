-- Thời gian hiển thị tin theo chuyên mục, tin quá hạn tự ẩn, gia hạn / kích hoạt lại bằng xu

-- AlterTable
ALTER TABLE "Category" ADD COLUMN "displayDays" INTEGER NOT NULL DEFAULT 60;

-- Điện thoại, xe cộ: 30 ngày; còn lại 60 ngày
UPDATE "Category" SET "displayDays" = 30 WHERE "id" IN ('phones', 'vehicles');

-- AlterTable
ALTER TABLE "Listing" ADD COLUMN "expiresAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "Listing_status_expiresAt_idx" ON "Listing"("status", "expiresAt");

-- Tin đang hiển thị / đã ẩn có sẵn: tính hạn từ hôm nay để không bị ẩn ngay khi chạy migration
UPDATE "Listing" AS l SET "expiresAt" = NOW() + make_interval(days => c."displayDays")
FROM "Category" AS c
WHERE l."categoryId" = c."id" AND l."status" IN ('AVAILABLE', 'HIDDEN');
UPDATE "Listing" SET "expiresAt" = NOW() + INTERVAL '60 days'
WHERE "expiresAt" IS NULL AND "status" IN ('AVAILABLE', 'HIDDEN');
