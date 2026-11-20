import { PrismaClient } from '@prisma/client';

/**
 * Transaction tương tác (prisma.$transaction(async (tx) => ...)) mặc định chỉ được 5 giây.
 * DB Supabase ở xa, mỗi truy vấn mất ~1 giây nên các transaction nhiều bước (đăng tin, đăng nháp, trừ xu)
 * dễ vượt 5 giây và báo P2028 "Transaction not found". Nới lên 20 giây, chờ lấy kết nối tối đa 10 giây.
 */
export const prisma = new PrismaClient({
  transactionOptions: { maxWait: 10_000, timeout: 20_000 },
});
