-- Migration: Create Incidents Table for Reports
-- Description: Create incidents table for citizen and worker reports (violations and damages)
-- Version: 013
-- Date: 2025-11-29

-- Create incidents table
CREATE TABLE IF NOT EXISTS incidents (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Reporter information
    reporter_id VARCHAR(100) NOT NULL,
    reporter_name TEXT,
    reporter_phone TEXT,
    
    -- Report details
    report_category TEXT NOT NULL CHECK (report_category IN ('violation', 'damage')),
    type TEXT NOT NULL CHECK (type IN (
        -- Violations (vi phạm)
        'illegal_dump',           -- Vứt rác trái phép
        'wrong_classification',   -- Phân loại sai
        'overloaded_bin',        -- Thùng rác quá tải
        'littering',             -- Xả rác bừa bãi
        'burning_waste',         -- Đốt rác
        -- Damages (hư hỏng)
        'broken_bin',            -- Thùng rác hỏng
        'damaged_equipment',     -- Thiết bị hư hỏng
        'road_damage',           -- Đường bị hư
        'facility_damage',       -- Cơ sở vật chất hư hỏng
        -- Other
        'missed_collection',     -- Bỏ sót thu gom
        'overflow',              -- Tràn rác
        'vehicle_issue',         -- Sự cố xe
        'other'                  -- Khác
    )),
    
    -- Description
    description TEXT NOT NULL,
    
    -- Location (simple lat/lon)
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_address TEXT,
    
    -- Images (array of URLs)
    image_urls TEXT[] NOT NULL,
    
    -- Priority & Status
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'open', 'in_progress', 'resolved', 'closed', 'rejected')),
    
    -- Assignment
    assigned_to UUID REFERENCES personnel(id),
    
    -- Resolution
    resolution_notes TEXT,
    resolved_at TIMESTAMPTZ,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_incidents_reporter_id ON incidents(reporter_id);
CREATE INDEX IF NOT EXISTS idx_incidents_report_category ON incidents(report_category);
CREATE INDEX IF NOT EXISTS idx_incidents_type ON incidents(type);
CREATE INDEX IF NOT EXISTS idx_incidents_status ON incidents(status);
CREATE INDEX IF NOT EXISTS idx_incidents_priority ON incidents(priority);
CREATE INDEX IF NOT EXISTS idx_incidents_created_at ON incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_assigned_to ON incidents(assigned_to);

-- Spatial indexes for location queries
CREATE INDEX IF NOT EXISTS idx_incidents_latitude ON incidents(latitude);
CREATE INDEX IF NOT EXISTS idx_incidents_longitude ON incidents(longitude);

-- GIN index for image_urls array
CREATE INDEX IF NOT EXISTS idx_incidents_image_urls ON incidents USING GIN(image_urls);

-- Composite index for reporter + status
CREATE INDEX IF NOT EXISTS idx_incidents_reporter_status ON incidents(reporter_id, status);

-- Update updated_at trigger
CREATE OR REPLACE FUNCTION update_incident_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_incident_updated_at
    BEFORE UPDATE ON incidents
    FOR EACH ROW
    EXECUTE FUNCTION update_incident_updated_at();

-- Set resolved_at when status changes to resolved
CREATE OR REPLACE FUNCTION update_incident_resolved_at()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IN ('resolved', 'closed') AND OLD.status NOT IN ('resolved', 'closed') THEN
        NEW.resolved_at := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_incident_resolved_at
    BEFORE UPDATE ON incidents
    FOR EACH ROW
    EXECUTE FUNCTION update_incident_resolved_at();

COMMENT ON TABLE incidents IS 'Incident reports from citizens and workers, including violations and damages';
COMMENT ON COLUMN incidents.report_category IS 'Category: violation (vi phạm) or damage (hư hỏng)';
COMMENT ON COLUMN incidents.image_urls IS 'Array of image URLs uploaded by reporter (mandatory, 1-3 photos)';
COMMENT ON COLUMN incidents.location_address IS 'Human-readable address or location description';mandatory, 1-3 photos)';
COMMENT ON COLUMN incidents.location_address IS 'Reverse geocoded address from geom';

-- Migration completed
SELECT 'Migration 013: Created incidents table' as status;
