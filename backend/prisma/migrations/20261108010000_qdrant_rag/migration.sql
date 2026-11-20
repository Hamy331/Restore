-- Additive migration. Keep legacy SQL vectors until administrators have reindexed in Qdrant.
ALTER TABLE "AiKnowledgeChunk"
  ADD COLUMN "collection" TEXT NOT NULL DEFAULT '',
  ADD COLUMN "generation" TEXT NOT NULL DEFAULT '',
  ALTER COLUMN "embedding" SET DEFAULT ARRAY[]::DOUBLE PRECISION[];
CREATE INDEX "AiKnowledgeChunk_collection_model_idx" ON "AiKnowledgeChunk"("collection", "model");

CREATE TABLE "AiKnowledgeIndex" (
  "documentId" TEXT NOT NULL PRIMARY KEY,
  "status" TEXT NOT NULL DEFAULT 'IDLE',
  "lease" TEXT,
  "busyUntil" TIMESTAMP(3),
  "generation" TEXT,
  "documentVersion" TIMESTAMP(3),
  "model" TEXT,
  "collection" TEXT,
  "indexedAt" TIMESTAMP(3),
  "errorCode" TEXT,
  CONSTRAINT "AiKnowledgeIndex_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "KnowledgeDocument"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE TABLE "AiVectorDeletion" (
  "pointId" TEXT NOT NULL,
  "collection" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "AiVectorDeletion_pkey" PRIMARY KEY ("pointId", "collection")
);
CREATE INDEX "AiVectorDeletion_collection_createdAt_idx" ON "AiVectorDeletion"("collection", "createdAt");

-- Keep external deletion work even when a document is deleted via cascade/admin tools.
CREATE FUNCTION "queue_ai_vector_deletion"() RETURNS trigger AS $$
BEGIN
  IF OLD."collection" <> '' THEN
    INSERT INTO "AiVectorDeletion" ("pointId", "collection") VALUES (OLD.id, OLD."collection")
      ON CONFLICT ("pointId", "collection") DO NOTHING;
  END IF;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER "AiKnowledgeChunk_queue_vector_deletion"
AFTER DELETE ON "AiKnowledgeChunk"
FOR EACH ROW EXECUTE FUNCTION "queue_ai_vector_deletion"();
