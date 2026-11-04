-- "Báo khi có hàng": thông báo tin mong muốn và các tin đã khớp (C26)

-- CreateEnum
CREATE TYPE "WantedAlertMatchLevel" AS ENUM ('BROAD', 'BALANCED', 'STRICT');

-- CreateTable
CREATE TABLE "WantedAlert" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "keywords" TEXT NOT NULL,
    "categoryId" TEXT,
    "minPrice" BIGINT,
    "maxPrice" BIGINT,
    "conditions" "ListingCondition"[],
    "dealTypes" TEXT[],
    "areaCode" TEXT,
    "areaLevel" TEXT,
    "areaLabel" TEXT,
    "matchLevel" "WantedAlertMatchLevel" NOT NULL DEFAULT 'BALANCED',
    "seenAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastMatchedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "WantedAlert_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WantedAlertMatch" (
    "alertId" TEXT NOT NULL,
    "listingId" TEXT NOT NULL,
    "score" DOUBLE PRECISION NOT NULL,
    "matchedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WantedAlertMatch_pkey" PRIMARY KEY ("alertId","listingId")
);

-- CreateIndex
CREATE INDEX "WantedAlert_userId_createdAt_idx" ON "WantedAlert"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "WantedAlert_categoryId_idx" ON "WantedAlert"("categoryId");

-- CreateIndex
CREATE INDEX "WantedAlertMatch_alertId_matchedAt_idx" ON "WantedAlertMatch"("alertId", "matchedAt");

-- CreateIndex
CREATE INDEX "WantedAlertMatch_listingId_idx" ON "WantedAlertMatch"("listingId");

-- AddForeignKey
ALTER TABLE "WantedAlert" ADD CONSTRAINT "WantedAlert_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WantedAlert" ADD CONSTRAINT "WantedAlert_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WantedAlertMatch" ADD CONSTRAINT "WantedAlertMatch_alertId_fkey" FOREIGN KEY ("alertId") REFERENCES "WantedAlert"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WantedAlertMatch" ADD CONSTRAINT "WantedAlertMatch_listingId_fkey" FOREIGN KEY ("listingId") REFERENCES "Listing"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Chỉ backend (Prisma) đọc ghi, chặn truy cập trực tiếp qua API Supabase
ALTER TABLE "WantedAlert" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "WantedAlert" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "WantedAlert" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "WantedAlert" FROM authenticated; END IF; END $$;

ALTER TABLE "WantedAlertMatch" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "WantedAlertMatch" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "WantedAlertMatch" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "WantedAlertMatch" FROM authenticated; END IF; END $$;
