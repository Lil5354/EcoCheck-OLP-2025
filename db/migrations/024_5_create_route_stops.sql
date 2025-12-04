-- Create route_stops table for managing individual stops in routes
-- MIT License - Copyright (c) 2025 Lil5354

-- Create route_stops table if not exists
CREATE TABLE IF NOT EXISTS route_stops (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id uuid NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  point_id uuid REFERENCES points(id) ON DELETE SET NULL,
  seq int NOT NULL,
  stop_order int,
  point_name text,
  status text NOT NULL DEFAULT 'pending',
  planned_eta timestamptz,
  actual_at timestamptz,
  completed_at timestamptz,
  actual_weight_kg numeric(10,2),
  photo_urls text[],
  notes text,
  reason text,
  meta jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS route_stops_route_id_idx ON route_stops(route_id);
CREATE INDEX IF NOT EXISTS route_stops_point_id_idx ON route_stops(point_id);
CREATE INDEX IF NOT EXISTS route_stops_status_idx ON route_stops(status);
CREATE INDEX IF NOT EXISTS route_stops_route_order_idx ON route_stops(route_id, stop_order);

-- Add constraint
ALTER TABLE route_stops DROP CONSTRAINT IF EXISTS route_stops_status_check;
ALTER TABLE route_stops ADD CONSTRAINT route_stops_status_check 
  CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped', 'failed'));

-- Create unique constraint on route_id + stop_order
CREATE UNIQUE INDEX IF NOT EXISTS route_stops_route_order_uniq ON route_stops(route_id, stop_order);

-- Add trigger to update updated_at
CREATE OR REPLACE FUNCTION update_route_stops_updated_at()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_route_stops_updated_at ON route_stops;
CREATE TRIGGER update_route_stops_updated_at 
  BEFORE UPDATE ON route_stops 
  FOR EACH ROW EXECUTE FUNCTION update_route_stops_updated_at();

-- Grant permissions
GRANT ALL ON route_stops TO ecocheck_user;
