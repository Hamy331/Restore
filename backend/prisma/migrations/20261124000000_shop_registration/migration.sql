-- AlterTable
ALTER TABLE "Shop" ADD COLUMN     "registrationCredits" INTEGER,
ADD COLUMN     "termsAcceptedAt" TIMESTAMP(3),
ADD COLUMN     "termsVersion" TEXT;
