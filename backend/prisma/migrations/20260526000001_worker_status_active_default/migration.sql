-- Change default value of worker_profiles.status from INACTIVE to ACTIVE
ALTER TABLE "worker_profiles" ALTER COLUMN "status" SET DEFAULT 'ACTIVE'::"WorkerStatus";
