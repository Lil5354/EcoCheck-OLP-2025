-- Migration 026: Seed Routes for All Active Drivers
-- This ensures all drivers have at least one planned route for testing

-- Clean up old test routes first
DELETE FROM route_stops WHERE route_id IN (
  SELECT id FROM routes WHERE name LIKE '%Test Mobile%'
);

DELETE FROM routes WHERE name LIKE '%Test Mobile%';

-- Create routes for each active driver
DO $$
DECLARE
  driver_record RECORD;
  route_id UUID;
  vehicle_id TEXT;
  depot_id UUID;
  dump_id UUID;
  point_record RECORD;
  stop_seq INT;
BEGIN
  -- Get default depot and dump
  SELECT id INTO depot_id FROM depots LIMIT 1;
  SELECT id INTO dump_id FROM dumps LIMIT 1;

  -- Loop through all active drivers
  FOR driver_record IN 
    SELECT id, name FROM personnel 
    WHERE role = 'driver' AND status = 'active'
    ORDER BY name
  LOOP
    -- Generate new route ID
    route_id := gen_random_uuid();
    
    -- Get first available vehicle
    SELECT id INTO vehicle_id FROM vehicles 
    WHERE status = 'available' 
    LIMIT 1 OFFSET (ABS(HASHTEXT(driver_record.id::TEXT)) % (SELECT COUNT(*)::INT FROM vehicles WHERE status = 'available'));
    
    -- Create route for this driver
    INSERT INTO routes (
      id,
      name,
      vehicle_id,
      driver_id,
      collector_id,
      depot_id,
      dump_id,
      status,
      scheduled_date,
      planned_distance_km,
      planned_duration_min,
      created_at,
      updated_at
    ) VALUES (
      route_id,
      'Lộ trình ngày ' || TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') || ' - ' || driver_record.name,
      vehicle_id,
      driver_record.id,
      (SELECT id FROM personnel WHERE role = 'collector' AND status = 'active' LIMIT 1),
      depot_id,
      dump_id,
      'planned',
      CURRENT_DATE,
      ROUND((RANDOM() * 20 + 10)::NUMERIC, 2), -- Random 10-30 km
      ROUND((RANDOM() * 120 + 60)::INT), -- Random 60-180 minutes
      NOW(),
      NOW()
    );
    
    -- Add 3-7 random stops for this route
    stop_seq := 0;
    FOR point_record IN 
      SELECT id, geom 
      FROM points 
      WHERE ghost = false 
      ORDER BY RANDOM() 
      LIMIT (3 + (ABS(HASHTEXT(route_id::TEXT)) % 5))
    LOOP
      stop_seq := stop_seq + 1;
      
      INSERT INTO route_stops (
        id,
        route_id,
        point_id,
        seq,
        stop_order,
        status,
        planned_eta,
        created_at
      ) VALUES (
        gen_random_uuid(),
        route_id,
        point_record.id,
        stop_seq,
        stop_seq,
        'pending',
        NOW() + (stop_seq * 15 || ' minutes')::INTERVAL,
        NOW()
      );
    END LOOP;
    
    RAISE NOTICE 'Created route % for driver % with % stops', route_id, driver_record.name, stop_seq;
  END LOOP;
END $$;

-- Update route statistics
UPDATE routes r
SET meta = jsonb_set(
  COALESCE(r.meta, '{}'::jsonb),
  '{total_stops}',
  (SELECT COUNT(*)::TEXT::jsonb FROM route_stops WHERE route_id = r.id)
)
WHERE r.scheduled_date = CURRENT_DATE;

-- Verify results
SELECT 
  p.name as driver_name,
  r.name as route_name,
  r.status,
  r.scheduled_date,
  COUNT(rs.id) as stops_count,
  r.planned_distance_km,
  v.plate as vehicle_plate
FROM routes r
INNER JOIN personnel p ON r.driver_id = p.id
LEFT JOIN vehicles v ON r.vehicle_id = v.id
LEFT JOIN route_stops rs ON r.id = rs.route_id
WHERE r.scheduled_date = CURRENT_DATE
GROUP BY p.name, r.name, r.status, r.scheduled_date, r.planned_distance_km, v.plate
ORDER BY p.name;
