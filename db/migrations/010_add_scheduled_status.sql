-- Migration: Add 'scheduled' status to schedules table
-- Description: Allow schedules to have 'scheduled' status when created successfully
-- Version: 010
-- Date: 2025-11-25

-- Drop old constraint
ALTER TABLE schedules DROP CONSTRAINT IF EXISTS schedules_status_check;

-- Add new constraint with 'scheduled' status
ALTER TABLE schedules ADD CONSTRAINT schedules_status_check 
    CHECK (status IN ('pending', 'scheduled', 'assigned', 'in_progress', 'completed', 'cancelled'));

-- Update default status to 'scheduled'
ALTER TABLE schedules ALTER COLUMN status SET DEFAULT 'scheduled';

-- Update existing 'pending' records to 'scheduled' (optional, for data migration)
UPDATE schedules SET status = 'scheduled' WHERE status = 'pending';

-- Add comment
COMMENT ON COLUMN schedules.status IS 'Status: pending (chờ xử lý), scheduled (đã lên lịch), assigned (đã phân công), in_progress (đang thực hiện), completed (hoàn thành), cancelled (đã hủy)';
