-- Chống gửi trùng thông báo nhắc (VD tin sắp hết hạn): mỗi người một dedupeKey
ALTER TABLE "Notification" ADD COLUMN "dedupeKey" VARCHAR(160);
CREATE UNIQUE INDEX "Notification_userId_dedupeKey_key" ON "Notification"("userId", "dedupeKey");
