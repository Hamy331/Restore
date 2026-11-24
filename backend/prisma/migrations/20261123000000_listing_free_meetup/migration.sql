-- Đăng tin kiểu mới: cho tặng miễn phí, có nhiều món giống nhau, gặp mặt giao dịch
ALTER TABLE "Listing"
  ADD COLUMN "isFree" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "multipleUnits" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "meetUp" BOOLEAN NOT NULL DEFAULT true;

ALTER TABLE "ListingRevision"
  ADD COLUMN "isFree" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "multipleUnits" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "meetUp" BOOLEAN NOT NULL DEFAULT true;

-- isNegotiable trước đây bị bỏ qua (luôn bằng allowSale) và nay là "giá cố định":
-- đặt lại để tin cũ vẫn cho trả giá như trước
UPDATE "Listing" SET "isNegotiable" = "allowSale";
UPDATE "ListingRevision" SET "isNegotiable" = "allowSale";

-- Tab "Đồ miễn phí" trên trang chủ
CREATE INDEX "Listing_isFree_status_idx" ON "Listing"("isFree", "status");
