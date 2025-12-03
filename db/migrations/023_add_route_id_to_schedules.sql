-- Migration: Add route_id to schedules table
-- Description: Link schedules to routes for Route-first assignment approach
-- Version: 023
-- Date: 2025-01-XX

-- Add route_id column to schedules table
ALTER TABLE schedules 
ADD COLUMN IF NOT EXISTS route_id UUID REFERENCES routes(id) ON DELETE SET NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_schedules_route_id ON schedules(route_id) WHERE route_id IS NOT NULL;

-- Add comment
COMMENT ON COLUMN schedules.route_id IS 'Route ID that this schedule belongs to (for route-first assignment approach)';

-- Migration completed
SELECT 'Migration 023: Added route_id to schedules table' as status;

