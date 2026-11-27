BEGIN;
-- Lần đổi tên người dùng gần nhất: đổi xong phải chờ 14 ngày mới đổi tiếp
ALTER TABLE "User" ADD COLUMN "usernameChangedAt" TIMESTAMP(3);
COMMIT;
