-- Migration: standardize_media_storage_metadata
-- Adds nullable metadata fields to booking_attachments, chat_messages,
-- client_profiles, worker_profiles, and worker_documents.
-- All columns are nullable — no existing rows are affected.

-- AttachmentType enum: never created in earlier migrations
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'AttachmentType') THEN
    CREATE TYPE "AttachmentType" AS ENUM ('IMAGE', 'VIDEO', 'AUDIO');
  END IF;
END $$;

-- booking_attachments: table absent from all earlier migrations; create it now
CREATE TABLE IF NOT EXISTS "booking_attachments" (
    "id"              TEXT NOT NULL,
    "bookingId"       TEXT NOT NULL,
    "type"            "AttachmentType" NOT NULL,
    "url"             TEXT NOT NULL,
    "storageKey"      TEXT,
    "fileName"        TEXT,
    "mimeType"        TEXT,
    "sizeBytes"       INTEGER,
    "durationSeconds" DOUBLE PRECISION,
    "thumbnailUrl"    TEXT,
    "createdAt"       TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "booking_attachments_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "booking_attachments_bookingId_idx" ON "booking_attachments"("bookingId");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'booking_attachments_bookingId_fkey'
  ) THEN
    ALTER TABLE "booking_attachments"
      ADD CONSTRAINT "booking_attachments_bookingId_fkey"
      FOREIGN KEY ("bookingId") REFERENCES "bookings"("id")
      ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

-- BookingAttachment: scoped storage key + rich metadata (safe on existing DBs)
ALTER TABLE "booking_attachments"
  ADD COLUMN IF NOT EXISTS "storageKey"      TEXT,
  ADD COLUMN IF NOT EXISTS "sizeBytes"       INTEGER,
  ADD COLUMN IF NOT EXISTS "durationSeconds" DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "thumbnailUrl"    TEXT;

-- Message (chat): scoped storage key + rich metadata
ALTER TABLE "chat_messages"
  ADD COLUMN IF NOT EXISTS "storageKey"      TEXT,
  ADD COLUMN IF NOT EXISTS "mimeType"        TEXT,
  ADD COLUMN IF NOT EXISTS "fileName"        TEXT,
  ADD COLUMN IF NOT EXISTS "sizeBytes"       INTEGER,
  ADD COLUMN IF NOT EXISTS "durationSeconds" DOUBLE PRECISION;

-- ClientProfile: avatar storage key for future CDN/delete operations
ALTER TABLE "client_profiles"
  ADD COLUMN IF NOT EXISTS "avatarStorageKey" TEXT;

-- WorkerProfile: avatar storage key
ALTER TABLE "worker_profiles"
  ADD COLUMN IF NOT EXISTS "avatarStorageKey" TEXT;

-- WorkerDocument: file metadata
ALTER TABLE "worker_documents"
  ADD COLUMN IF NOT EXISTS "storageKey" TEXT,
  ADD COLUMN IF NOT EXISTS "fileName"   TEXT,
  ADD COLUMN IF NOT EXISTS "mimeType"   TEXT,
  ADD COLUMN IF NOT EXISTS "sizeBytes"  INTEGER;

-- Notification: extra columns absent from init_auth but present in schema
ALTER TABLE "notifications"
  ADD COLUMN IF NOT EXISTS "readAt"      TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "eventKey"    TEXT,
  ADD COLUMN IF NOT EXISTS "entityType"  TEXT,
  ADD COLUMN IF NOT EXISTS "entityId"    TEXT,
  ADD COLUMN IF NOT EXISTS "bookingId"   TEXT,
  ADD COLUMN IF NOT EXISTS "actorUserId" TEXT,
  ADD COLUMN IF NOT EXISTS "actorRole"   TEXT,
  ADD COLUMN IF NOT EXISTS "route"       TEXT,
  ADD COLUMN IF NOT EXISTS "payload"     JSONB;

-- Notification composite index missing from migration chain
CREATE INDEX IF NOT EXISTS "notifications_userId_isRead_idx" ON "notifications"("userId", "isRead");
