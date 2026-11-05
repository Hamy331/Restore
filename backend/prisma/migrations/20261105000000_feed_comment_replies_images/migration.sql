ALTER TABLE "FeedComment" ADD COLUMN "imageUrl" TEXT, ADD COLUMN "parentId" TEXT;
CREATE INDEX "FeedComment_parentId_createdAt_id_idx" ON "FeedComment"("parentId", "createdAt", "id");
ALTER TABLE "FeedComment" ADD CONSTRAINT "FeedComment_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "FeedComment"("id") ON DELETE CASCADE ON UPDATE CASCADE;
