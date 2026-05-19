-- Migration: standardize_media_storage_metadata
-- Adds nullable metadata fields to booking_attachments, chat_messages,
-- client_profiles, worker_profiles, and worker_documents.
-- All columns are nullable — no existing rows are affected.

-- BookingAttachment: scoped storage key + rich metadata
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
