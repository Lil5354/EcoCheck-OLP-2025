-- Migration: Seed Predictive Analytics Data
-- Description: Add historical schedules data (60 days) for testing predictive analytics
-- Version: 017
-- Date: 2025-01-28
-- MIT License - Copyright (c) 2025 Lil5354

BEGIN;

-- ============================================================================
-- SEED HISTORICAL SCHEDULES DATA (60 days) - Cho /api/analytics/predict
-- ============================================================================

-- Tạo dữ liệu schedules đã completed trong 60 ngày qua
-- Với trend tăng dần và variation để test linear regression

DO $$
DECLARE
  day_offset INTEGER;
  base_weight NUMERIC;
  base_total_tons NUMERIC;
  daily_total_tons NUMERIC;
  variation_tons NUMERIC;
  trend_weight NUMERIC;
  variation NUMERIC;
  daily_count INTEGER;
  schedule_date TIMESTAMPTZ;
  completed_date TIMESTAMPTZ;
  waste_types TEXT[] := ARRAY['household', 'recyclable', 'bulky', 'organic'];
  time_slots TEXT[] := ARRAY['morning', 'afternoon', 'evening'];
  user_rec RECORD;
  point_rec RECORD;
  i INTEGER;
  j INTEGER;
  schedule_id UUID;
BEGIN
  -- Lấy user và point để tạo schedules
  SELECT id INTO user_rec FROM users WHERE role = 'citizen' LIMIT 1;
  SELECT id INTO point_rec FROM points WHERE ghost = false LIMIT 1;
  
  -- Nếu chưa có user hoặc point, tạo tạm
  IF user_rec.id IS NULL THEN
    INSERT INTO users (id, phone, role, status)
    VALUES (gen_random_uuid(), '0900000000', 'citizen', 'active')
    RETURNING id INTO user_rec.id;
  END IF;
  
  IF point_rec.id IS NULL THEN
    INSERT INTO points (id, geom, ghost)
    VALUES (
      gen_random_uuid(),
      ST_GeogFromText('POINT(106.7 10.78)'),
      false
    )
    RETURNING id INTO point_rec.id;
  END IF;

  -- Tạo dữ liệu cho 60 ngày qua
  FOR day_offset IN 0..59 LOOP
    schedule_date := NOW() - (day_offset || ' days')::INTERVAL;
    completed_date := schedule_date + (8 + random() * 4)::INTEGER * INTERVAL '1 hour'; -- Completed 8-12h sau scheduled
    
    -- Tính TỔNG weight mỗi ngày với trend tăng RẤT RÕ RÀNG (từ 0.5 tấn -> 3.0 tấn trong 60 ngày)
    -- Đảm bảo trend rõ ràng cho linear regression
    -- day_offset = 0 (hôm nay) -> weight cao nhất, day_offset = 59 (60 ngày trước) -> weight thấp nhất
    base_total_tons := 3.0 - (day_offset * 0.0417); -- Trend: giảm 0.0417 tấn/ngày khi đi ngược về quá khứ (từ 3.0 -> 0.5 tấn)
    variation_tons := (random() - 0.5) * 0.08; -- Variation: ±0.04 tấn (giảm variation để trend rõ hơn)
    daily_total_tons := base_total_tons + variation_tons;
    
    daily_count := 20 + floor(random() * 15)::INTEGER; -- 20-35 schedules/ngày
    
    -- Weekly pattern: cuối tuần (thứ 7, CN) có weight cao hơn 20%
    IF EXTRACT(DOW FROM schedule_date) IN (0, 6) THEN
      daily_total_tons := daily_total_tons * 1.2;
      daily_count := daily_count + 5;
    END IF;
    
    -- Đảm bảo tổng weight không âm
    daily_total_tons := GREATEST(0.2, daily_total_tons);
    
    -- Tạo schedules cho ngày này
    FOR i IN 1..daily_count LOOP
      schedule_id := gen_random_uuid();
      
      -- Phân bổ weight cho từng schedule (tổng = daily_total_tons)
      -- Mỗi schedule có weight từ 5-50kg
      trend_weight := (daily_total_tons * 1000.0) / daily_count; -- Convert tons to kg
      trend_weight := trend_weight * (0.7 + random() * 0.6); -- Variation: 70%-130% của average
      trend_weight := GREATEST(5.0, LEAST(50.0, trend_weight)); -- Cap between 5-50kg per schedule
      
      INSERT INTO schedules (
        schedule_id,
        citizen_id,
        scheduled_date,
        time_slot,
        waste_type,
        estimated_weight,
        actual_weight,
        latitude,
        longitude,
        location,
        status,
        completed_at,
        created_at
      ) VALUES (
        schedule_id,
        user_rec.id::TEXT,
        schedule_date,
        time_slots[1 + floor(random() * 3)::INTEGER],
        waste_types[1 + floor(random() * 4)::INTEGER],
        trend_weight * 0.9, -- estimated thấp hơn actual một chút
        GREATEST(5.0, trend_weight), -- actual_weight, tối thiểu 5kg
        10.78 + (random() - 0.5) * 0.1,
        106.7 + (random() - 0.5) * 0.1,
        ST_GeogFromText('POINT(' || 
          (106.7 + (random() - 0.5) * 0.1)::TEXT || ' ' || 
          (10.78 + (random() - 0.5) * 0.1)::TEXT || 
        ')'),
        'completed',
        completed_date,
        schedule_date - INTERVAL '2 days' -- created 2 ngày trước scheduled
      );
    END LOOP;
    
    -- Log progress mỗi 10 ngày
    IF day_offset % 10 = 0 THEN
      RAISE NOTICE 'Created schedules for day -% (date: %)', day_offset, schedule_date::DATE;
    END IF;
  END LOOP;
  
  RAISE NOTICE '✅ Created historical schedules data for 60 days';
END $$;

-- ============================================================================
-- VERIFY DATA
-- ============================================================================

-- Kiểm tra số lượng schedules đã tạo
DO $$
DECLARE
  total_count INTEGER;
  completed_count INTEGER;
  date_range TEXT;
BEGIN
  SELECT COUNT(*) INTO total_count FROM schedules;
  SELECT COUNT(*) INTO completed_count FROM schedules WHERE status = 'completed' AND completed_at >= NOW() - INTERVAL '60 days';
  SELECT 
    MIN(completed_at)::DATE || ' to ' || MAX(completed_at)::DATE INTO date_range
  FROM schedules 
  WHERE status = 'completed' AND completed_at >= NOW() - INTERVAL '60 days';
  
  RAISE NOTICE '📊 Statistics:';
  RAISE NOTICE '   Total schedules: %', total_count;
  RAISE NOTICE '   Completed (60 days): %', completed_count;
  RAISE NOTICE '   Date range: %', date_range;
END $$;

-- Success message
SELECT 'Migration 017: Predictive analytics seed data completed successfully!' AS status;

COMMIT;

