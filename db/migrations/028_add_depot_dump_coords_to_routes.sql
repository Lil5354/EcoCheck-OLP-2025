-- Migration 028: Add depot and dump coordinates directly to routes table
-- This ensures the START/END markers on mobile match the actual VRP route start/end points
-- Previously, routes only stored depot_id/dump_id and joined to get coordinates,
-- but VRP uses vehicleStartLocation which may differ from depot location
-- MIT License - Copyright (c) 2025 Lil5354

-- Add columns for storing actual depot/dump coordinates used in route
ALTER TABLE routes 
  ADD COLUMN IF NOT EXISTS depot_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS depot_lon DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS dump_lat DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS dump_lon DOUBLE PRECISION;

-- Backfill existing routes with depot coordinates from depots table
UPDATE routes r
SET 
  depot_lat = COALESCE(d.lat, d.latitude),
  depot_lon = COALESCE(d.lon, d.longitude)
FROM depots d
WHERE r.depot_id = d.id 
  AND r.depot_lat IS NULL;

-- Note: dumps table may not exist in current schema, skip backfill for now

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS routes_depot_coords_idx ON routes(depot_lat, depot_lon) WHERE depot_lat IS NOT NULL;
CREATE INDEX IF NOT EXISTS routes_dump_coords_idx ON routes(dump_lat, dump_lon) WHERE dump_lat IS NOT NULL;

-- Add comments
COMMENT ON COLUMN routes.depot_lat IS 'Actual latitude of route start point (may differ from depot location)';
COMMENT ON COLUMN routes.depot_lon IS 'Actual longitude of route start point (may differ from depot location)';
COMMENT ON COLUMN routes.dump_lat IS 'Actual latitude of route end point (dump/landfill)';
COMMENT ON COLUMN routes.dump_lon IS 'Actual longitude of route end point (dump/landfill)';
