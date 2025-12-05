-- Migration 028: Backfill depot_lat/lon and dump_lat/lon for existing routes
-- This ensures all routes have proper START/END coordinates for mobile app

-- Update depot coordinates from depots table for routes that don't have them
UPDATE routes r
SET 
  depot_lat = d.latitude,
  depot_lon = d.longitude
FROM depots d
WHERE r.depot_id = d.id
  AND (r.depot_lat IS NULL OR r.depot_lon IS NULL);

-- Log results
DO $$
DECLARE
  updated_count INT;
BEGIN
  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RAISE NOTICE 'Updated % routes with depot coordinates', updated_count;
END $$;

-- Verify results
SELECT 
  COUNT(*) as total_routes,
  COUNT(depot_lat) as routes_with_depot_lat,
  COUNT(depot_lon) as routes_with_depot_lon
FROM routes;
