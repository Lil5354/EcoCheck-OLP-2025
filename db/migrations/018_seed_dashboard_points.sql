-- Migration: Seed Dashboard Points Data
-- Description: Add diverse collection points for dashboard display
-- Version: 018
-- Date: 2025-01-28
-- MIT License - Copyright (c) 2025 Lil5354

BEGIN;

-- ============================================================================
-- SEED DASHBOARD POINTS - Cho bản đồ vận hành thời gian thực
-- ============================================================================

-- Tạo các điểm với đủ các loại:
-- 1. Ghost points (Không rác - Điểm ma) - Grey
-- 2. Rác ít/vừa (level < 0.7) - Green
-- 3. Rác nhiều (level >= 0.7, type != 'bulky') - Orange
-- 4. Rác cồng kềnh/Sự cố (type = 'bulky') - Red

DO $$
DECLARE
  point_id UUID;
  base_lat NUMERIC := 10.78; -- HCMC center
  base_lon NUMERIC := 106.7;
  i INTEGER;
  lat_offset NUMERIC;
  lon_offset NUMERIC;
  waste_type TEXT;
  waste_level NUMERIC;
  is_ghost BOOLEAN;
  checkin_time TIMESTAMPTZ;
BEGIN
  -- 1. Ghost points (Không rác - Grey) - 20 điểm
  FOR i IN 1..20 LOOP
    lat_offset := (random() - 0.5) * 0.2; -- ±0.1 độ (~11km)
    lon_offset := (random() - 0.5) * 0.2;
    point_id := gen_random_uuid();
    
    INSERT INTO points (
      id,
      address_id,
      geom,
      ghost,
      last_waste_type,
      last_level,
      last_checkin_at,
      total_checkins
    ) VALUES (
      point_id,
      NULL,
      ST_SetSRID(ST_MakePoint(base_lon + lon_offset, base_lat + lat_offset), 4326)::geography,
      true, -- Ghost point
      'household',
      0.0, -- Không rác
      NOW() - (random() * INTERVAL '7 days'), -- Check-in cũ
      floor(random() * 5)::INTEGER -- 0-4 checkins
    );
  END LOOP;
  
  RAISE NOTICE 'Created 20 ghost points (Grey - Không rác)';

  -- 2. Rác ít/vừa (Green) - 40 điểm
  FOR i IN 1..40 LOOP
    lat_offset := (random() - 0.5) * 0.2;
    lon_offset := (random() - 0.5) * 0.2;
    point_id := gen_random_uuid();
    waste_type := (ARRAY['household', 'recyclable', 'organic'])[1 + floor(random() * 3)::INTEGER];
    waste_level := 0.2 + random() * 0.45; -- 0.2 - 0.65 (ít/vừa)
    is_ghost := false;
    checkin_time := NOW() - (random() * INTERVAL '24 hours');
    
    INSERT INTO points (
      id,
      address_id,
      geom,
      ghost,
      last_waste_type,
      last_level,
      last_checkin_at,
      total_checkins
    ) VALUES (
      point_id,
      NULL,
      ST_SetSRID(ST_MakePoint(base_lon + lon_offset, base_lat + lat_offset), 4326)::geography,
      is_ghost,
      waste_type,
      waste_level,
      checkin_time,
      5 + floor(random() * 20)::INTEGER -- 5-24 checkins
    );
  END LOOP;
  
  RAISE NOTICE 'Created 40 points with low/medium waste (Green - Rác ít/vừa)';

  -- 3. Rác nhiều (Orange) - 30 điểm
  FOR i IN 1..30 LOOP
    lat_offset := (random() - 0.5) * 0.2;
    lon_offset := (random() - 0.5) * 0.2;
    point_id := gen_random_uuid();
    waste_type := (ARRAY['household', 'recyclable', 'organic'])[1 + floor(random() * 3)::INTEGER];
    waste_level := 0.7 + random() * 0.25; -- 0.7 - 0.95 (nhiều)
    is_ghost := false;
    checkin_time := NOW() - (random() * INTERVAL '12 hours'); -- Gần đây hơn
    
    INSERT INTO points (
      id,
      address_id,
      geom,
      ghost,
      last_waste_type,
      last_level,
      last_checkin_at,
      total_checkins
    ) VALUES (
      point_id,
      NULL,
      ST_SetSRID(ST_MakePoint(base_lon + lon_offset, base_lat + lat_offset), 4326)::geography,
      is_ghost,
      waste_type,
      waste_level,
      checkin_time,
      10 + floor(random() * 30)::INTEGER -- 10-39 checkins
    );
  END LOOP;
  
  RAISE NOTICE 'Created 30 points with high waste (Orange - Rác nhiều)';

  -- 4. Rác cồng kềnh/Sự cố (Red) - 15 điểm
  FOR i IN 1..15 LOOP
    lat_offset := (random() - 0.5) * 0.2;
    lon_offset := (random() - 0.5) * 0.2;
    point_id := gen_random_uuid();
    waste_type := 'bulky'; -- Cồng kềnh
    waste_level := 0.6 + random() * 0.4; -- 0.6 - 1.0
    is_ghost := false;
    checkin_time := NOW() - (random() * INTERVAL '6 hours'); -- Rất gần đây
    
    INSERT INTO points (
      id,
      address_id,
      geom,
      ghost,
      last_waste_type,
      last_level,
      last_checkin_at,
      total_checkins
    ) VALUES (
      point_id,
      NULL,
      ST_SetSRID(ST_MakePoint(base_lon + lon_offset, base_lat + lat_offset), 4326)::geography,
      is_ghost,
      waste_type,
      waste_level,
      checkin_time,
      3 + floor(random() * 10)::INTEGER -- 3-12 checkins
    );
  END LOOP;
  
  RAISE NOTICE 'Created 15 points with bulky waste (Red - Rác cồng kềnh/Sự cố)';

  -- 5. Thêm một số điểm có alert (sự cố) - Red
  -- Tạo alerts cho một số điểm bulky để hiển thị sự cố
  FOR i IN 1..5 LOOP
    INSERT INTO alerts (
      alert_id,
      alert_type,
      point_id,
      severity,
      status,
      created_at
    )
    SELECT
      nextval('alerts_alert_id_seq'),
      'missed_point',
      p.id,
      'critical',
      'open',
      NOW() - (random() * INTERVAL '2 hours')
    FROM points p
    WHERE p.last_waste_type = 'bulky'
      AND p.ghost = false
      AND NOT EXISTS (
        SELECT 1 FROM alerts a WHERE a.point_id = p.id AND a.status = 'open'
      )
    LIMIT 1;
  END LOOP;
  
  RAISE NOTICE 'Created 5 alerts for incident points (Red - Sự cố)';

  RAISE NOTICE '✅ Dashboard points seeding completed!';
  RAISE NOTICE '   Total points created: 105';
  RAISE NOTICE '   - Ghost (Grey): 20';
  RAISE NOTICE '   - Low/Medium (Green): 40';
  RAISE NOTICE '   - High (Orange): 30';
  RAISE NOTICE '   - Bulky/Incident (Red): 15';
END $$;

-- Success message
SELECT 'Migration 018: Dashboard points seed data completed successfully!' AS status;

COMMIT;

