-- 011_seed_collection_schedules.sql
-- Seed test data for collection_schedules table
-- MIT License - Copyright (c) 2025 Lil5354

BEGIN;

-- Get a citizen user (or create one if none exists)
DO $$
DECLARE
  v_citizen_id uuid;
  v_citizen_id2 uuid;
  v_citizen_id3 uuid;
BEGIN
  -- Try to get existing citizen users
  SELECT id INTO v_citizen_id FROM users WHERE role = 'citizen' LIMIT 1;
  SELECT id INTO v_citizen_id2 FROM users WHERE role = 'citizen' OFFSET 1 LIMIT 1;
  SELECT id INTO v_citizen_id3 FROM users WHERE role = 'citizen' OFFSET 2 LIMIT 1;
  
  -- If no citizen exists, create test citizens
  IF v_citizen_id IS NULL THEN
    INSERT INTO users (id, phone, email, role, status, profile)
    VALUES 
      (uuid_generate_v4(), '0901234567', 'citizen1@test.com', 'citizen', 'active', '{"name": "Nguyễn Văn A"}'::jsonb)
    RETURNING id INTO v_citizen_id;
  END IF;
  
  IF v_citizen_id2 IS NULL THEN
    INSERT INTO users (id, phone, email, role, status, profile)
    VALUES 
      (uuid_generate_v4(), '0901234568', 'citizen2@test.com', 'citizen', 'active', '{"name": "Trần Thị B"}'::jsonb)
    RETURNING id INTO v_citizen_id2;
  END IF;
  
  IF v_citizen_id3 IS NULL THEN
    INSERT INTO users (id, phone, email, role, status, profile)
    VALUES 
      (uuid_generate_v4(), '0901234569', 'citizen3@test.com', 'citizen', 'active', '{"name": "Lê Văn C"}'::jsonb)
    RETURNING id INTO v_citizen_id3;
  END IF;
  
  -- Insert test collection schedules
  INSERT INTO collection_schedules (
    id,
    citizen_id,
    scheduled_date,
    time_slot,
    waste_type,
    estimated_weight_kg,
    latitude,
    longitude,
    address,
    status,
    priority,
    notes,
    created_at
  ) VALUES
    -- Pending schedules (chờ xử lý)
    (
      uuid_generate_v4(),
      v_citizen_id,
      CURRENT_DATE + INTERVAL '1 day',
      '18:00-20:00',
      'household',
      15.5,
      10.762622,
      106.660172,
      '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
      'pending',
      0,
      'Rác sinh hoạt hàng ngày',
      NOW() - INTERVAL '2 hours'
    ),
    (
      uuid_generate_v4(),
      v_citizen_id2,
      CURRENT_DATE + INTERVAL '2 days',
      '20:00-22:00',
      'recyclable',
      8.2,
      10.775658,
      106.700409,
      '456 Đường Lê Lợi, Quận 1, TP.HCM',
      'pending',
      1,
      'Rác tái chế: giấy, nhựa, kim loại',
      NOW() - INTERVAL '1 hour'
    ),
    -- Scheduled schedules (đã lên lịch)
    (
      uuid_generate_v4(),
      v_citizen_id3,
      CURRENT_DATE + INTERVAL '3 days',
      '18:00-20:00',
      'bulky',
      25.0,
      10.790000,
      106.720000,
      '789 Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
      'scheduled',
      2,
      'Đồ nội thất cũ: ghế, bàn',
      NOW() - INTERVAL '5 hours'
    ),
    (
      uuid_generate_v4(),
      v_citizen_id,
      CURRENT_DATE + INTERVAL '1 day',
      '20:00-22:00',
      'household',
      12.3,
      10.762622,
      106.660172,
      '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
      'scheduled',
      0,
      NULL,
      NOW() - INTERVAL '3 hours'
    ),
    -- Assigned schedules (đã gán nhân viên)
    (
      uuid_generate_v4(),
      v_citizen_id2,
      CURRENT_DATE,
      '18:00-20:00',
      'household',
      10.0,
      10.775658,
      106.700409,
      '456 Đường Lê Lợi, Quận 1, TP.HCM',
      'assigned',
      1,
      'Đã gán cho nhân viên thu gom',
      NOW() - INTERVAL '1 day'
    ),
    -- In progress schedules (đang thực hiện)
    (
      uuid_generate_v4(),
      v_citizen_id3,
      CURRENT_DATE,
      '20:00-22:00',
      'recyclable',
      7.5,
      10.790000,
      106.720000,
      '789 Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
      'in_progress',
      2,
      'Nhân viên đang trên đường đến',
      NOW() - INTERVAL '2 days'
    ),
    -- Completed schedules (hoàn thành)
    (
      uuid_generate_v4(),
      v_citizen_id,
      CURRENT_DATE - INTERVAL '1 day',
      '18:00-20:00',
      'household',
      18.2,
      10.762622,
      106.660172,
      '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
      'completed',
      0,
      'Đã thu gom thành công',
      NOW() - INTERVAL '3 days'
    ),
    (
      uuid_generate_v4(),
      v_citizen_id2,
      CURRENT_DATE - INTERVAL '2 days',
      '20:00-22:00',
      'organic',
      5.8,
      10.775658,
      106.700409,
      '456 Đường Lê Lợi, Quận 1, TP.HCM',
      'completed',
      1,
      'Rác hữu cơ đã được xử lý',
      NOW() - INTERVAL '4 days'
    ),
    -- Cancelled schedules (đã hủy)
    (
      uuid_generate_v4(),
      v_citizen_id3,
      CURRENT_DATE + INTERVAL '5 days',
      '18:00-20:00',
      'household',
      20.0,
      10.790000,
      106.720000,
      '789 Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
      'cancelled',
      0,
      'Người dân đã hủy yêu cầu',
      NOW() - INTERVAL '6 days'
    ),
    -- Missed schedules (bỏ lỡ)
    (
      uuid_generate_v4(),
      v_citizen_id,
      CURRENT_DATE - INTERVAL '3 days',
      '18:00-20:00',
      'household',
      15.0,
      10.762622,
      106.660172,
      '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
      'missed',
      0,
      'Không có nhân viên đến thu gom',
      NOW() - INTERVAL '5 days'
    )
  ON CONFLICT (id) DO NOTHING;
  
  RAISE NOTICE 'Inserted test collection schedules for citizens: %, %, %', v_citizen_id, v_citizen_id2, v_citizen_id3;
END $$;

COMMIT;

