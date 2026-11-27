-- AlterTable
ALTER TABLE "SepayWebhookEvent" ADD COLUMN     "apiTransactionId" TEXT,
ADD COLUMN     "source" TEXT NOT NULL DEFAULT 'webhook';

-- CreateTable
CREATE TABLE "SepaySyncState" (
    "id" TEXT NOT NULL,
    "cursor" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SepaySyncState_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "SepayWebhookEvent_apiTransactionId_key" ON "SepayWebhookEvent"("apiTransactionId");

-- CreateIndex
CREATE INDEX "SepayWebhookEvent_referenceCode_amountVnd_idx" ON "SepayWebhookEvent"("referenceCode", "amountVnd");


-- Chỉ backend đọc / ghi, không mở qua API Supabase
ALTER TABLE "SepaySyncState" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "SepaySyncState" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "SepaySyncState" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "SepaySyncState" FROM authenticated; END IF; END $$;
