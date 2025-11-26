-- 014_seed_test_alerts_and_exceptions.sql
-- Seed test data for Dynamic Dispatch (alerts) and Exceptions
-- MIT License - Copyright (c) 2025 Lil5354

BEGIN;

DO $$
DECLARE
  v_point_id uuid;
  v_vehicle_id text;
  v_route_id uuid;
  v_stop_id uuid;
  v_exception_id uuid;
BEGIN
  -- Get or create a point
  SELECT id INTO v_point_id FROM points LIMIT 1;
  IF v_point_id IS NULL THEN
    -- Create a test point if none exists
    INSERT INTO points (id, address_id, geom, ghost, last_waste_type, last_level, total_checkins)
    VALUES (
      uuid_generate_v4(),
      NULL,
      ST_SetSRID(ST_MakePoint(106.7, 10.78), 4326)::geography,
      false,
      'household',
      0.5,
      0
    )
    RETURNING id INTO v_point_id;
  END IF;

  -- Get or create a vehicle
  SELECT id INTO v_vehicle_id FROM vehicles LIMIT 1;
  IF v_vehicle_id IS NULL THEN
    INSERT INTO vehicles (id, plate, type, capacity_kg, status)
    VALUES ('VH000001', 'TEST-001', 'compactor', 5000, 'available')
    RETURNING id INTO v_vehicle_id;
  END IF;

  -- Get or create a route
  SELECT id INTO v_route_id FROM routes LIMIT 1;
  IF v_route_id IS NULL THEN
    INSERT INTO routes (id, vehicle_id, start_at, status)
    VALUES (uuid_generate_v4(), v_vehicle_id, NOW(), 'in_progress')
    RETURNING id INTO v_route_id;
  END IF;

  -- Get or create a route stop
  SELECT id INTO v_stop_id FROM route_stops WHERE route_id = v_route_id LIMIT 1;
  IF v_stop_id IS NULL THEN
    INSERT INTO route_stops (id, route_id, point_id, seq, status)
    VALUES (uuid_generate_v4(), v_route_id, v_point_id, 1, 'pending')
    RETURNING id INTO v_stop_id;
  END IF;

  -- Insert test alerts (if not exists)
  INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
  VALUES
    (
      'missed_point',
      v_point_id,
      v_vehicle_id,
      v_route_id,
      'critical',
      'open',
      jsonb_build_object('detected_at', NOW()::text, 'distance_m', 750)
    ),
    (
      'late_checkin',
      v_point_id,
      v_vehicle_id,
      v_route_id,
      'warning',
      'open',
      jsonb_build_object('detected_at', NOW()::text, 'delay_minutes', 15)
    )
  ON CONFLICT DO NOTHING;

  -- Insert test exceptions (if not exists)
  INSERT INTO exceptions (id, route_id, stop_id, type, reason, status, created_at)
  VALUES
    (
      uuid_generate_v4(),
      v_route_id,
      v_stop_id,
      'cannot_collect',
      'Đường bị chặn do công trình xây dựng',
      'pending',
      NOW() - INTERVAL '2 hours'
    ),
    (
      uuid_generate_v4(),
      v_route_id,
      v_stop_id,
      'road_blocked',
      'Đường bị kẹt xe, không thể tiếp cận điểm thu gom',
      'pending',
      NOW() - INTERVAL '1 hour'
    ),
    (
      uuid_generate_v4(),
      v_route_id,
      v_stop_id,
      'wrong_waste_type',
      'Người dân để sai loại rác, không đúng quy định',
      'pending',
      NOW() - INTERVAL '30 minutes'
    ),
    (
      uuid_generate_v4(),
      v_route_id,
      v_stop_id,
      'vehicle_breakdown',
      'Xe bị hỏng động cơ, cần hỗ trợ',
      'pending',
      NOW() - INTERVAL '15 minutes'
    )
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Inserted test alerts and exceptions. Point: %, Vehicle: %, Route: %', v_point_id, v_vehicle_id, v_route_id;
END $$;

COMMIT;

