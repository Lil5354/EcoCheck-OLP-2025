-- 012_seed_test_schedules_for_optimization.sql
-- Seed test data for route optimization testing
-- Creates schedules for 2025-11-26 with proper coordinates in Ho Chi Minh City
-- MIT License - Copyright (c) 2025 Lil5354

BEGIN;

DO $$
DECLARE
  v_citizen_id uuid;
  v_depot_id uuid;
  v_dump_id uuid;
BEGIN
  -- Get or create a citizen user
  SELECT id INTO v_citizen_id FROM users WHERE role = 'citizen' LIMIT 1;
  IF v_citizen_id IS NULL THEN
    INSERT INTO users (id, phone, email, role, status, profile)
    VALUES (uuid_generate_v4(), '0901111111', 'test_citizen@test.com', 'citizen', 'active', '{"name": "Người dân Test"}'::jsonb)
    RETURNING id INTO v_citizen_id;
  END IF;

  -- Get depot and dump IDs
  SELECT id INTO v_depot_id FROM depots WHERE name LIKE '%Bình Thạnh%' LIMIT 1;
  SELECT id INTO v_dump_id FROM dumps WHERE name LIKE '%Đa Phước%' LIMIT 1;

  -- Insert test schedules for 2025-11-26 (scheduled status for optimization)
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
    created_at
  ) VALUES
    -- Schedule 1: Quận 1
    (
      uuid_generate_v4(),
      v_citizen_id,
      '2025-11-26',
      '18:00-20:00',
      'household',
      12.5,
      10.7769,
      106.6958,
      '123 Nguyễn Huệ, Quận 1, TP.HCM',
      'scheduled',
      0,
      NOW()
    ),
    -- Schedule 2: Quận 3
    (
      uuid_generate_v4(),
      v_citizen_id,
      '2025-11-26',
      '18:00-20:00',
      'household',
      15.0,
      10.783,
      106.683,
      '456 Võ Văn Tần, Quận 3, TP.HCM',
      'scheduled',
      0,
      NOW()
    ),
    -- Schedule 3: Bình Thạnh
    (
      uuid_generate_v4(),
      v_citizen_id,
      '2025-11-26',
      '18:00-20:00',
      'recyclable',
      8.5,
      10.8014,
      106.7054,
      '789 Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM',
      'scheduled',
      1,
      NOW()
    ),
    -- Schedule 4: Phú Nhuận
    (
      uuid_generate_v4(),
      v_citizen_id,
      '2025-11-26',
      '20:00-22:00',
      'household',
      10.0,
      10.795,
      106.68,
      '321 Phan Đăng Lưu, Phú Nhuận, TP.HCM',
      'scheduled',
      0,
      NOW()
    ),
    -- Schedule 5: Tân Bình
    (
      uuid_generate_v4(),
      v_citizen_id,
      '2025-11-26',
      '20:00-22:00',
      'bulky',
      25.0,
      10.7992,
      106.6297,
      '654 Cộng Hòa, Tân Bình, TP.HCM',
      'scheduled',
      2,
      NOW()
    ),
    -- Schedule 6: Quận 1 (thêm điểm gần)
    (
      uuid_generate_v4(),
      v_citizen_id,
      '2025-11-26',
      '18:00-20:00',
      'household',
      9.5,
      10.775,
      106.700,
      '111 Đồng Khởi, Quận 1, TP.HCM',
      'scheduled',
      0,
      NOW()
    ),
    -- Schedule 7: Quận 3 (thêm điểm gần)
    (
      uuid_generate_v4(),
      v_citizen_id,
      '2025-11-26',
      '18:00-20:00',
      'recyclable',
      7.0,
      10.785,
      106.690,
      '222 Nguyễn Đình Chiểu, Quận 3, TP.HCM',
      'scheduled',
      1,
      NOW()
    ),
    -- Schedule 8: Bình Thạnh (thêm điểm)
    (
      uuid_generate_v4(),
      v_citizen_id,
      '2025-11-26',
      '20:00-22:00',
      'household',
      11.0,
      10.805,
      106.710,
      '333 Điện Biên Phủ, Bình Thạnh, TP.HCM',
      'scheduled',
      0,
      NOW()
    )
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Inserted test schedules for 2025-11-26. Citizen: %, Depot: %, Dump: %', v_citizen_id, v_depot_id, v_dump_id;
END $$;

COMMIT;

