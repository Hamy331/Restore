BEGIN;
ALTER TABLE "Listing" DROP COLUMN "originalPrice";
ALTER TABLE "ListingRevision" DROP COLUMN "originalPrice";
COMMIT;
