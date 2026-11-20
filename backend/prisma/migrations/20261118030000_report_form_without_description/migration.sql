-- The agreed report form contains only a reason and two contact fields.
UPDATE "ReportReason"
SET "requiresDescription" = false, "guidanceVi" = NULL, "guidanceEn" = NULL,
    "updatedAt" = CURRENT_TIMESTAMP;
