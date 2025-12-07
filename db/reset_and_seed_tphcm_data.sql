-- EcoCheck - Reset and Seed TPHCM Data
-- Xóa và seed lại dữ liệu đa dạng chỉ trong TPHCM
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- PHẦN 1: XÓA DỮ LIỆU CŨ (GIỮ SCHEMA)
-- ============================================================================

-- Xóa theo thứ tự để tránh foreign key constraints
TRUNCATE TABLE 
  route_stops,
  routes,
  schedules,
  incidents,
  checkins,
  points,
  user_addresses,
  user_badges,
  badges,
  point_transactions,
  user_points,
  user_bills,
  billing_cycles,
  system_logs,
  vehicle_tracking,
  exceptions,
  sensors_observations,
  sensors,
  groups,
  personnel,
  vehicles,
  users,
  dumps,
  depots
CASCADE;

-- Reset sequences nếu có
-- ALTER SEQUENCE IF EXISTS ... RESTART WITH 1;

-- ============================================================================
-- PHẦN 2: SEED MASTER DATA (TPHCM)
-- ============================================================================

-- DEPOTS (Trạm thu gom) - Chỉ trong TPHCM
INSERT INTO depots (id, name, geom, address, capacity_vehicles, opening_hours, status, created_at) VALUES
  (gen_random_uuid(), 'Trạm Thu Gom Quận 1', ST_SetSRID(ST_MakePoint(106.6958, 10.7769), 4326)::geography, '123 Nguyễn Huệ, Quận 1, TP.HCM', 15, '18:00-06:00', 'active', NOW()),
  (gen_random_uuid(), 'Trạm Thu Gom Quận 3', ST_SetSRID(ST_MakePoint(106.6830, 10.7830), 4326)::geography, '456 Võ Văn Tần, Quận 3, TP.HCM', 12, '18:00-06:00', 'active', NOW()),
  (gen_random_uuid(), 'Trạm Thu Gom Bình Thạnh', ST_SetSRID(ST_MakePoint(106.7054, 10.8014), 4326)::geography, '789 Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM', 10, '18:00-06:00', 'active', NOW()),
  (gen_random_uuid(), 'Trạm Thu Gom Tân Bình', ST_SetSRID(ST_MakePoint(106.6297, 10.7992), 4326)::geography, '321 Cộng Hòa, Tân Bình, TP.HCM', 8, '18:00-06:00', 'active', NOW()),
  (gen_random_uuid(), 'Trạm Thu Gom Phú Nhuận', ST_SetSRID(ST_MakePoint(106.6800, 10.7950), 4326)::geography, '654 Phan Đăng Lưu, Phú Nhuận, TP.HCM', 10, '18:00-06:00', 'active', NOW()),
  (gen_random_uuid(), 'Trạm Thu Gom Quận 7', ST_SetSRID(ST_MakePoint(106.7219, 10.7314), 4326)::geography, '789 Nguyễn Thị Thập, Quận 7, TP.HCM', 10, '18:00-06:00', 'active', NOW()),
  (gen_random_uuid(), 'Trạm Thu Gom Quận 10', ST_SetSRID(ST_MakePoint(106.6674, 10.7736), 4326)::geography, '456 Lý Thái Tổ, Quận 10, TP.HCM', 8, '18:00-06:00', 'active', NOW());

-- DUMPS (Bãi rác) - Chỉ trong TPHCM
INSERT INTO dumps (id, name, geom, address, accepted_waste_types, capacity_tons, opening_hours, status, created_at) VALUES
  (gen_random_uuid(), 'Bãi Rác Đa Phước', ST_SetSRID(ST_MakePoint(106.5500, 10.8500), 4326)::geography, 'Xã Phước Kiển, Huyện Nhà Bè, TP.HCM', 
   ARRAY['household', 'recyclable', 'bulky'], 5000.00, '18:00-06:00', 'active', NOW()),
  (gen_random_uuid(), 'Trạm Trung Chuyển Gò Cát', ST_SetSRID(ST_MakePoint(106.7200, 10.8100), 4326)::geography, 'Đường Gò Cát, Phú Hữu, Quận 9, TP.HCM', 
   ARRAY['household', 'recyclable'], 2000.00, '00:00-24:00', 'active', NOW()),
  (gen_random_uuid(), 'Trạm Trung Chuyển Tân Sơn Nhất', ST_SetSRID(ST_MakePoint(106.6500, 10.8200), 4326)::geography, 'Gần Sân Bay Tân Sơn Nhất, Tân Bình, TP.HCM', 
   ARRAY['household', 'recyclable', 'bulky'], 1500.00, '00:00-24:00', 'active', NOW());

-- VEHICLES (Phương tiện)
INSERT INTO vehicles (id, plate, type, capacity_kg, accepted_types, fuel_type, status, depot_id, current_load_kg, created_at) VALUES
  ('VH001', '51A-12345', 'compactor', 5000, ARRAY['household', 'recyclable'], 'diesel', 'available', (SELECT id FROM depots LIMIT 1), 0, NOW()),
  ('VH002', '51B-23456', 'compactor', 5000, ARRAY['household', 'recyclable'], 'diesel', 'in_use', (SELECT id FROM depots LIMIT 1), 2500, NOW()),
  ('VH003', '51C-34567', 'compactor', 6000, ARRAY['household', 'recyclable', 'bulky'], 'diesel', 'available', (SELECT id FROM depots OFFSET 1 LIMIT 1), 0, NOW()),
  ('VH004', '51D-45678', 'compactor', 5500, ARRAY['household'], 'hybrid', 'available', (SELECT id FROM depots OFFSET 2 LIMIT 1), 0, NOW()),
  ('VH005', '51E-56789', 'mini-truck', 2000, ARRAY['household', 'bulky'], 'diesel', 'available', (SELECT id FROM depots OFFSET 3 LIMIT 1), 0, NOW()),
  ('VH006', '51F-67890', 'mini-truck', 2500, ARRAY['household', 'recyclable'], 'diesel', 'in_use', (SELECT id FROM depots OFFSET 1 LIMIT 1), 1200, NOW()),
  ('VH007', '51G-78901', 'mini-truck', 1800, ARRAY['bulky'], 'diesel', 'available', (SELECT id FROM depots OFFSET 2 LIMIT 1), 0, NOW()),
  ('VH008', '51H-89012', 'electric-trike', 500, ARRAY['recyclable'], 'electric', 'available', (SELECT id FROM depots LIMIT 1), 0, NOW()),
  ('VH009', '51I-90123', 'electric-trike', 600, ARRAY['recyclable', 'household'], 'electric', 'available', (SELECT id FROM depots OFFSET 1 LIMIT 1), 0, NOW()),
  ('VH010', '51K-01234', 'electric-trike', 550, ARRAY['recyclable'], 'electric', 'in_use', (SELECT id FROM depots OFFSET 3 LIMIT 1), 200, NOW()),
  ('VH011', '51L-12346', 'specialized', 8000, ARRAY['bulky'], 'diesel', 'available', (SELECT id FROM depots OFFSET 2 LIMIT 1), 0, NOW()),
  ('VH012', '51M-23457', 'specialized', 3000, ARRAY['hazardous'], 'diesel', 'available', (SELECT id FROM depots OFFSET 4 LIMIT 1), 0, NOW());

-- PERSONNEL (Nhân sự)
INSERT INTO personnel (id, name, role, phone, email, certifications, status, depot_id, created_at) VALUES
  (gen_random_uuid(), 'Nguyễn Văn An', 'driver', '0901234567', 'nguyenvanan@ecocheck.vn', ARRAY['B2', 'C'], 'active', (SELECT id FROM depots LIMIT 1), NOW()),
  (gen_random_uuid(), 'Trần Văn Bình', 'driver', '0902345678', 'tranvanbinh@ecocheck.vn', ARRAY['B2', 'C'], 'active', (SELECT id FROM depots LIMIT 1), NOW()),
  (gen_random_uuid(), 'Lê Văn Cường', 'driver', '0903456789', 'levancuong@ecocheck.vn', ARRAY['B2'], 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1), NOW()),
  (gen_random_uuid(), 'Phạm Văn Dũng', 'driver', '0904567890', 'phamvandung@ecocheck.vn', ARRAY['B2', 'C'], 'active', (SELECT id FROM depots OFFSET 2 LIMIT 1), NOW()),
  (gen_random_uuid(), 'Hoàng Văn Em', 'driver', '0905678901', 'hoangvanem@ecocheck.vn', ARRAY['B2'], 'active', (SELECT id FROM depots OFFSET 3 LIMIT 1), NOW()),
  (gen_random_uuid(), 'Trần Thị Bình', 'collector', '0906789012', 'tranthib@ecocheck.vn', ARRAY['waste_handling'], 'active', (SELECT id FROM depots LIMIT 1), NOW()),
  (gen_random_uuid(), 'Phạm Thị Dung', 'collector', '0907890123', 'phamthidung@ecocheck.vn', ARRAY['waste_handling'], 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1), NOW()),
  (gen_random_uuid(), 'Nguyễn Thị Hoa', 'collector', '0908901234', 'nguyenthihoa@ecocheck.vn', ARRAY['waste_handling', 'recycling'], 'active', (SELECT id FROM depots OFFSET 2 LIMIT 1), NOW()),
  (gen_random_uuid(), 'Lê Thị Kim', 'collector', '0909012345', 'lethikim@ecocheck.vn', ARRAY['waste_handling'], 'active', (SELECT id FROM depots OFFSET 3 LIMIT 1), NOW()),
  (gen_random_uuid(), 'Võ Văn Phong', 'manager', '0910123456', 'vovanphong@ecocheck.vn', ARRAY['management', 'logistics'], 'active', (SELECT id FROM depots LIMIT 1), NOW()),
  (gen_random_uuid(), 'Đặng Thị Quỳnh', 'manager', '0911234567', 'dangthiquynh@ecocheck.vn', ARRAY['management'], 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1), NOW()),
  (gen_random_uuid(), 'Võ Thị Phương', 'dispatcher', '0912345678', 'vothiphuong@ecocheck.vn', ARRAY['dispatch', 'route_planning'], 'active', (SELECT id FROM depots LIMIT 1), NOW()),
  (gen_random_uuid(), 'Trương Văn Sơn', 'dispatcher', '0913456789', 'truongvanson@ecocheck.vn', ARRAY['dispatch'], 'active', (SELECT id FROM depots OFFSET 2 LIMIT 1), NOW());

-- USERS (Người dân) - Tạo nhiều users để test
INSERT INTO users (id, phone, email, role, status, profile, created_at) VALUES
  (gen_random_uuid(), '0911111111', 'user1@example.com', 'citizen', 'active', '{"name": "Nguyễn Văn A"}'::jsonb, NOW()),
  (gen_random_uuid(), '0922222222', 'user2@example.com', 'citizen', 'active', '{"name": "Trần Thị B"}'::jsonb, NOW()),
  (gen_random_uuid(), '0933333333', 'user3@example.com', 'citizen', 'active', '{"name": "Lê Văn C"}'::jsonb, NOW()),
  (gen_random_uuid(), '0944444444', 'user4@example.com', 'citizen', 'active', '{"name": "Phạm Thị D"}'::jsonb, NOW()),
  (gen_random_uuid(), '0955555555', 'user5@example.com', 'citizen', 'active', '{"name": "Hoàng Văn E"}'::jsonb, NOW()),
  (gen_random_uuid(), '0966666666', 'user6@example.com', 'citizen', 'active', '{"name": "Võ Thị F"}'::jsonb, NOW()),
  (gen_random_uuid(), '0977777777', 'user7@example.com', 'citizen', 'active', '{"name": "Đặng Văn G"}'::jsonb, NOW()),
  (gen_random_uuid(), '0988888888', 'user8@example.com', 'citizen', 'active', '{"name": "Trương Thị H"}'::jsonb, NOW()),
  (gen_random_uuid(), '0999999999', 'user9@example.com', 'citizen', 'active', '{"name": "Phan Văn I"}'::jsonb, NOW()),
  (gen_random_uuid(), '0900000000', 'user10@example.com', 'citizen', 'active', '{"name": "Ngô Thị K"}'::jsonb, NOW()),
  (gen_random_uuid(), '0912345678', 'doanduong@example.com', 'citizen', 'active', '{"name": "doanduong"}'::jsonb, NOW()),
  (gen_random_uuid(), '0912345679', 'anhdoan@example.com', 'citizen', 'active', '{"name": "anh doan"}'::jsonb, NOW());

-- USER_ADDRESSES (Địa chỉ người dân) - Chỉ trong TPHCM
INSERT INTO user_addresses (id, user_id, label, geom, address_text, is_default, created_at)
SELECT 
  gen_random_uuid(),
  u.id,
  'Nhà riêng',
  ST_SetSRID(ST_MakePoint(
    106.6 + (random() * 0.2),  -- lon: 106.6-106.8 (TPHCM)
    10.7 + (random() * 0.2)    -- lat: 10.7-10.9 (TPHCM)
  ), 4326)::geography,
  CASE (ROW_NUMBER() OVER ())
    WHEN 1 THEN '123 Đường Nguyễn Huệ, Quận 1, TP.HCM'
    WHEN 2 THEN '456 Đường Lê Lợi, Quận 1, TP.HCM'
    WHEN 3 THEN '789 Đường Pasteur, Quận 3, TP.HCM'
    WHEN 4 THEN '321 Đường Cộng Hòa, Tân Bình, TP.HCM'
    WHEN 5 THEN '654 Đường Phan Đăng Lưu, Phú Nhuận, TP.HCM'
    WHEN 6 THEN '987 Đường Nguyễn Thị Thập, Quận 7, TP.HCM'
    WHEN 7 THEN '111 Đường Lý Thái Tổ, Quận 10, TP.HCM'
    WHEN 8 THEN '222 Đường Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM'
    WHEN 9 THEN '333 Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM'
    WHEN 10 THEN '444 Đường Nguyễn Văn Cừ, Quận 5, TP.HCM'
    WHEN 11 THEN '555 Đường Võ Văn Tần, Quận 3, TP.HCM'
    WHEN 12 THEN '666 Đường Trường Chinh, Tân Bình, TP.HCM'
    ELSE 'Đường ' || (ROW_NUMBER() OVER ()) || ', Quận ' || (1 + (ROW_NUMBER() OVER () % 12)) || ', TP.HCM'
  END,
  true,
  NOW()
FROM users u
WHERE u.role = 'citizen'
ORDER BY u.created_at;

-- POINTS (Điểm thu gom) - Chỉ trong TPHCM
INSERT INTO points (id, address_id, geom, ghost, last_waste_type, last_level, last_checkin_at, total_checkins, created_at)
SELECT 
  gen_random_uuid(),
  ua.id,
  ua.geom,
  false,
  CASE (ROW_NUMBER() OVER () % 5)
    WHEN 0 THEN 'household'
    WHEN 1 THEN 'recyclable'
    WHEN 2 THEN 'bulky'
    WHEN 3 THEN 'organic'
    ELSE 'hazardous'
  END,
  (random() * 0.8 + 0.1)::numeric(3,2),  -- 0.1-0.9
  NOW() - (random() * INTERVAL '7 days'),
  (random() * 50)::int,
  NOW() - (random() * INTERVAL '30 days')
FROM user_addresses ua
LIMIT 30;

-- ============================================================================
-- PHẦN 3: SEED SCHEDULES (Lịch thu gom) - ĐA DẠNG STATUS
-- ============================================================================

-- Schedules với các status khác nhau, chỉ trong TPHCM
DO $$
DECLARE
  citizen_rec RECORD;
  employee_rec RECORD;
  today_date DATE := CURRENT_DATE;
  schedule_id_val UUID;
  lat_val DECIMAL(10,8);
  lon_val DECIMAL(11,8);
  address_val TEXT;
  waste_types TEXT[] := ARRAY['household', 'recyclable', 'bulky', 'organic', 'hazardous'];
  time_slots TEXT[] := ARRAY['morning', 'afternoon', 'evening'];
  statuses TEXT[] := ARRAY['pending', 'scheduled', 'assigned', 'in_progress', 'completed'];
  i INT;
  status_val TEXT;
  time_slot_val TEXT;
  waste_type_val TEXT;
BEGIN
  -- Lấy danh sách citizens
  FOR citizen_rec IN SELECT id FROM users WHERE role = 'citizen' LIMIT 20
  LOOP
    -- Tạo 2-5 schedules cho mỗi citizen
    FOR i IN 1..(2 + (random() * 3)::int)
    LOOP
      schedule_id_val := gen_random_uuid();
      
      -- Random location trong TPHCM
      lat_val := 10.7 + (random() * 0.2);  -- 10.7-10.9
      lon_val := 106.6 + (random() * 0.2); -- 106.6-106.8
      
      -- Random address trong TPHCM
      address_val := CASE (random() * 12)::int
        WHEN 0 THEN '123 Đường Nguyễn Huệ, Quận 1, TP.HCM'
        WHEN 1 THEN '456 Đường Lê Lợi, Quận 1, TP.HCM'
        WHEN 2 THEN '789 Đường Pasteur, Quận 3, TP.HCM'
        WHEN 3 THEN '321 Đường Cộng Hòa, Tân Bình, TP.HCM'
        WHEN 4 THEN '654 Đường Phan Đăng Lưu, Phú Nhuận, TP.HCM'
        WHEN 5 THEN '987 Đường Nguyễn Thị Thập, Quận 7, TP.HCM'
        WHEN 6 THEN '111 Đường Lý Thái Tổ, Quận 10, TP.HCM'
        WHEN 7 THEN '222 Đường Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM'
        WHEN 8 THEN '333 Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM'
        WHEN 9 THEN '444 Đường Nguyễn Văn Cừ, Quận 5, TP.HCM'
        WHEN 10 THEN '555 Đường Võ Văn Tần, Quận 3, TP.HCM'
        ELSE '666 Đường Trường Chinh, Tân Bình, TP.HCM'
      END;
      
      -- Random waste type, time slot, status
      waste_type_val := waste_types[1 + (random() * array_length(waste_types, 1))::int];
      time_slot_val := time_slots[1 + (random() * array_length(time_slots, 1))::int];
      status_val := statuses[1 + (random() * array_length(statuses, 1))::int];
      
      -- Lấy employee nếu status là assigned hoặc in_progress hoặc completed
      IF status_val IN ('assigned', 'in_progress', 'completed') THEN
        SELECT id INTO employee_rec FROM personnel WHERE role IN ('driver', 'collector') AND status = 'active' ORDER BY RANDOM() LIMIT 1;
      ELSE
        employee_rec := NULL;
      END IF;
      
      -- Insert schedule
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
        address,
        location,
        status,
        employee_id,
        priority,
        notes,
        photo_urls,
        created_at,
        updated_at,
        completed_at
      ) VALUES (
        schedule_id_val,
        citizen_rec.id::TEXT,
        today_date + (random() * 7)::int * INTERVAL '1 day',  -- Trong 7 ngày tới
        time_slot_val,
        waste_type_val,
        (random() * 30 + 5)::numeric(10,2),  -- 5-35 kg
        CASE WHEN status_val = 'completed' THEN (random() * 35 + 6)::numeric(10,2) ELSE NULL END,
        lat_val,
        lon_val,
        address_val,
        ST_SetSRID(ST_MakePoint(lon_val, lat_val), 4326)::geography,
        status_val,
        employee_rec.id,
        (random() * 5)::int,  -- priority 0-4
        CASE WHEN random() > 0.7 THEN 'Ghi chú: ' || waste_type_val ELSE NULL END,
        CASE WHEN random() > 0.5 THEN ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'] ELSE NULL END,
        NOW() - (random() * 3)::int * INTERVAL '1 day',
        NOW() - (random() * 1)::int * INTERVAL '1 day',
        CASE WHEN status_val = 'completed' THEN NOW() - (random() * 2)::int * INTERVAL '1 hour' ELSE NULL END
      );
    END LOOP;
  END LOOP;
END $$;

-- ============================================================================
-- PHẦN 4: SEED INCIDENTS (Báo cáo) - ĐA DẠNG CATEGORY VÀ STATUS
-- ============================================================================

DO $$
DECLARE
  citizen_rec RECORD;
  personnel_rec RECORD;
  incident_id_val UUID;
  lat_val DECIMAL(10,8);
  lon_val DECIMAL(11,8);
  address_val TEXT;
  violation_types TEXT[] := ARRAY['illegal_dump', 'wrong_classification', 'overloaded_bin', 'littering', 'burning_waste'];
  damage_types TEXT[] := ARRAY['broken_bin', 'damaged_equipment', 'road_damage', 'facility_damage'];
  priorities TEXT[] := ARRAY['low', 'medium', 'high', 'urgent'];
  statuses TEXT[] := ARRAY['pending', 'open', 'in_progress', 'resolved', 'closed'];
  i INT;
  category_val TEXT;
  type_val TEXT;
  priority_val TEXT;
  status_val TEXT;
  reporter_id_val TEXT;
  reporter_name_val TEXT;
  reporter_phone_val TEXT;
BEGIN
  -- Tạo incidents từ citizens
  FOR citizen_rec IN SELECT id, phone, profile FROM users WHERE role = 'citizen' LIMIT 15
  LOOP
    FOR i IN 1..(1 + (random() * 3)::int)  -- 1-4 incidents mỗi citizen
    LOOP
      incident_id_val := gen_random_uuid();
      
      -- Random location trong TPHCM
      lat_val := 10.7 + (random() * 0.2);
      lon_val := 106.6 + (random() * 0.2);
      
      -- Random address
      address_val := CASE (random() * 12)::int
        WHEN 0 THEN '123 Đường Nguyễn Huệ, Quận 1, TP.HCM'
        WHEN 1 THEN '456 Đường Lê Lợi, Quận 1, TP.HCM'
        WHEN 2 THEN '789 Đường Pasteur, Quận 3, TP.HCM'
        WHEN 3 THEN '321 Đường Cộng Hòa, Tân Bình, TP.HCM'
        WHEN 4 THEN '654 Đường Phan Đăng Lưu, Phú Nhuận, TP.HCM'
        WHEN 5 THEN '987 Đường Nguyễn Thị Thập, Quận 7, TP.HCM'
        WHEN 6 THEN '111 Đường Lý Thái Tổ, Quận 10, TP.HCM'
        WHEN 7 THEN '222 Đường Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM'
        WHEN 8 THEN '333 Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM'
        WHEN 9 THEN '444 Đường Nguyễn Văn Cừ, Quận 5, TP.HCM'
        WHEN 10 THEN '555 Đường Võ Văn Tần, Quận 3, TP.HCM'
        ELSE '666 Đường Trường Chinh, Tân Bình, TP.HCM'
      END;
      
      -- Random category (70% violation, 30% damage)
      IF random() < 0.7 THEN
        category_val := 'violation';
        type_val := violation_types[1 + (random() * array_length(violation_types, 1))::int];
      ELSE
        category_val := 'damage';
        type_val := damage_types[1 + (random() * array_length(damage_types, 1))::int];
      END IF;
      
      priority_val := priorities[1 + (random() * array_length(priorities, 1))::int];
      status_val := statuses[1 + (random() * array_length(statuses, 1))::int];
      
      -- Lấy assigned_to nếu status không phải pending
      IF status_val != 'pending' THEN
        SELECT id INTO personnel_rec FROM personnel WHERE status = 'active' ORDER BY RANDOM() LIMIT 1;
      ELSE
        personnel_rec := NULL;
      END IF;
      
      reporter_id_val := citizen_rec.id::TEXT;
      reporter_name_val := COALESCE(citizen_rec.profile->>'name', 'Người dùng');
      reporter_phone_val := citizen_rec.phone;
      
      INSERT INTO incidents (
        id,
        reporter_id,
        reporter_name,
        reporter_phone,
        report_category,
        type,
        description,
        latitude,
        longitude,
        location_address,
        image_urls,
        priority,
        status,
        assigned_to,
        resolution_notes,
        resolved_at,
        created_at,
        updated_at
      ) VALUES (
        incident_id_val,
        reporter_id_val,
        reporter_name_val,
        reporter_phone_val,
        category_val,
        type_val,
        CASE category_val
          WHEN 'violation' THEN 'Báo cáo vi phạm: ' || type_val || ' tại ' || address_val
          ELSE 'Báo cáo hư hỏng: ' || type_val || ' tại ' || address_val
        END,
        lat_val,
        lon_val,
        address_val,
        ARRAY[
          'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400',
          'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'
        ],
        priority_val,
        status_val,
        personnel_rec.id,
        CASE WHEN status_val IN ('resolved', 'closed') THEN 'Đã xử lý xong' ELSE NULL END,
        CASE WHEN status_val IN ('resolved', 'closed') THEN NOW() - (random() * 2)::int * INTERVAL '1 day' ELSE NULL END,
        NOW() - (random() * 7)::int * INTERVAL '1 day',  -- Tạo trong 7 ngày qua
        NOW() - (random() * 1)::int * INTERVAL '1 day'
      );
    END LOOP;
  END LOOP;
END $$;

-- ============================================================================
-- PHẦN 5: SEED ROUTES (Tuyến đường) - ACTIVE ROUTES
-- ============================================================================

DO $$
DECLARE
  driver_rec RECORD;
  route_id_val UUID;
  vehicle_id_val TEXT;
  depot_id_val UUID;
  dump_id_val UUID;
  collector_id_val UUID;
  i INT;
BEGIN
  -- Lấy default depot và dump
  SELECT id INTO depot_id_val FROM depots LIMIT 1;
  SELECT id INTO dump_id_val FROM dumps LIMIT 1;
  
  -- Tạo routes cho các drivers
  FOR driver_rec IN 
    SELECT id, name FROM personnel 
    WHERE role = 'driver' AND status = 'active'
    LIMIT 10
  LOOP
    route_id_val := gen_random_uuid();
    
    -- Lấy vehicle available
    SELECT id INTO vehicle_id_val FROM vehicles 
    WHERE status IN ('available', 'in_use')
    ORDER BY RANDOM() 
    LIMIT 1;
    
    -- Lấy collector
    SELECT id INTO collector_id_val FROM personnel 
    WHERE role = 'collector' AND status = 'active'
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Insert route
    INSERT INTO routes (
      id,
      vehicle_id,
      depot_id,
      dump_id,
      start_at,
      end_at,
      status,
      meta,
      created_at
    ) VALUES (
      route_id_val,
      vehicle_id_val,
      depot_id_val,
      dump_id_val,
      NOW() - INTERVAL '2 hours',
      CASE WHEN random() > 0.5 THEN NOW() + INTERVAL '2 hours' ELSE NULL END,
      CASE (random() * 3)::int
        WHEN 0 THEN 'planned'
        WHEN 1 THEN 'in_progress'
        ELSE 'completed'
      END,
      '{}'::jsonb,
      NOW() - (random() * 2)::int * INTERVAL '1 day'
    );
    
    -- Thêm route_stops (3-7 stops)
    FOR i IN 1..(3 + (random() * 5)::int)
    LOOP
      INSERT INTO route_stops (
        id,
        route_id,
        point_id,
        seq,
        planned_eta,
        status,
        actual_at,
        created_at
      )
      SELECT
        gen_random_uuid(),
        route_id_val,
        p.id,
        i,
        NOW() + (i * 15 || ' minutes')::INTERVAL,
        CASE (random() * 3)::int
          WHEN 0 THEN 'pending'
          WHEN 1 THEN 'in_progress'
          ELSE 'completed'
        END,
        CASE WHEN random() > 0.5 THEN NOW() - ((4 - i) * 15 || ' minutes')::INTERVAL ELSE NULL END,
        NOW()
      FROM points p
      WHERE p.ghost = false
      ORDER BY RANDOM()
      LIMIT 1;
    END LOOP;
  END LOOP;
END $$;

-- ============================================================================
-- PHẦN 6: SEED CHECKINS (Check-in rác)
-- ============================================================================

INSERT INTO checkins (id, user_id, point_id, waste_type, filling_level, geom, photo_url, source, verified, created_at)
SELECT
  gen_random_uuid(),
  u.id,
  p.id,
  CASE (random() * 5)::int
    WHEN 0 THEN 'household'
    WHEN 1 THEN 'recyclable'
    WHEN 2 THEN 'bulky'
    WHEN 3 THEN 'organic'
    ELSE 'hazardous'
  END,
  (random() * 0.9 + 0.1)::numeric(3,2),  -- 0.1-1.0
  p.geom,
  'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400',
  CASE (random() * 3)::int
    WHEN 0 THEN 'mobile_app'
    WHEN 1 THEN 'web'
    ELSE 'api'
  END,
  random() > 0.3,  -- 70% verified
  NOW() - (random() * 7)::int * INTERVAL '1 day'
FROM users u
CROSS JOIN points p
WHERE u.role = 'citizen'
  AND p.ghost = false
LIMIT 50;

-- ============================================================================
-- PHẦN 7: SUMMARY
-- ============================================================================

SELECT '✅ Reset and seed TPHCM data completed!' AS message;

SELECT 
  'depots' as table_name, COUNT(*) as count FROM depots
UNION ALL SELECT 'dumps', COUNT(*) FROM dumps
UNION ALL SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL SELECT 'personnel', COUNT(*) FROM personnel
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'user_addresses', COUNT(*) FROM user_addresses
UNION ALL SELECT 'points', COUNT(*) FROM points
UNION ALL SELECT 'schedules', COUNT(*) FROM schedules
UNION ALL SELECT 'incidents', COUNT(*) FROM incidents
UNION ALL SELECT 'routes', COUNT(*) FROM routes
UNION ALL SELECT 'route_stops', COUNT(*) FROM route_stops
UNION ALL SELECT 'checkins', COUNT(*) FROM checkins
ORDER BY count DESC;

