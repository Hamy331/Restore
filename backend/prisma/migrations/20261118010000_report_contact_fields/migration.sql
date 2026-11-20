-- Optional fields preserve reports created by older clients.
ALTER TABLE "ViolationReport"
  ADD COLUMN "reasonCode" TEXT,
  ADD COLUMN "contactPhone" TEXT,
  ADD COLUMN "contactEmail" TEXT;
