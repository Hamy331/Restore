-- Khu vực đã chọn gần đây ở trang chọn khu vực (tối đa 8 mỗi người)
CREATE TABLE "RecentArea" (
    "userId" TEXT NOT NULL,
    "code" VARCHAR(10) NOT NULL,
    "usedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "RecentArea_pkey" PRIMARY KEY ("userId","code")
);

CREATE INDEX "RecentArea_userId_usedAt_idx" ON "RecentArea"("userId", "usedAt");

ALTER TABLE "RecentArea" ADD CONSTRAINT "RecentArea_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
