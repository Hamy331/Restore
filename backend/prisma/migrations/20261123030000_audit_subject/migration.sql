-- Người bị ảnh hưởng của dòng nhật ký (VD chủ tin bị kiểm duyệt): lịch sử vi phạm không mất khi tin bị xoá
ALTER TABLE "AdminAudit" ADD COLUMN "subjectId" TEXT;
CREATE INDEX "AdminAudit_subjectId_createdAt_idx" ON "AdminAudit"("subjectId", "createdAt");

-- Điền cho nhật ký kiểm duyệt tin cũ (tin còn tồn tại)
UPDATE "AdminAudit" a SET "subjectId" = l."ownerId"
FROM "Listing" l
WHERE a."targetType" = 'LISTING' AND a."targetId" = l.id AND a."subjectId" IS NULL;
