-- Migration: Add photo_urls to schedules table
-- Description: Add column to store multiple photo URLs for waste collection schedules
-- Version: 012
-- Date: 2025-11-29

-- Add photo_urls column to schedules table
ALTER TABLE schedules 
ADD COLUMN IF NOT EXISTS photo_urls TEXT[];

-- Create index for photo_urls (GIN index for array operations)
CREATE INDEX IF NOT EXISTS idx_schedules_photo_urls ON schedules USING GIN(photo_urls);

-- Add comment
COMMENT ON COLUMN schedules.photo_urls IS 'Array of photo URLs uploaded by citizens when creating schedule';

-- Migration completed
SELECT 'Migration 012: Added photo_urls column to schedules table' as status;
