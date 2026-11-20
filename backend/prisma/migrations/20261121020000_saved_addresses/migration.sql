-- Địa chỉ đã lưu để chọn lại khi đăng tin (tối đa 5 mỗi người)
CREATE TABLE "SavedAddress" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "label" VARCHAR(40),
    "provinceCode" VARCHAR(10) NOT NULL,
    "wardCode" VARCHAR(10) NOT NULL,
    "streetAddress" VARCHAR(200) NOT NULL DEFAULT '',
    "streetKey" VARCHAR(200) NOT NULL DEFAULT '',
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "geoSource" VARCHAR(16) NOT NULL DEFAULT 'ward_center',
    "lastUsedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SavedAddress_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "SavedAddress_userId_wardCode_streetKey_key" ON "SavedAddress"("userId", "wardCode", "streetKey");
CREATE INDEX "SavedAddress_userId_lastUsedAt_idx" ON "SavedAddress"("userId", "lastUsedAt");

ALTER TABLE "SavedAddress" ADD CONSTRAINT "SavedAddress_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
