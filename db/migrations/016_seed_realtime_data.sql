-- Migration: Seed Realtime Data for Testing
-- Description: Add recent checkins and vehicle tracking data for realtime endpoints
-- Version: 016
-- Date: 2025-01-28
-- MIT License - Copyright (c) 2025 Lil5354

BEGIN;

-- ============================================================================
-- RECENT CHECKINS (24 giờ qua) - Cho /api/rt/checkins
-- ============================================================================

-- Tạo thêm checkins gần đây (24h qua) từ các points đã có
-- Chỉ tạo nếu chưa có đủ checkins gần đây
DO $$
DECLARE
  recent_checkins_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO recent_checkins_count
  FROM checkins
  WHERE created_at >= NOW() - INTERVAL '24 hours';
  
  -- Nếu chưa có đủ 60 checkins gần đây, tạo thêm
  IF recent_checkins_count < 60 THEN
    INSERT INTO checkins (id, user_id, point_id, waste_type, filling_level, geom, photo_url, source, verified, created_at)
    SELECT 
      uuid_generate_v4(),
      u.id,
      p.id,
      COALESCE(p.last_waste_type, 'household'),
      COALESCE(p.last_level, 0.5 + random() * 0.4),
      p.geom,
      'https://storage.ecocheck.vn/photos/checkin_' || LPAD((ROW_NUMBER() OVER())::text, 3, '0') || '.jpg',
      'mobile_app',
      CASE WHEN random() < 0.8 THEN true ELSE false END,
      NOW() - (random() * INTERVAL '24 hours')
    FROM points p
    CROSS JOIN LATERAL (
      SELECT id FROM users WHERE role = 'citizen' ORDER BY random() LIMIT 1
    ) u
    WHERE p.ghost = false
      AND p.last_waste_type IS NOT NULL
      AND p.last_level IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM checkins c 
        WHERE c.point_id = p.id 
        AND c.created_at >= NOW() - INTERVAL '24 hours'
      )
    LIMIT (60 - recent_checkins_count);
    
    RAISE NOTICE 'Created % additional recent checkins', (60 - recent_checkins_count);
  END IF;
END $$;

-- ============================================================================
-- VEHICLE TRACKING DATA - Cho /api/rt/vehicles
-- ============================================================================

-- Tạo tracking data cho các vehicles đang hoạt động
-- Chỉ tạo nếu chưa có tracking data gần đây
DO $$
DECLARE
  recent_tracking_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO recent_tracking_count
  FROM vehicle_tracking
  WHERE recorded_at >= NOW() - INTERVAL '1 hour';
  
  -- Nếu chưa có tracking data gần đây, tạo mới
  IF recent_tracking_count < 10 THEN
    -- Tạo tracking data cho vehicles đang hoạt động
    INSERT INTO vehicle_tracking (id, vehicle_id, route_id, geom, speed_kmh, heading, accuracy_m, battery_level, recorded_at)
    SELECT 
      uuid_generate_v4(),
      v.id,
      r.id,
      -- Vị trí ngẫu nhiên trong khu vực HCM (hoặc dùng depot location nếu có)
      COALESCE(
        ST_GeogFromText('POINT(' || 
          (106.63 + random() * 0.15)::text || ' ' || 
          (10.72 + random() * 0.14)::text || 
        ')'),
        d.geom
      ),
      -- Speed: 0-50 km/h
      20 + (random() * 30)::numeric(5,2),
      -- Heading: 0-360 độ
      (random() * 360)::numeric(5,2),
      -- Accuracy: 5-20m
      10 + (random() * 15)::numeric(10,2),
      -- Battery: 50-100%
      70 + (random() * 30)::int,
      -- Recorded trong 1 giờ qua
      NOW() - (random() * INTERVAL '1 hour')
    FROM vehicles v
    LEFT JOIN routes r ON r.vehicle_id = v.id AND r.status = 'in_progress'
    LEFT JOIN depots d ON d.id = v.depot_id
    WHERE v.status IN ('available', 'in_use')
      AND NOT EXISTS (
        SELECT 1 FROM vehicle_tracking vt 
        WHERE vt.vehicle_id = v.id 
        AND vt.recorded_at >= NOW() - INTERVAL '1 hour'
      )
    LIMIT 20;
    
    RAISE NOTICE 'Created vehicle tracking data for active vehicles';
  END IF;
  
  -- Tạo thêm tracking data lịch sử (để có nhiều điểm hơn cho demo)
  INSERT INTO vehicle_tracking (id, vehicle_id, route_id, geom, speed_kmh, heading, accuracy_m, recorded_at)
  SELECT 
    uuid_generate_v4(),
    v.id,
    NULL,
    COALESCE(
      ST_GeogFromText('POINT(' || 
        (106.63 + random() * 0.15)::text || ' ' || 
        (10.72 + random() * 0.14)::text || 
      ')'),
      d.geom
    ),
    15 + (random() * 35)::numeric(5,2),
    (random() * 360)::numeric(5,2),
    8 + (random() * 12)::numeric(10,2),
    NOW() - (random() * INTERVAL '6 hours')
  FROM vehicles v
  LEFT JOIN depots d ON d.id = v.depot_id
  WHERE v.status IN ('available', 'in_use')
    AND NOT EXISTS (
      SELECT 1 FROM vehicle_tracking vt 
      WHERE vt.vehicle_id = v.id 
      AND vt.recorded_at >= NOW() - INTERVAL '6 hours'
    )
  LIMIT 50;
  
  RAISE NOTICE 'Created historical vehicle tracking data';
END $$;

-- Success message
SELECT 'Migration 016: Realtime seed data completed successfully!' AS status;

COMMIT;

