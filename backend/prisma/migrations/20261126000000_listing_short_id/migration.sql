BEGIN;
-- Mã số ngắn tự tăng cho URL đẹp; SERIAL tự gán số cho các tin hiện có
ALTER TABLE "Listing" ADD COLUMN "shortId" SERIAL NOT NULL;
CREATE UNIQUE INDEX "Listing_shortId_key" ON "Listing"("shortId");
COMMIT;
