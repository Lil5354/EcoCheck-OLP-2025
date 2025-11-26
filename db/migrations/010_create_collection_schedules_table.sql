-- 010_create_collection_schedules_table.sql
-- Create collection_schedules table for citizen collection requests
-- MIT License - Copyright (c) 2025 Lil5354

BEGIN;

-- Create collection_schedules table
CREATE TABLE IF NOT EXISTS collection_schedules (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  citizen_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scheduled_date date NOT NULL,
  time_slot text NOT NULL, -- e.g., "18:00-20:00", "20:00-22:00"
  waste_type text NOT NULL CHECK (waste_type IN ('household', 'recyclable', 'bulky', 'hazardous', 'organic')),
  estimated_weight_kg numeric(10,2) DEFAULT 0 CHECK (estimated_weight_kg >= 0),
  latitude numeric(10,7),
  longitude numeric(10,7),
  address text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'scheduled', 'assigned', 'in_progress', 'completed', 'cancelled', 'missed')),
  priority int DEFAULT 0 CHECK (priority >= 0),
  employee_id uuid REFERENCES personnel(id) ON DELETE SET NULL, -- Assigned worker
  route_id uuid REFERENCES routes(id) ON DELETE SET NULL, -- Assigned route
  notes text,
  completed_at timestamptz,
  cancelled_at timestamptz,
  cancelled_reason text,
  meta jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS collection_schedules_citizen_idx ON collection_schedules(citizen_id);
CREATE INDEX IF NOT EXISTS collection_schedules_status_idx ON collection_schedules(status);
CREATE INDEX IF NOT EXISTS collection_schedules_date_idx ON collection_schedules(scheduled_date);
CREATE INDEX IF NOT EXISTS collection_schedules_employee_idx ON collection_schedules(employee_id) WHERE employee_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS collection_schedules_route_idx ON collection_schedules(route_id) WHERE route_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS collection_schedules_created_idx ON collection_schedules(created_at DESC);

-- Add comment
COMMENT ON TABLE collection_schedules IS 'Lịch thu gom rác từ người dân';
COMMENT ON COLUMN collection_schedules.citizen_id IS 'ID của người dân đăng ký';
COMMENT ON COLUMN collection_schedules.scheduled_date IS 'Ngày dự kiến thu gom';
COMMENT ON COLUMN collection_schedules.time_slot IS 'Khung giờ thu gom (ví dụ: 18:00-20:00)';
COMMENT ON COLUMN collection_schedules.status IS 'Trạng thái: pending (chờ xử lý), scheduled (đã lên lịch), assigned (đã gán nhân viên), in_progress (đang thực hiện), completed (hoàn thành), cancelled (đã hủy), missed (bỏ lỡ)';

-- Create trigger for updated_at
CREATE TRIGGER collection_schedules_updated_at
  BEFORE UPDATE ON collection_schedules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

COMMIT;

