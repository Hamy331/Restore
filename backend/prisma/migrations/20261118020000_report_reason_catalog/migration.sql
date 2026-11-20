CREATE TABLE "ReportReason" (
  "code" TEXT NOT NULL PRIMARY KEY,
  "labelVi" TEXT NOT NULL,
  "labelEn" TEXT NOT NULL,
  "requiresDescription" BOOLEAN NOT NULL DEFAULT false,
  "guidanceVi" TEXT,
  "guidanceEn" TEXT,
  "active" BOOLEAN NOT NULL DEFAULT true,
  "sortOrder" INTEGER NOT NULL DEFAULT 0,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Shared catalog for the eight agreed reasons. Runtime reads this table.
INSERT INTO "ReportReason" ("code", "labelVi", "labelEn", "requiresDescription", "sortOrder") VALUES
('SCAM', 'Lừa đảo', 'Scam or fraud', false, 1),
('DUPLICATE', 'Trùng lặp', 'Duplicate listing', false, 2),
('SOLD', 'Hàng đã bán', 'Item already sold', false, 3),
('UNREACHABLE', 'Không liên lạc được', 'Seller cannot be reached', false, 4),
('MISLEADING', 'Thông tin không đúng thực tế', 'Misleading information', false, 5),
('COUNTERFEIT', 'Hàng giả, hàng nhái, hàng dựng', 'Counterfeit or misrepresented goods', false, 6),
('DAMAGED', 'Hàng hư hỏng sau khi mua', 'Item damaged after purchase', false, 7),
('OTHER', 'Lý do khác', 'Other reason', true, 8);

UPDATE "ReportReason" SET
  "guidanceVi" = 'Restore tiếp nhận thông tin để xem xét vi phạm. Báo cáo này không phải yêu cầu hoàn tiền; hãy cung cấp thời điểm mua và mô tả vấn đề nếu có.',
  "guidanceEn" = 'Restore reviews reports for violations. This is not a refund request; include the purchase date and describe the issue if available.'
WHERE "code" = 'DAMAGED';

CREATE INDEX "ViolationReport_targetType_targetId_status_createdAt_idx"
  ON "ViolationReport" ("targetType", "targetId", "status", "createdAt");
CREATE INDEX "ViolationReport_status_reasonCode_createdAt_idx"
  ON "ViolationReport" ("status", "reasonCode", "createdAt");

ALTER TABLE "ReportReason" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON "ReportReason" FROM PUBLIC, anon, authenticated;
