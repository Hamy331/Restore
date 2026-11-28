BEGIN;
-- Lúc xác minh số điện thoại bằng OTP (badge xác minh, quyền đăng tin)
ALTER TABLE "User" ADD COLUMN "phoneVerifiedAt" TIMESTAMP(3);
COMMIT;
