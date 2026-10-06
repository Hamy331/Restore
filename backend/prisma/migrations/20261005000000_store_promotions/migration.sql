-- CreateEnum
CREATE TYPE "StoreTier" AS ENUM ('PERSONAL', 'BASIC', 'PRO');

-- CreateEnum
CREATE TYPE "PurchaseStatus" AS ENUM ('PENDING', 'CONFIRMED', 'REJECTED');

-- CreateEnum
CREATE TYPE "PromotionKind" AS ENUM ('BUMP', 'FEATURED');

-- CreateEnum
CREATE TYPE "PromotionSource" AS ENUM ('INCLUDED', 'PURCHASED');

-- AlterTable
ALTER TABLE "Listing" ADD COLUMN     "categoryId" TEXT;

-- CreateTable
CREATE TABLE "Category" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StorePackage" (
    "id" TEXT NOT NULL,
    "tier" "StoreTier" NOT NULL,
    "name" TEXT NOT NULL,
    "monthlyPrice" DECIMAL(65,30) NOT NULL,
    "dailyListingLimit" INTEGER NOT NULL,
    "activeListingLimit" INTEGER NOT NULL,
    "monthlyPromotionQuota" INTEGER NOT NULL,
    "priorityLevel" INTEGER NOT NULL,

    CONSTRAINT "StorePackage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreSubscription" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "startsAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "StoreSubscription_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreOrder" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "amount" DECIMAL(65,30) NOT NULL,
    "status" "PurchaseStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "decidedAt" TIMESTAMP(3),

    CONSTRAINT "StoreOrder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PromotionPackage" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "kind" "PromotionKind" NOT NULL,
    "durationDays" INTEGER NOT NULL,
    "price" DECIMAL(65,30) NOT NULL,
    "priority" INTEGER NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "PromotionPackage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Promotion" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "source" "PromotionSource" NOT NULL DEFAULT 'INCLUDED',
    "orderId" TEXT,
    "startsAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endsAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Promotion_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PromotionOrder" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "packageId" TEXT NOT NULL,
    "amount" DECIMAL(65,30) NOT NULL,
    "status" "PurchaseStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "decidedAt" TIMESTAMP(3),

    CONSTRAINT "PromotionOrder_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "StorePackage_tier_key" ON "StorePackage"("tier");

-- CreateIndex
CREATE UNIQUE INDEX "StoreSubscription_userId_key" ON "StoreSubscription"("userId");

-- CreateIndex
CREATE INDEX "StoreOrder_userId_status_idx" ON "StoreOrder"("userId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "Promotion_orderId_key" ON "Promotion"("orderId");

-- CreateIndex
CREATE INDEX "Promotion_userId_createdAt_idx" ON "Promotion"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "Promotion_listingId_endsAt_idx" ON "Promotion"("listingId", "endsAt");

-- CreateIndex
CREATE INDEX "PromotionOrder_userId_status_idx" ON "PromotionOrder"("userId", "status");

-- AddForeignKey
ALTER TABLE "Listing" ADD CONSTRAINT "Listing_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreSubscription" ADD CONSTRAINT "StoreSubscription_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreSubscription" ADD CONSTRAINT "StoreSubscription_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "StorePackage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreSubscription" ADD CONSTRAINT "StoreSubscription_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreOrder" ADD CONSTRAINT "StoreOrder_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreOrder" ADD CONSTRAINT "StoreOrder_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "StorePackage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreOrder" ADD CONSTRAINT "StoreOrder_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Promotion" ADD CONSTRAINT "Promotion_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Promotion" ADD CONSTRAINT "Promotion_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Promotion" ADD CONSTRAINT "Promotion_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "PromotionPackage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Promotion" ADD CONSTRAINT "Promotion_orderId_fkey" FOREIGN KEY ("orderId") REFERENCES "PromotionOrder"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PromotionOrder" ADD CONSTRAINT "PromotionOrder_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PromotionOrder" ADD CONSTRAINT "PromotionOrder_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PromotionOrder" ADD CONSTRAINT "PromotionOrder_packageId_fkey" FOREIGN KEY ("packageId") REFERENCES "PromotionPackage"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Sample catalog. Adjust prices and limits in the catalog after product review.
INSERT INTO "Category" ("id", "name") VALUES
('phones', 'Điện thoại'),
('vehicles', 'Xe cộ'),
('furniture', 'Nội thất'),
('electronics', 'Điện tử'),
('fashion', 'Thời trang'),
('other', 'Khác');

INSERT INTO "StorePackage" ("id", "tier", "name", "monthlyPrice", "dailyListingLimit", "activeListingLimit", "monthlyPromotionQuota", "priorityLevel") VALUES
('personal', 'PERSONAL', 'Cá nhân', 0, 3, 10, 0, 0),
('basic', 'BASIC', 'Cửa hàng Basic', 99000, 10, 30, 2, 1),
('pro', 'PRO', 'Cửa hàng Pro', 299000, 30, 100, 10, 2);

INSERT INTO "PromotionPackage" ("id", "name", "kind", "durationDays", "price", "priority", "active") VALUES
('bump-1', 'Đẩy tin 1 ngày', 'BUMP', 1, 10000, 0, true),
('bump-3', 'Đẩy tin 3 ngày', 'BUMP', 3, 28000, 0, true),
('bump-7', 'Đẩy tin 7 ngày', 'BUMP', 7, 63000, 0, true),
('featured-1', 'Tin ưu tiên 1 ngày', 'FEATURED', 1, 20000, 3, true),
('featured-3', 'Tin ưu tiên 3 ngày', 'FEATURED', 3, 57000, 3, true),
('featured-7', 'Tin ưu tiên 7 ngày', 'FEATURED', 7, 126000, 3, true);
