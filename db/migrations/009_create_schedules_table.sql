-- Migration: Create Schedules Table for Waste Collection Scheduling
-- Description: Schedule waste collection requests from citizens
-- Version: 009
-- Date: 2025-02-02

-- Create schedules table
CREATE TABLE IF NOT EXISTS schedules (
    -- Primary key
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Citizen reference
    citizen_id VARCHAR(100) NOT NULL,
    
    -- Schedule details
    scheduled_date TIMESTAMPTZ NOT NULL,
    time_slot VARCHAR(50) NOT NULL CHECK (time_slot IN ('morning', 'afternoon', 'evening')),
    
    -- Waste information
    waste_type VARCHAR(50) NOT NULL,
    estimated_weight DECIMAL(10, 2) CHECK (estimated_weight >= 0),
    actual_weight DECIMAL(10, 2) CHECK (actual_weight >= 0),
    
    -- Location
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    address TEXT,
    location GEOGRAPHY(POINT, 4326),
    
    -- Assignment
    employee_id UUID REFERENCES personnel(id),
    
    -- Status tracking
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'in_progress', 'completed', 'cancelled')),
    priority INTEGER DEFAULT 0,
    
    -- Additional information
    notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_schedules_citizen_id ON schedules(citizen_id);
CREATE INDEX IF NOT EXISTS idx_schedules_scheduled_date ON schedules(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_schedules_status ON schedules(status);
CREATE INDEX IF NOT EXISTS idx_schedules_employee_id ON schedules(employee_id);
CREATE INDEX IF NOT EXISTS idx_schedules_created_at ON schedules(created_at);

-- Spatial index for location queries
CREATE INDEX IF NOT EXISTS idx_schedules_location ON schedules USING GIST(location);

-- Composite index for citizen + status queries
CREATE INDEX IF NOT EXISTS idx_schedules_citizen_status ON schedules(citizen_id, status);

-- Update location from lat/lon trigger
CREATE OR REPLACE FUNCTION update_schedule_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_schedule_location
    BEFORE INSERT OR UPDATE OF latitude, longitude ON schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_schedule_location();

-- Update updated_at timestamp trigger
CREATE OR REPLACE FUNCTION update_schedule_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_schedule_updated_at
    BEFORE UPDATE ON schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_schedule_updated_at();

-- Set completed_at when status changes to completed
CREATE OR REPLACE FUNCTION update_schedule_completed_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        NEW.completed_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_schedule_completed_at
    BEFORE UPDATE OF status ON schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_schedule_completed_at();

-- Set cancelled_at when status changes to cancelled
CREATE OR REPLACE FUNCTION update_schedule_cancelled_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
        NEW.cancelled_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_schedule_cancelled_at
    BEFORE UPDATE OF status ON schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_schedule_cancelled_at();

-- Add comments for documentation
COMMENT ON TABLE schedules IS 'Scheduled waste collection requests from citizens';
COMMENT ON COLUMN schedules.schedule_id IS 'Unique identifier for the schedule';
COMMENT ON COLUMN schedules.citizen_id IS 'ID of the citizen who created the schedule';
COMMENT ON COLUMN schedules.scheduled_date IS 'Scheduled date and time for collection';
COMMENT ON COLUMN schedules.time_slot IS 'Time slot: morning, afternoon, or evening';
COMMENT ON COLUMN schedules.waste_type IS 'Type of waste to be collected';
COMMENT ON COLUMN schedules.estimated_weight IS 'Estimated weight in kg provided by citizen';
COMMENT ON COLUMN schedules.actual_weight IS 'Actual weight in kg recorded by worker';
COMMENT ON COLUMN schedules.employee_id IS 'Assigned worker/personnel ID';
COMMENT ON COLUMN schedules.status IS 'Current status: pending, assigned, in_progress, completed, cancelled';
COMMENT ON COLUMN schedules.priority IS 'Priority level for scheduling (higher = more urgent)';
