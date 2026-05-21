-- AlterTable: add currentlyWorking boolean to worker_profiles
ALTER TABLE "worker_profiles" ADD COLUMN "currentlyWorking" BOOLEAN NOT NULL DEFAULT false;

-- Add location tracking columns missing from init_auth (added here so the
-- timestamptz conversion in the next migration can find them on a fresh DB)
ALTER TABLE "worker_profiles"
  ADD COLUMN IF NOT EXISTS "currentLat"        DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "currentLng"        DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "locationUpdatedAt" TIMESTAMP(3);

-- Add availabilityStatus enum + column (also absent from init_auth)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'AvailabilityStatus') THEN
    CREATE TYPE "AvailabilityStatus" AS ENUM ('OFFLINE', 'ONLINE', 'BUSY');
  END IF;
END $$;

ALTER TABLE "worker_profiles"
  ADD COLUMN IF NOT EXISTS "availabilityStatus" "AvailabilityStatus" NOT NULL DEFAULT 'OFFLINE';
