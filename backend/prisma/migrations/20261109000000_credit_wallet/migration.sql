-- Xu ReStore (credit): gói nạp, đơn nạp, sổ cái xu

-- CreateEnum
CREATE TYPE "CreditPayMethod" AS ENUM ('VNPAY', 'VIETQR');
CREATE TYPE "TopupStatus" AS ENUM ('PENDING', 'PAID', 'FAILED', 'EXPIRED', 'REFUNDED');
CREATE TYPE "CreditTxnType" AS ENUM ('TOPUP', 'BONUS', 'SPEND', 'REFUND', 'EXPIRE', 'ADJUST');
CREATE TYPE "CreditBucket" AS ENUM ('PAID', 'BONUS');

-- CreateTable
CREATE TABLE "CreditPackage" (
    "id" TEXT NOT NULL,
    "priceVnd" INTEGER NOT NULL,
    "credits" INTEGER NOT NULL,
    "bonusCredits" INTEGER NOT NULL DEFAULT 0,
    "popular" BOOLEAN NOT NULL DEFAULT false,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "CreditPackage_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "CreditTopupOrder" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "method" "CreditPayMethod" NOT NULL,
    "amountVnd" INTEGER NOT NULL,
    "credits" INTEGER NOT NULL,
    "bonusCredits" INTEGER NOT NULL DEFAULT 0,
    "status" "TopupStatus" NOT NULL DEFAULT 'PENDING',
    "providerTxnId" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "paidAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CreditTopupOrder_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "CreditTransaction" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "CreditTxnType" NOT NULL,
    "bucket" "CreditBucket" NOT NULL,
    "amount" INTEGER NOT NULL,
    "expiresAt" TIMESTAMP(3),
    "topupOrderId" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CreditTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "CreditTopupOrder_code_key" ON "CreditTopupOrder"("code");
CREATE UNIQUE INDEX "CreditTopupOrder_providerTxnId_key" ON "CreditTopupOrder"("providerTxnId");
CREATE INDEX "CreditTopupOrder_userId_status_idx" ON "CreditTopupOrder"("userId", "status");
CREATE INDEX "CreditTransaction_userId_createdAt_idx" ON "CreditTransaction"("userId", "createdAt");
CREATE UNIQUE INDEX "CreditTransaction_topupOrderId_type_key" ON "CreditTransaction"("topupOrderId", "type");

-- AddForeignKey
ALTER TABLE "CreditTopupOrder" ADD CONSTRAINT "CreditTopupOrder_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CreditTopupOrder" ADD CONSTRAINT "CreditTopupOrder_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "CreditPackage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "CreditTransaction" ADD CONSTRAINT "CreditTransaction_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CreditTransaction" ADD CONSTRAINT "CreditTransaction_topupOrderId_fkey" FOREIGN KEY ("topupOrderId") REFERENCES "CreditTopupOrder"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Gói nạp mặc định (1 xu = 1.000 đ), admin sửa được sau
INSERT INTO "CreditPackage" ("id", "priceVnd", "credits", "bonusCredits", "popular", "sortOrder") VALUES
  ('p20', 20000, 20, 0, false, 1),
  ('p50', 50000, 50, 2, false, 2),
  ('p100', 100000, 100, 10, true, 3),
  ('p200', 200000, 200, 30, false, 4),
  ('p500', 500000, 500, 100, false, 5)
ON CONFLICT ("id") DO NOTHING;
