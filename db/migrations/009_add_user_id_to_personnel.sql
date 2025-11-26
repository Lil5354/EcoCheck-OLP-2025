-- 009_add_user_id_to_personnel.sql
-- Add user_id column to personnel table to link with users table
-- This enables creating worker accounts that can login via mobile app

BEGIN;

-- Add user_id column to personnel if not exists
ALTER TABLE personnel ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES users(id) ON DELETE SET NULL;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS personnel_user_id_idx ON personnel(user_id) WHERE user_id IS NOT NULL;

-- Add comment
COMMENT ON COLUMN personnel.user_id IS 'Links personnel to users table for authentication';

COMMIT;

