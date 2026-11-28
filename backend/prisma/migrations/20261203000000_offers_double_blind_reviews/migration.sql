BEGIN;

-- 1. Đề nghị giá (Make Offer)
CREATE TYPE "OfferStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED', 'EXPIRED');

CREATE TABLE "Offer" (
  "id" TEXT NOT NULL,
  "conversationId" TEXT NOT NULL,
  "listingId" TEXT NOT NULL,
  "buyerId" TEXT NOT NULL,
  "sellerId" TEXT NOT NULL,
  "amount" DECIMAL(65,30) NOT NULL,
  "listedPrice" DECIMAL(65,30) NOT NULL,
  "status" "OfferStatus" NOT NULL DEFAULT 'PENDING',
  "expiresAt" TIMESTAMP(3) NOT NULL,
  "respondedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "Offer_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "Offer_amount_check" CHECK ("amount" > 0),
  CONSTRAINT "Offer_parties_check" CHECK ("buyerId" <> "sellerId")
);
ALTER TABLE "Offer" ADD CONSTRAINT "Offer_conversationId_fkey" FOREIGN KEY ("conversationId")
  REFERENCES "Conversation"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Offer" ADD CONSTRAINT "Offer_listingId_fkey" FOREIGN KEY ("listingId")
  REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;
CREATE INDEX "Offer_conversationId_createdAt_idx" ON "Offer"("conversationId", "createdAt");
CREATE INDEX "Offer_listingId_status_idx" ON "Offer"("listingId", "status");
CREATE INDEX "Offer_buyerId_createdAt_idx" ON "Offer"("buyerId", "createdAt");
CREATE INDEX "Offer_status_expiresAt_idx" ON "Offer"("status", "expiresAt");
-- Mỗi hội thoại (tin + người mua) chỉ có một đề nghị đang chờ
CREATE UNIQUE INDEX "Offer_one_pending_per_conversation" ON "Offer"("conversationId") WHERE "status" = 'PENDING';

-- 2. ListingTrade thành bản ghi thỏa thuận: một tin có thể có nhiều người mua
ALTER TABLE "ListingTrade" DROP CONSTRAINT IF EXISTS "ListingTrade_listingId_key";
DROP INDEX IF EXISTS "ListingTrade_listingId_key";
ALTER TABLE "ListingTrade" RENAME COLUMN "confirmedAt" TO "acceptedAt";
ALTER TABLE "ListingTrade"
  ADD COLUMN "offerId" TEXT,
  ADD COLUMN "listedPrice" DECIMAL(65,30),
  ADD COLUMN "reviewDeadline" TIMESTAMP(3),
  ADD COLUMN "revealAt" TIMESTAMP(3),
  ADD COLUMN "closedAt" TIMESTAMP(3);

-- Giao dịch cũ: yêu cầu "người bán đã xác nhận bán" chưa được người mua nhận coi như đã chấp nhận
-- từ hôm nay. Mọi giao dịch cũ có ít nhất 30 ngày kể từ hôm nay để đánh giá.
UPDATE "ListingTrade" SET
  "acceptedAt" = coalesce("acceptedAt", CURRENT_TIMESTAMP),
  "listedPrice" = "price";
UPDATE "ListingTrade" SET
  "reviewDeadline" = greatest("acceptedAt" + interval '30 days', CURRENT_TIMESTAMP + interval '30 days');

ALTER TABLE "ListingTrade"
  ALTER COLUMN "acceptedAt" SET NOT NULL,
  ALTER COLUMN "acceptedAt" SET DEFAULT CURRENT_TIMESTAMP,
  ALTER COLUMN "reviewDeadline" SET NOT NULL;
ALTER TABLE "ListingTrade" ADD CONSTRAINT "ListingTrade_offerId_fkey" FOREIGN KEY ("offerId")
  REFERENCES "Offer"("id") ON DELETE SET NULL ON UPDATE CASCADE;
CREATE UNIQUE INDEX "ListingTrade_offerId_key" ON "ListingTrade"("offerId");
CREATE INDEX "ListingTrade_listingId_idx" ON "ListingTrade"("listingId");
CREATE INDEX "ListingTrade_sellerId_acceptedAt_idx" ON "ListingTrade"("sellerId", "acceptedAt");
CREATE INDEX "ListingTrade_buyerId_acceptedAt_idx" ON "ListingTrade"("buyerId", "acceptedAt");
CREATE INDEX "ListingTrade_closedAt_revealAt_idx" ON "ListingTrade"("closedAt", "revealAt");
CREATE INDEX "ListingTrade_closedAt_reviewDeadline_idx" ON "ListingTrade"("closedAt", "reviewDeadline");

-- 3. Đánh giá: giữ kín tới khi công khai, phản hồi, gỡ bởi admin
ALTER TABLE "TradeReview"
  ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ADD COLUMN "publishedAt" TIMESTAMP(3),
  ADD COLUMN "reply" VARCHAR(500),
  ADD COLUMN "repliedAt" TIMESTAMP(3),
  ADD COLUMN "removedAt" TIMESTAMP(3),
  ADD COLUMN "removedReason" VARCHAR(500);
CREATE INDEX "TradeReview_recipientId_publishedAt_idx" ON "TradeReview"("recipientId", "publishedAt");

-- Đánh giá cũ đã hiển thị: giữ nguyên là đã công khai
UPDATE "TradeReview" SET "publishedAt" = "createdAt", "updatedAt" = "createdAt";

-- Bộ tiêu chí mới. Người mua đánh giá người bán: communication, asDescribed, punctual, keptDeal, friendly.
-- Người bán đánh giá người mua: communication, punctual, keptDeal, paidAsAgreed, polite.
UPDATE "TradeReview" SET "tags" = ARRAY(
  SELECT DISTINCT CASE
    WHEN "fromSeller" AND tag = 'friendly' THEN 'polite'
    WHEN "fromSeller" AND tag = 'fairPrice' THEN 'paidAsAgreed'
    WHEN NOT "fromSeller" AND tag IN ('accurate', 'quality') THEN 'asDescribed'
    WHEN tag = 'reliable' THEN 'keptDeal'
    ELSE tag
  END
  FROM unnest("tags") AS tag
);

-- Giao dịch cũ đã đủ hai đánh giá: đóng lượt đánh giá
UPDATE "ListingTrade" t SET "closedAt" = r.last
FROM (SELECT "conversationId", max("createdAt") AS last, count(*) AS n FROM "TradeReview" GROUP BY "conversationId") r
WHERE r."conversationId" = t."conversationId" AND r.n >= 2;
-- Mới có một đánh giá: bên còn lại có 7 ngày kể từ hôm nay
UPDATE "ListingTrade" t SET "revealAt" = CURRENT_TIMESTAMP + interval '7 days'
FROM (SELECT "conversationId", count(*) AS n FROM "TradeReview" GROUP BY "conversationId") r
WHERE r."conversationId" = t."conversationId" AND r.n = 1;

-- 4. Điểm trung bình chỉ tính đánh giá đã công khai và chưa bị gỡ
DROP TRIGGER IF EXISTS trade_rating_change ON "TradeReview";
CREATE OR REPLACE FUNCTION refresh_trade_rating() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE recipient TEXT;
BEGIN
  IF TG_OP = 'DELETE' THEN recipient := OLD."recipientId"; ELSE recipient := NEW."recipientId"; END IF;
  PERFORM id FROM "User" WHERE id = recipient FOR NO KEY UPDATE;
  UPDATE "User" SET ("ratingCount", "ratingAverage") =
    (SELECT count(*)::int, coalesce(avg(stars), 0) FROM "TradeReview"
      WHERE "recipientId" = recipient AND "publishedAt" IS NOT NULL AND "removedAt" IS NULL)
    WHERE id = recipient;
  RETURN NULL;
END $$;
CREATE TRIGGER trade_rating_change
AFTER INSERT OR DELETE OR UPDATE OF "publishedAt", "removedAt", "stars" ON "TradeReview"
FOR EACH ROW EXECUTE FUNCTION refresh_trade_rating();

COMMIT;
