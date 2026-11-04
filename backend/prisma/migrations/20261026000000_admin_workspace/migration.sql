CREATE TYPE "ReportStatus" AS ENUM ('OPEN', 'RESOLVED', 'DISMISSED');

CREATE TYPE "PostStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'HIDDEN', 'ARCHIVED');

ALTER TABLE "User" ADD COLUMN     "suspendedUntil" TIMESTAMP(3);

ALTER TABLE "Category" ADD COLUMN     "active" BOOLEAN NOT NULL DEFAULT true;

CREATE TABLE "AdminAudit" (
    "id" TEXT NOT NULL,
    "actorId" TEXT NOT NULL,
    "action" TEXT NOT NULL,
    "targetType" TEXT NOT NULL,
    "targetId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "before" JSONB,
    "after" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AdminAudit_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ConditionPolicy" (
    "condition" "ListingCondition" NOT NULL,
    "name" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ConditionPolicy_pkey" PRIMARY KEY ("condition")
);

CREATE TABLE "ViolationReport" (
    "id" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "targetType" TEXT NOT NULL,
    "targetId" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "evidence" TEXT NOT NULL,
    "status" "ReportStatus" NOT NULL DEFAULT 'OPEN',
    "decision" TEXT,
    "resolution" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ViolationReport_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "BlogPost" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "coverUrl" TEXT,
    "listingIds" TEXT[],
    "status" "PostStatus" NOT NULL DEFAULT 'DRAFT',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BlogPost_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SupportTicket" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SupportTicket_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "SupportMessage" (
    "id" TEXT NOT NULL,
    "ticketId" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "isAdmin" BOOLEAN NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SupportMessage_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "KnowledgeDocument" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "indexedText" TEXT,
    "syncedAt" TIMESTAMP(3),
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "KnowledgeDocument_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "AdminAudit_targetType_targetId_createdAt_idx" ON "AdminAudit"("targetType", "targetId", "createdAt");

CREATE INDEX "AdminAudit_createdAt_idx" ON "AdminAudit"("createdAt");

CREATE INDEX "ViolationReport_status_createdAt_idx" ON "ViolationReport"("status", "createdAt");

CREATE INDEX "ViolationReport_reporterId_idx" ON "ViolationReport"("reporterId");

CREATE UNIQUE INDEX "BlogPost_slug_key" ON "BlogPost"("slug");

CREATE INDEX "BlogPost_status_createdAt_idx" ON "BlogPost"("status", "createdAt");

CREATE INDEX "SupportTicket_userId_createdAt_idx" ON "SupportTicket"("userId", "createdAt");

CREATE INDEX "SupportTicket_status_updatedAt_idx" ON "SupportTicket"("status", "updatedAt");

CREATE INDEX "SupportMessage_ticketId_createdAt_idx" ON "SupportMessage"("ticketId", "createdAt");

CREATE INDEX "KnowledgeDocument_active_idx" ON "KnowledgeDocument"("active");

ALTER TABLE "SupportMessage" ADD CONSTRAINT "SupportMessage_ticketId_fkey" FOREIGN KEY ("ticketId") REFERENCES "SupportTicket"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "AdminAudit" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "AdminAudit" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "AdminAudit" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "AdminAudit" FROM authenticated; END IF; END $$;

ALTER TABLE "ConditionPolicy" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "ConditionPolicy" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "ConditionPolicy" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "ConditionPolicy" FROM authenticated; END IF; END $$;

ALTER TABLE "ViolationReport" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "ViolationReport" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "ViolationReport" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "ViolationReport" FROM authenticated; END IF; END $$;

ALTER TABLE "BlogPost" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "BlogPost" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "BlogPost" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "BlogPost" FROM authenticated; END IF; END $$;

ALTER TABLE "SupportTicket" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "SupportTicket" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "SupportTicket" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "SupportTicket" FROM authenticated; END IF; END $$;

ALTER TABLE "SupportMessage" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "SupportMessage" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "SupportMessage" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "SupportMessage" FROM authenticated; END IF; END $$;

ALTER TABLE "KnowledgeDocument" ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE "KnowledgeDocument" FROM PUBLIC;
DO $$ BEGIN IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='anon') THEN REVOKE ALL ON "KnowledgeDocument" FROM anon; END IF; IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname='authenticated') THEN REVOKE ALL ON "KnowledgeDocument" FROM authenticated; END IF; END $$;

INSERT INTO "ConditionPolicy" ("condition","name","active","updatedAt") VALUES ('NEW','Mới',true,NOW()),('LIKE_NEW','Như mới',true,NOW()),('USED_GOOD','Đã dùng – Tốt',true,NOW()),('USED_FAIR','Đã dùng – Khá',true,NOW()),('FOR_PARTS','Cần sửa chữa',true,NOW());
ALTER TABLE "SupportTicket" ADD CONSTRAINT "SupportTicket_status_check" CHECK (status IN ('OPEN','RESOLVED'));
ALTER TABLE "ViolationReport" ADD CONSTRAINT "ViolationReport_targetType_check" CHECK ("targetType" IN ('USER','LISTING'));

CREATE INDEX "User_status_suspendedUntil_idx" ON "User"("status", "suspendedUntil");