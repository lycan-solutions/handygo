-- Add soft-delete support to users table
ALTER TABLE "users" ADD COLUMN "deletedAt" TIMESTAMP(3);
