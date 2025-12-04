-- Migration 027: Link route_stops to schedules via metadata
-- Purpose: Ensure route_stops can find their corresponding schedules for completion

-- 1. Add meta column to route_stops if not exists
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';

-- 2. Create function to link route_stops with schedules when route is created
CREATE OR REPLACE FUNCTION link_route_stops_to_schedules()
RETURNS trigger AS $$
BEGIN
  -- When a route_stop is created, try to find the corresponding schedule
  -- Match by route_id and location proximity
  UPDATE route_stops rs
  SET meta = jsonb_set(
    COALESCE(rs.meta, '{}'::jsonb),
    '{schedule_id}',
    to_jsonb(s.schedule_id::text)
  )
  FROM schedules s
  JOIN points p ON ST_DWithin(
    p.geom,
    ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
    50  -- Within 50 meters
  )
  WHERE rs.id = NEW.id
    AND rs.route_id = s.route_id
    AND rs.point_id = p.id
    AND s.status = 'assigned'
    AND rs.meta->>'schedule_id' IS NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create trigger to auto-link route_stops when created
DROP TRIGGER IF EXISTS trigger_link_route_stops ON route_stops;
CREATE TRIGGER trigger_link_route_stops
  AFTER INSERT ON route_stops
  FOR EACH ROW
  EXECUTE FUNCTION link_route_stops_to_schedules();

-- 4. Backfill existing route_stops with schedule links
UPDATE route_stops rs
SET meta = jsonb_set(
  COALESCE(rs.meta, '{}'::jsonb),
  '{schedule_id}',
  to_jsonb(s.schedule_id::text)
)
FROM schedules s
JOIN points p ON ST_DWithin(
  p.geom,
  ST_SetSRID(ST_MakePoint(s.longitude, s.latitude), 4326)::geography,
  50  -- Within 50 meters
)
WHERE rs.route_id = s.route_id
  AND rs.point_id = p.id
  AND s.status IN ('assigned', 'completed')
  AND rs.meta->>'schedule_id' IS NULL;

-- 5. Create view for route_stops with linked schedule info
CREATE OR REPLACE VIEW route_stops_with_schedules AS
SELECT 
  rs.*,
  (rs.meta->>'schedule_id')::uuid as schedule_id,
  s.citizen_id,
  s.waste_type,
  s.estimated_weight,
  s.scheduled_date,
  s.status as schedule_status,
  s.actual_weight,
  s.latitude as schedule_lat,
  s.longitude as schedule_lng,
  s.address,
  s.notes as schedule_notes,
  p.geom as point_geom,
  ST_Y(p.geom::geometry) as point_lat,
  ST_X(p.geom::geometry) as point_lng,
  u.profile->>'name' as citizen_name,
  u.phone as citizen_phone
FROM route_stops rs
LEFT JOIN schedules s ON (rs.meta->>'schedule_id')::uuid = s.schedule_id
LEFT JOIN points p ON rs.point_id = p.id
LEFT JOIN users u ON s.citizen_id = u.id::text;

-- 6. Add index for faster lookups
CREATE INDEX IF NOT EXISTS route_stops_meta_schedule_id_idx ON route_stops ((meta->>'schedule_id'));
CREATE INDEX IF NOT EXISTS schedules_route_id_status_idx ON schedules (route_id, status);

-- 7. Create function to check route completion status
CREATE OR REPLACE FUNCTION check_route_completion(route_uuid uuid)
RETURNS TABLE (
  total_stops int,
  completed_stops int,
  pending_stops int,
  skipped_stops int,
  can_complete boolean
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::int as total_stops,
    COUNT(*) FILTER (WHERE status = 'completed')::int as completed_stops,
    COUNT(*) FILTER (WHERE status = 'pending')::int as pending_stops,
    COUNT(*) FILTER (WHERE status = 'skipped')::int as skipped_stops,
    (COUNT(*) FILTER (WHERE status = 'pending') = 0) as can_complete
  FROM route_stops
  WHERE route_id = route_uuid;
END;
$$ LANGUAGE plpgsql;

-- 8. Add constraint: route cannot be completed if stops are pending
CREATE OR REPLACE FUNCTION validate_route_completion()
RETURNS trigger AS $$
DECLARE
  pending_count int;
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    -- Check if there are pending stops
    SELECT COUNT(*) INTO pending_count
    FROM route_stops
    WHERE route_id = NEW.id
      AND status = 'pending';
    
    IF pending_count > 0 THEN
      RAISE EXCEPTION 'Cannot complete route with % pending stops', pending_count;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_validate_route_completion ON routes;
CREATE TRIGGER trigger_validate_route_completion
  BEFORE UPDATE ON routes
  FOR EACH ROW
  EXECUTE FUNCTION validate_route_completion();

-- 9. Create helper function to get route completion progress
CREATE OR REPLACE FUNCTION get_route_progress(route_uuid uuid)
RETURNS jsonb AS $$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'route_id', route_uuid,
    'total_stops', COUNT(*),
    'completed_stops', COUNT(*) FILTER (WHERE status = 'completed'),
    'pending_stops', COUNT(*) FILTER (WHERE status = 'pending'),
    'skipped_stops', COUNT(*) FILTER (WHERE status = 'skipped'),
    'progress_percentage', ROUND(
      (COUNT(*) FILTER (WHERE status = 'completed')::decimal / COUNT(*)) * 100,
      2
    ),
    'can_complete', (COUNT(*) FILTER (WHERE status = 'pending') = 0),
    'stops', jsonb_agg(
      jsonb_build_object(
        'stop_id', id,
        'seq', seq,
        'status', status,
        'schedule_id', (meta->>'schedule_id')::uuid,
        'completed_at', completed_at
      ) ORDER BY seq
    )
  ) INTO result
  FROM route_stops
  WHERE route_id = route_uuid;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Migration complete
SELECT 
  COUNT(*) FILTER (WHERE meta->>'schedule_id' IS NOT NULL) as linked_stops,
  COUNT(*) FILTER (WHERE meta->>'schedule_id' IS NULL) as unlinked_stops,
  COUNT(*) as total_stops
FROM route_stops;
