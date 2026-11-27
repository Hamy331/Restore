BEGIN;
-- Liên hệ công khai của shop (mục Thông tin doanh nghiệp ở Sửa hồ sơ)
ALTER TABLE "Shop" ADD COLUMN "contactPhone" TEXT;
ALTER TABLE "Shop" ADD COLUMN "businessEmail" TEXT;
ALTER TABLE "Shop" ADD COLUMN "website" TEXT;
COMMIT;
