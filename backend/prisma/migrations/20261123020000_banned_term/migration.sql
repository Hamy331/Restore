-- Từ / cụm từ admin thêm vào bộ lọc nội dung tin (CONTACT: liên hệ ngoài, BANNED: hàng cấm)
CREATE TABLE "BannedTerm" (
    "id" TEXT NOT NULL,
    "term" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "BannedTerm_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "BannedTerm_term_key" ON "BannedTerm"("term");
