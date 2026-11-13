-- Xu ReStore: thêm cổng ZaloPay (sandbox) cho đơn nạp

-- AlterEnum
ALTER TYPE "CreditPayMethod" ADD VALUE 'ZALOPAY';

-- AlterTable
ALTER TABLE "CreditTopupOrder" ADD COLUMN "providerRef" TEXT,
ADD COLUMN "payUrl" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "CreditTopupOrder_providerRef_key" ON "CreditTopupOrder"("providerRef");
