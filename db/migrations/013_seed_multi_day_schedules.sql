-- 013_seed_multi_day_schedules.sql
-- Seed test data for multiple days for route optimization testing
-- Creates schedules for multiple dates with proper coordinates in Ho Chi Minh City
-- MIT License - Copyright (c) 2025 Lil5354

BEGIN;

DO $$
DECLARE
  v_citizen_id uuid;
  v_citizen_id2 uuid;
  v_citizen_id3 uuid;
  v_citizen_id4 uuid;
  v_depot_id uuid;
  v_dump_id uuid;
  test_date date;
  i integer;
BEGIN
  -- Get or create citizen users
  SELECT id INTO v_citizen_id FROM users WHERE role = 'citizen' LIMIT 1;
  IF v_citizen_id IS NULL THEN
    INSERT INTO users (id, phone, email, role, status, profile)
    VALUES (uuid_generate_v4(), '0901111111', 'test_citizen1@test.com', 'citizen', 'active', '{"name": "Người dân Test 1"}'::jsonb)
    RETURNING id INTO v_citizen_id;
  END IF;

  SELECT id INTO v_citizen_id2 FROM users WHERE role = 'citizen' OFFSET 1 LIMIT 1;
  IF v_citizen_id2 IS NULL THEN
    INSERT INTO users (id, phone, email, role, status, profile)
    VALUES (uuid_generate_v4(), '0901111112', 'test_citizen2@test.com', 'citizen', 'active', '{"name": "Người dân Test 2"}'::jsonb)
    RETURNING id INTO v_citizen_id2;
  END IF;

  SELECT id INTO v_citizen_id3 FROM users WHERE role = 'citizen' OFFSET 2 LIMIT 1;
  IF v_citizen_id3 IS NULL THEN
    INSERT INTO users (id, phone, email, role, status, profile)
    VALUES (uuid_generate_v4(), '0901111113', 'test_citizen3@test.com', 'citizen', 'active', '{"name": "Người dân Test 3"}'::jsonb)
    RETURNING id INTO v_citizen_id3;
  END IF;

  SELECT id INTO v_citizen_id4 FROM users WHERE role = 'citizen' OFFSET 3 LIMIT 1;
  IF v_citizen_id4 IS NULL THEN
    INSERT INTO users (id, phone, email, role, status, profile)
    VALUES (uuid_generate_v4(), '0901111114', 'test_citizen4@test.com', 'citizen', 'active', '{"name": "Người dân Test 4"}'::jsonb)
    RETURNING id INTO v_citizen_id4;
  END IF;

  -- Get depot and dump IDs
  SELECT id INTO v_depot_id FROM depots WHERE name LIKE '%Bình Thạnh%' LIMIT 1;
  SELECT id INTO v_dump_id FROM dumps WHERE name LIKE '%Đa Phước%' LIMIT 1;

  -- Create schedules for multiple days (today + next 7 days)
  FOR i IN 0..7 LOOP
    test_date := CURRENT_DATE + (i || ' days')::interval;
    
    -- Insert 5-8 schedules per day
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
      -- Day schedules (different locations each day)
      (
        uuid_generate_v4(),
        CASE (i % 4) WHEN 0 THEN v_citizen_id WHEN 1 THEN v_citizen_id2 WHEN 2 THEN v_citizen_id3 ELSE v_citizen_id4 END,
        test_date,
        '18:00-20:00',
        'household',
        10.0 + (i * 0.5),
        10.7769 + (i * 0.001),  -- Slight variation in location
        106.6958 + (i * 0.001),
        '123 Nguyễn Huệ, Quận 1, TP.HCM - Ngày ' || to_char(test_date, 'DD/MM/YYYY'),
        'scheduled',
        0,
        NOW() - (i || ' days')::interval
      ),
      (
        uuid_generate_v4(),
        CASE ((i + 1) % 4) WHEN 0 THEN v_citizen_id WHEN 1 THEN v_citizen_id2 WHEN 2 THEN v_citizen_id3 ELSE v_citizen_id4 END,
        test_date,
        '18:00-20:00',
        'household',
        12.5 + (i * 0.3),
        10.783 + (i * 0.001),
        106.683 + (i * 0.001),
        '456 Võ Văn Tần, Quận 3, TP.HCM - Ngày ' || to_char(test_date, 'DD/MM/YYYY'),
        'scheduled',
        0,
        NOW() - (i || ' days')::interval
      ),
      (
        uuid_generate_v4(),
        CASE ((i + 2) % 4) WHEN 0 THEN v_citizen_id WHEN 1 THEN v_citizen_id2 WHEN 2 THEN v_citizen_id3 ELSE v_citizen_id4 END,
        test_date,
        '18:00-20:00',
        'recyclable',
        8.0 + (i * 0.4),
        10.8014 + (i * 0.001),
        106.7054 + (i * 0.001),
        '789 Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM - Ngày ' || to_char(test_date, 'DD/MM/YYYY'),
        'scheduled',
        1,
        NOW() - (i || ' days')::interval
      ),
      (
        uuid_generate_v4(),
        CASE ((i + 3) % 4) WHEN 0 THEN v_citizen_id WHEN 1 THEN v_citizen_id2 WHEN 2 THEN v_citizen_id3 ELSE v_citizen_id4 END,
        test_date,
        '20:00-22:00',
        'household',
        9.5 + (i * 0.2),
        10.795 + (i * 0.001),
        106.68 + (i * 0.001),
        '321 Phan Đăng Lưu, Phú Nhuận, TP.HCM - Ngày ' || to_char(test_date, 'DD/MM/YYYY'),
        'scheduled',
        0,
        NOW() - (i || ' days')::interval
      ),
      (
        uuid_generate_v4(),
        CASE (i % 4) WHEN 0 THEN v_citizen_id WHEN 1 THEN v_citizen_id2 WHEN 2 THEN v_citizen_id3 ELSE v_citizen_id4 END,
        test_date,
        '20:00-22:00',
        'bulky',
        20.0 + (i * 1.0),
        10.7992 + (i * 0.001),
        106.6297 + (i * 0.001),
        '654 Cộng Hòa, Tân Bình, TP.HCM - Ngày ' || to_char(test_date, 'DD/MM/YYYY'),
        'scheduled',
        2,
        NOW() - (i || ' days')::interval
      ),
      (
        uuid_generate_v4(),
        CASE ((i + 1) % 4) WHEN 0 THEN v_citizen_id WHEN 1 THEN v_citizen_id2 WHEN 2 THEN v_citizen_id3 ELSE v_citizen_id4 END,
        test_date,
        '18:00-20:00',
        'household',
        11.0 + (i * 0.3),
        10.775 + (i * 0.001),
        106.700 + (i * 0.001),
        '111 Đồng Khởi, Quận 1, TP.HCM - Ngày ' || to_char(test_date, 'DD/MM/YYYY'),
        'scheduled',
        0,
        NOW() - (i || ' days')::interval
      ),
      (
        uuid_generate_v4(),
        CASE ((i + 2) % 4) WHEN 0 THEN v_citizen_id WHEN 1 THEN v_citizen_id2 WHEN 2 THEN v_citizen_id3 ELSE v_citizen_id4 END,
        test_date,
        '18:00-20:00',
        'recyclable',
        7.5 + (i * 0.2),
        10.785 + (i * 0.001),
        106.690 + (i * 0.001),
        '222 Nguyễn Đình Chiểu, Quận 3, TP.HCM - Ngày ' || to_char(test_date, 'DD/MM/YYYY'),
        'scheduled',
        1,
        NOW() - (i || ' days')::interval
      ),
      (
        uuid_generate_v4(),
        CASE ((i + 3) % 4) WHEN 0 THEN v_citizen_id WHEN 1 THEN v_citizen_id2 WHEN 2 THEN v_citizen_id3 ELSE v_citizen_id4 END,
        test_date,
        '20:00-22:00',
        'household',
        13.0 + (i * 0.4),
        10.805 + (i * 0.001),
        106.710 + (i * 0.001),
        '333 Điện Biên Phủ, Bình Thạnh, TP.HCM - Ngày ' || to_char(test_date, 'DD/MM/YYYY'),
        'scheduled',
        0,
        NOW() - (i || ' days')::interval
      )
    ON CONFLICT (id) DO NOTHING;
    
    RAISE NOTICE 'Inserted schedules for date: %', test_date;
  END LOOP;

  RAISE NOTICE 'Inserted test schedules for multiple days. Citizens: %, %, %, %', v_citizen_id, v_citizen_id2, v_citizen_id3, v_citizen_id4;
END $$;

COMMIT;

