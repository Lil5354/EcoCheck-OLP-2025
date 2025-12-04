-- Migration to enhance routes table for worker app
-- Adds additional fields needed for route management
-- MIT License - Copyright (c) 2025 Lil5354

-- Add missing columns to routes table
ALTER TABLE routes ADD COLUMN IF NOT EXISTS driver_id uuid REFERENCES personnel(id);
ALTER TABLE routes ADD COLUMN IF NOT EXISTS collector_id uuid REFERENCES personnel(id);
ALTER TABLE routes ADD COLUMN IF NOT EXISTS name text;
ALTER TABLE routes ADD COLUMN IF NOT EXISTS scheduled_date date;
ALTER TABLE routes ADD COLUMN IF NOT EXISTS planned_distance_km numeric(10,2);
ALTER TABLE routes ADD COLUMN IF NOT EXISTS planned_duration_min int;
ALTER TABLE routes ADD COLUMN IF NOT EXISTS actual_distance_km numeric(10,2);
ALTER TABLE routes ADD COLUMN IF NOT EXISTS actual_duration_min int;
ALTER TABLE routes ADD COLUMN IF NOT EXISTS total_weight_kg numeric(10,2);
ALTER TABLE routes ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE routes ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE routes ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES users(id);

-- Add status constraint
ALTER TABLE routes DROP CONSTRAINT IF EXISTS routes_status_check;
ALTER TABLE routes ADD CONSTRAINT routes_status_check 
  CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled'));

-- Add indexes for worker queries
CREATE INDEX IF NOT EXISTS routes_driver_id_idx ON routes(driver_id);
CREATE INDEX IF NOT EXISTS routes_collector_id_idx ON routes(collector_id);
CREATE INDEX IF NOT EXISTS routes_scheduled_date_idx ON routes(scheduled_date);
CREATE INDEX IF NOT EXISTS routes_status_idx ON routes(status);
CREATE INDEX IF NOT EXISTS routes_driver_status_idx ON routes(driver_id, status);
CREATE INDEX IF NOT EXISTS routes_collector_status_idx ON routes(collector_id, status);

-- Add missing columns to route_stops table
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS stop_order int;
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS point_name text;
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS completed_at timestamptz;
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS actual_weight_kg numeric(10,2);
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS photo_urls text[];
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS notes text;
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Rename seq to stop_order if exists
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'route_stops' AND column_name = 'seq') THEN
    ALTER TABLE route_stops RENAME COLUMN seq TO stop_order;
  END IF;
END $$;

-- Add status constraint for route_stops
ALTER TABLE route_stops DROP CONSTRAINT IF EXISTS route_stops_status_check;
ALTER TABLE route_stops ADD CONSTRAINT route_stops_status_check 
  CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped', 'failed'));

-- Create index for route stops ordering
CREATE INDEX IF NOT EXISTS route_stops_route_order_idx ON route_stops(route_id, stop_order);
CREATE INDEX IF NOT EXISTS route_stops_status_idx ON route_stops(status);

-- Update route_stops unique constraint
DROP INDEX IF EXISTS route_stops_uniq;
CREATE UNIQUE INDEX IF NOT EXISTS route_stops_route_order_uniq ON route_stops(route_id, stop_order);

-- Add trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_routes_updated_at ON routes;
CREATE TRIGGER update_routes_updated_at 
  BEFORE UPDATE ON routes 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_route_stops_updated_at ON route_stops;
CREATE TRIGGER update_route_stops_updated_at 
  BEFORE UPDATE ON route_stops 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Add function to calculate route progress
CREATE OR REPLACE FUNCTION calculate_route_progress(route_uuid uuid)
RETURNS TABLE (
  total_stops int,
  completed_stops int,
  pending_stops int,
  progress_percentage numeric
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::int as total_stops,
    COUNT(*) FILTER (WHERE status = 'completed')::int as completed_stops,
    COUNT(*) FILTER (WHERE status = 'pending')::int as pending_stops,
    CASE 
      WHEN COUNT(*) > 0 THEN 
        ROUND((COUNT(*) FILTER (WHERE status = 'completed')::numeric / COUNT(*)::numeric * 100), 2)
      ELSE 0
    END as progress_percentage
  FROM route_stops
  WHERE route_id = route_uuid;
END;
$$ LANGUAGE plpgsql;

-- Create view for worker routes with full details
CREATE OR REPLACE VIEW worker_routes_view AS
SELECT 
  r.id,
  r.name,
  r.vehicle_id,
  v.plate as vehicle_plate,
  v.type as vehicle_type,
  v.capacity_kg as vehicle_capacity,
  r.depot_id,
  d1.name as depot_name,
  ST_Y(d1.geom::geometry) as depot_lat,
  ST_X(d1.geom::geometry) as depot_lon,
  r.dump_id,
  d2.name as dump_name,
  ST_Y(d2.geom::geometry) as dump_lat,
  ST_X(d2.geom::geometry) as dump_lon,
  r.driver_id,
  p1.name as driver_name,
  p1.phone as driver_phone,
  r.collector_id,
  p2.name as collector_name,
  p2.phone as collector_phone,
  r.scheduled_date,
  r.start_at,
  r.end_at,
  r.status,
  r.planned_distance_km,
  r.planned_duration_min,
  r.actual_distance_km,
  r.actual_duration_min,
  r.total_weight_kg,
  r.meta,
  r.created_at,
  r.updated_at,
  (SELECT COUNT(*) FROM route_stops WHERE route_id = r.id) as total_stops,
  (SELECT COUNT(*) FROM route_stops WHERE route_id = r.id AND status = 'completed') as completed_stops
FROM routes r
LEFT JOIN vehicles v ON r.vehicle_id = v.id
LEFT JOIN depots d1 ON r.depot_id = d1.id
LEFT JOIN dumps d2 ON r.dump_id = d2.id
LEFT JOIN personnel p1 ON r.driver_id = p1.id
LEFT JOIN personnel p2 ON r.collector_id = p2.id;

COMMENT ON VIEW worker_routes_view IS 'Complete route information for worker app';
