CREATE TABLE "AiListingIndex" (
  "listingId" TEXT PRIMARY KEY,
  "pointId" TEXT NOT NULL UNIQUE,
  "sourceHash" TEXT NOT NULL,
  "model" TEXT NOT NULL,
  "collection" TEXT NOT NULL,
  "indexedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AiListingIndex_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "AiListingIndex_collection_model_idx" ON "AiListingIndex" ("collection", "model");

CREATE FUNCTION queue_ai_listing_vector() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'DELETE' OR OLD."pointId" IS DISTINCT FROM NEW."pointId" THEN
    INSERT INTO "AiVectorDeletion" ("pointId", "collection") VALUES (OLD."pointId", OLD."collection") ON CONFLICT DO NOTHING;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER "AiListingIndex_queue_deletion" AFTER DELETE OR UPDATE ON "AiListingIndex"
FOR EACH ROW EXECUTE FUNCTION queue_ai_listing_vector();

-- Views/favorites do not change the searchable text. Invalidate only relevant changes.
CREATE FUNCTION invalidate_ai_listing_index() RETURNS trigger AS $$
BEGIN
  IF ROW(OLD.title, OLD.description, OLD.price, OLD."categoryId", OLD.condition, OLD.status, OLD.attributes)
     IS DISTINCT FROM ROW(NEW.title, NEW.description, NEW.price, NEW."categoryId", NEW.condition, NEW.status, NEW.attributes) THEN
    DELETE FROM "AiListingIndex" WHERE "listingId" = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER "Listing_invalidate_ai_index" AFTER UPDATE ON "Listing"
FOR EACH ROW EXECUTE FUNCTION invalidate_ai_listing_index();
