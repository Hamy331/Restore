ALTER TABLE "ViolationReport"
  DROP CONSTRAINT "ViolationReport_targetType_check";

ALTER TABLE "ViolationReport"
  ADD CONSTRAINT "ViolationReport_targetType_check"
  CHECK ("targetType" IN ('USER', 'LISTING', 'FEED_POST'));
