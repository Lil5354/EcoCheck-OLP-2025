-- Migration: Enhance incidents table for mobile app reporting
-- Add report_category to distinguish between violations and damages

-- Add report_category column
ALTER TABLE incidents 
ADD COLUMN IF NOT EXISTS report_category TEXT 
CHECK (report_category IN ('violation', 'damage'));

-- Add image_urls array for multiple photos
ALTER TABLE incidents 
ADD COLUMN IF NOT EXISTS image_urls TEXT[];

-- Update existing type values to be more comprehensive
ALTER TABLE incidents DROP CONSTRAINT IF EXISTS incidents_type_check;
ALTER TABLE incidents ADD CONSTRAINT incidents_type_check 
CHECK (type IN (
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
));

-- Update status values
ALTER TABLE incidents DROP CONSTRAINT IF EXISTS incidents_status_check;
ALTER TABLE incidents ADD CONSTRAINT incidents_status_check
CHECK (status IN ('pending', 'open', 'in_progress', 'resolved', 'closed', 'rejected'));

-- Add location_address for reverse geocoded address
ALTER TABLE incidents 
ADD COLUMN IF NOT EXISTS location_address TEXT;

-- Add reporter_name for display
ALTER TABLE incidents 
ADD COLUMN IF NOT EXISTS reporter_name TEXT;

-- Add reporter_phone for contact
ALTER TABLE incidents 
ADD COLUMN IF NOT EXISTS reporter_phone TEXT;

-- Create index for report_category
CREATE INDEX IF NOT EXISTS idx_incidents_report_category ON incidents(report_category);

-- Create index for image_urls using GIN
CREATE INDEX IF NOT EXISTS idx_incidents_image_urls ON incidents USING GIN(image_urls);

-- Update trigger for updated_at
DROP TRIGGER IF EXISTS update_incidents_updated_at ON incidents;
CREATE TRIGGER update_incidents_updated_at
    BEFORE UPDATE ON incidents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comment
COMMENT ON COLUMN incidents.report_category IS 'Category: violation (vi phạm) or damage (hư hỏng)';
COMMENT ON COLUMN incidents.image_urls IS 'Array of image URLs uploaded by reporter';
COMMENT ON COLUMN incidents.location_address IS 'Reverse geocoded address from geom';
COMMENT ON TABLE incidents IS 'Incident reports from citizens and workers, including violations and damages';
