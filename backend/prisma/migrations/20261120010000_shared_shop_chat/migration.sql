BEGIN;
ALTER TABLE "Conversation" ADD COLUMN "threadId" TEXT REFERENCES "Conversation"(id) ON UPDATE CASCADE ON DELETE CASCADE;
CREATE INDEX "Conversation_threadId_updatedAt_idx" ON "Conversation"("threadId","updatedAt");
ALTER TABLE "ConversationMember" ADD COLUMN "blocked" BOOLEAN NOT NULL DEFAULT false,
 ADD COLUMN "hidden" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Message" ADD COLUMN "mediaName" TEXT;

-- Keep listing-specific IDs for historical messages, trades, reviews and old links.
CREATE TEMP TABLE chat_pairs ON COMMIT DROP AS
 SELECT c.id, string_agg(m."userId", ':' ORDER BY m."userId" COLLATE "C") AS pair
 FROM "Conversation" c JOIN "ConversationMember" m ON m."conversationId"=c.id
 GROUP BY c.id HAVING count(*)=2;
INSERT INTO "Conversation"(id,"pairKey","createdAt","updatedAt")
 SELECT gen_random_uuid()::text, p.pair, min(c."createdAt"), max(c."updatedAt")
 FROM chat_pairs p JOIN "Conversation" c ON c.id=p.id GROUP BY p.pair
 ON CONFLICT ("pairKey") DO NOTHING;
INSERT INTO "ConversationMember"("conversationId","userId")
 SELECT DISTINCT root.id,m."userId" FROM chat_pairs p
 JOIN "Conversation" root ON root."pairKey"=p.pair
 JOIN "ConversationMember" m ON m."conversationId"=p.id ON CONFLICT DO NOTHING;
UPDATE "Conversation" c SET "threadId"=root.id FROM chat_pairs p
 JOIN "Conversation" root ON root."pairKey"=p.pair WHERE c.id=p.id AND c.id<>root.id;
UPDATE "Conversation" root SET "updatedAt"=greatest(root."updatedAt",latest.stamp)
 FROM (SELECT "threadId",max("updatedAt") stamp FROM "Conversation" GROUP BY "threadId") latest
 WHERE root.id=latest."threadId";
COMMIT;
