BEGIN;
ALTER TABLE "User" RENAME COLUMN "ratingCount" TO "legacyRatingCount";
ALTER TABLE "User" RENAME COLUMN "ratingAverage" TO "legacyRatingAverage";
ALTER TABLE "User" ADD COLUMN "ratingCount" INTEGER NOT NULL DEFAULT 0,
                   ADD COLUMN "ratingAverage" DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE "Conversation" ADD COLUMN "listingId" TEXT REFERENCES "Listing"(id) ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX "Conversation_listingId_idx" ON "Conversation"("listingId");
CREATE TABLE "ListingTrade" (
  "conversationId" TEXT PRIMARY KEY REFERENCES "Conversation"(id) ON DELETE CASCADE ON UPDATE CASCADE,
  "listingId" TEXT NOT NULL UNIQUE, "sellerId" TEXT NOT NULL, "buyerId" TEXT NOT NULL,
  "title" TEXT NOT NULL, "price" DECIMAL(65,30) NOT NULL, "image" TEXT,
  "confirmedAt" TIMESTAMP(3), CHECK ("sellerId" <> "buyerId")
);
CREATE TABLE "TradeReview" (
  "id" TEXT PRIMARY KEY, "conversationId" TEXT NOT NULL REFERENCES "ListingTrade"("conversationId") ON DELETE CASCADE ON UPDATE CASCADE,
  "authorId" TEXT NOT NULL REFERENCES "User"(id) ON DELETE CASCADE ON UPDATE CASCADE,
  "recipientId" TEXT NOT NULL REFERENCES "User"(id) ON DELETE CASCADE ON UPDATE CASCADE,
  "fromSeller" BOOLEAN NOT NULL, "stars" INTEGER NOT NULL CHECK ("stars" BETWEEN 1 AND 5),
  "comment" VARCHAR(500) NOT NULL DEFAULT '', "tags" TEXT[] NOT NULL DEFAULT '{}',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK ("authorId" <> "recipientId"), UNIQUE ("conversationId","authorId")
);
CREATE INDEX "TradeReview_recipientId_createdAt_idx" ON "TradeReview"("recipientId","createdAt");
CREATE FUNCTION refresh_trade_rating() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE recipient TEXT;
BEGIN
  IF TG_OP = 'DELETE' THEN recipient := OLD."recipientId"; ELSE recipient := NEW."recipientId"; END IF;
  PERFORM id FROM "User" WHERE id = recipient FOR NO KEY UPDATE;
  UPDATE "User" SET ("ratingCount","ratingAverage") =
    (SELECT count(*)::int, coalesce(avg(stars),0) FROM "TradeReview" WHERE "recipientId" = recipient)
    WHERE id = recipient;
  RETURN NULL;
END $$;
CREATE TRIGGER trade_rating_change AFTER INSERT OR DELETE ON "TradeReview"
FOR EACH ROW EXECUTE FUNCTION refresh_trade_rating();
COMMIT;
