-- CreateEnum
CREATE TYPE "SepayEventStatus" AS ENUM ('RECEIVED', 'PAID', 'UNMATCHED', 'DUPLICATE', 'IGNORED');

-- CreateTable
CREATE TABLE "SepayWebhookEvent" (
    "id" TEXT NOT NULL,
    "status" "SepayEventStatus" NOT NULL DEFAULT 'RECEIVED',
    "success" BOOLEAN NOT NULL DEFAULT false,
    "reason" TEXT,
    "transferType" TEXT NOT NULL,
    "amountVnd" INTEGER NOT NULL,
    "code" TEXT,
    "accountNumber" TEXT,
    "referenceCode" TEXT,
    "transactionDate" TEXT,
    "topupOrderId" TEXT,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SepayWebhookEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "SepayWebhookEvent_status_createdAt_idx" ON "SepayWebhookEvent"("status", "createdAt");

-- CreateIndex
CREATE INDEX "SepayWebhookEvent_topupOrderId_idx" ON "SepayWebhookEvent"("topupOrderId");

-- AddForeignKey
ALTER TABLE "SepayWebhookEvent" ADD CONSTRAINT "SepayWebhookEvent_topupOrderId_fkey" FOREIGN KEY ("topupOrderId") REFERENCES "CreditTopupOrder"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- Payload chứa dữ liệu ngân hàng / cá nhân: chỉ backend (role của Prisma) đọc được, không mở qua API Supabase
ALTER TABLE "SepayWebhookEvent" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "SepayWebhookEvent" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "SepayWebhookEvent" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "SepayWebhookEvent" FROM authenticated; END IF; END $$;
