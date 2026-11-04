import { Prisma } from '@prisma/client';

/**
 * Ghi một dòng AdminAudit trong transaction đang chạy.
 * Chỉ truyền ảnh chụp công khai vào before/after: không bao giờ có mật khẩu, OTP hay token.
 */
export function audit(tx: Prisma.TransactionClient, actorId: string, action: string, targetType: string, targetId: string,
  reason: string, before?: unknown, after?: unknown) {
  const json = (value: unknown) => value == null ? Prisma.DbNull : JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;
  return tx.adminAudit.create({ data: { actorId, action, targetType, targetId, reason, before: json(before), after: json(after) } });
}
