-- Shop uy tín: gian hàng, theo dõi shop, banner shop; giá gốc của tin để hiện giảm giá

ALTER TABLE "Listing" ADD COLUMN "originalPrice" DECIMAL(65,30);

CREATE TYPE "ShopVerificationType" AS ENUM ('OFFICIAL_BRAND', 'CERTIFIED');
CREATE TYPE "ShopBannerStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

CREATE TABLE "Shop" (
    "id" TEXT NOT NULL,
    "ownerId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "tagline" TEXT NOT NULL DEFAULT '',
    "description" TEXT NOT NULL DEFAULT '',
    "logoUrl" TEXT,
    "coverUrl" TEXT,
    "accentColor" TEXT,
    "verificationType" "ShopVerificationType",
    "verifiedAt" TIMESTAMP(3),
    "certificateCode" TEXT,
    "categoryIds" TEXT[],
    "address" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "Shop_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Shop_ownerId_key" ON "Shop"("ownerId");
CREATE INDEX "Shop_verificationType_verifiedAt_idx" ON "Shop"("verificationType", "verifiedAt");
ALTER TABLE "Shop" ADD CONSTRAINT "Shop_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "ShopFollow" (
    "userId" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ShopFollow_pkey" PRIMARY KEY ("userId","shopId")
);
CREATE INDEX "ShopFollow_shopId_idx" ON "ShopFollow"("shopId");
ALTER TABLE "ShopFollow" ADD CONSTRAINT "ShopFollow_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ShopFollow" ADD CONSTRAINT "ShopFollow_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "ShopBanner" (
    "id" TEXT NOT NULL,
    "shopId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "imageUrl" TEXT NOT NULL,
    "startsAt" TIMESTAMP(3),
    "endsAt" TIMESTAMP(3),
    "status" "ShopBannerStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ShopBanner_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ShopBanner_shopId_status_idx" ON "ShopBanner"("shopId", "status");
ALTER TABLE "ShopBanner" ADD CONSTRAINT "ShopBanner_shopId_fkey" FOREIGN KEY ("shopId") REFERENCES "Shop"("id") ON DELETE CASCADE ON UPDATE CASCADE;
