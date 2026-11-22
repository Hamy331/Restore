-- Danh mục con: id nằm trong Category.metadata.subcategories của danh mục cha.
-- Chỉ thêm cột (nullable) và index, dữ liệu cũ được gán bằng scripts/migrate-categories.ts
ALTER TABLE "Listing" ADD COLUMN "subcategoryId" TEXT;

CREATE INDEX "Listing_categoryId_subcategoryId_status_idx" ON "Listing"("categoryId", "subcategoryId", "status");
