-- EcoCheck - Enhanced Seed Data
-- Comprehensive test data for development and testing
-- MIT License - Copyright (c) 2025 Lil5354

-- Clear existing data (optional - uncomment if needed for fresh start)
-- TRUNCATE TABLE user_badges, badges, point_transactions, user_points, user_bills, billing_cycles, 
--   system_logs, vehicle_tracking, exceptions, incidents, checkins, route_stops, routes, 
--   points, user_addresses, users, personnel, vehicles, dumps, depots CASCADE;

-- ============================================================================
-- ENHANCED DEPOTS (Trạm thu gom)
-- ============================================================================

INSERT INTO depots (id, name, geom, address, capacity_vehicles, opening_hours, status) VALUES
  (uuid_generate_v4(), 'Trạm Thu Gom Quận 1', ST_GeogFromText('POINT(106.6958 10.7769)'), '123 Nguyễn Huệ, Quận 1, TP.HCM', 15, '18:00-06:00', 'active'),
  (uuid_generate_v4(), 'Trạm Thu Gom Quận 3', ST_GeogFromText('POINT(106.6830 10.7830)'), '456 Võ Văn Tần, Quận 3, TP.HCM', 12, '18:00-06:00', 'active'),
  (uuid_generate_v4(), 'Trạm Thu Gom Bình Thạnh', ST_GeogFromText('POINT(106.7054 10.8014)'), '789 Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM', 10, '18:00-06:00', 'active'),
  (uuid_generate_v4(), 'Trạm Thu Gom Tân Bình', ST_GeogFromText('POINT(106.6297 10.7992)'), '321 Cộng Hòa, Tân Bình, TP.HCM', 8, '18:00-06:00', 'active'),
  (uuid_generate_v4(), 'Trạm Thu Gom Phú Nhuận', ST_GeogFromText('POINT(106.6800 10.7950)'), '654 Phan Đăng Lưu, Phú Nhuận, TP.HCM', 10, '18:00-06:00', 'active')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- ENHANCED DUMPS (Bãi rác / Trạm trung chuyển)
-- ============================================================================

INSERT INTO dumps (id, name, geom, address, accepted_waste_types, capacity_tons, opening_hours, status) VALUES
  (uuid_generate_v4(), 'Bãi Rác Đa Phước', ST_GeogFromText('POINT(106.5500 10.8500)'), 'Xã Phước Kiển, Huyện Nhà Bè, TP.HCM', 
   ARRAY['household', 'recyclable', 'bulky'], 5000.00, '18:00-06:00', 'active'),
  (uuid_generate_v4(), 'Trạm Trung Chuyển Gò Cát', ST_GeogFromText('POINT(106.7200 10.8100)'), 'Đường Gò Cát, Phú Hữu, Quận 9, TP.HCM', 
   ARRAY['household', 'recyclable'], 2000.00, '00:00-24:00', 'active'),
  (uuid_generate_v4(), 'Trạm Trung Chuyển Tân Sơn Nhất', ST_GeogFromText('POINT(106.6500 10.8200)'), 'Gần Sân Bay Tân Sơn Nhất, Tân Bình, TP.HCM', 
   ARRAY['household', 'recyclable', 'bulky'], 1500.00, '00:00-24:00', 'active'),
  (uuid_generate_v4(), 'Trạm Tái Chế Bình Triệu', ST_GeogFromText('POINT(106.7300 10.8300)'), 'Khu Công Nghiệp Bình Triệu, Thủ Đức, TP.HCM', 
   ARRAY['recyclable'], 800.00, '06:00-22:00', 'active')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- ENHANCED VEHICLES (Phương tiện thu gom)
-- ============================================================================

INSERT INTO vehicles (id, plate, type, capacity_kg, accepted_types, fuel_type, status, depot_id, current_load_kg) VALUES
  -- Compactor trucks (Xe ép rác)
  ('VH001', '51A-12345', 'compactor', 5000, ARRAY['household', 'recyclable'], 'diesel', 'available', (SELECT id FROM depots LIMIT 1), 0),
  ('VH002', '51B-23456', 'compactor', 5000, ARRAY['household', 'recyclable'], 'diesel', 'available', (SELECT id FROM depots LIMIT 1), 0),
  ('VH003', '51C-34567', 'compactor', 6000, ARRAY['household', 'recyclable', 'bulky'], 'diesel', 'in_use', (SELECT id FROM depots OFFSET 1 LIMIT 1), 2500),
  ('VH004', '51D-45678', 'compactor', 5500, ARRAY['household'], 'hybrid', 'available', (SELECT id FROM depots OFFSET 2 LIMIT 1), 0),
  
  -- Mini trucks (Xe tải nhỏ)
  ('VH005', '51E-56789', 'mini-truck', 2000, ARRAY['household', 'bulky'], 'diesel', 'available', (SELECT id FROM depots OFFSET 3 LIMIT 1), 0),
  ('VH006', '51F-67890', 'mini-truck', 2500, ARRAY['household', 'recyclable'], 'diesel', 'in_use', (SELECT id FROM depots OFFSET 1 LIMIT 1), 1200),
  ('VH007', '51G-78901', 'mini-truck', 1800, ARRAY['bulky'], 'diesel', 'available', (SELECT id FROM depots OFFSET 2 LIMIT 1), 0),
  
  -- Electric trikes (Xe ba gác điện)
  ('VH008', '51H-89012', 'electric-trike', 500, ARRAY['recyclable'], 'electric', 'available', (SELECT id FROM depots LIMIT 1), 0),
  ('VH009', '51I-90123', 'electric-trike', 600, ARRAY['recyclable', 'household'], 'electric', 'available', (SELECT id FROM depots OFFSET 1 LIMIT 1), 0),
  ('VH010', '51K-01234', 'electric-trike', 550, ARRAY['recyclable'], 'electric', 'in_use', (SELECT id FROM depots OFFSET 3 LIMIT 1), 200),
  
  -- Specialized vehicles (Xe chuyên dụng)
  ('VH011', '51L-12346', 'specialized', 8000, ARRAY['bulky'], 'diesel', 'available', (SELECT id FROM depots OFFSET 2 LIMIT 1), 0),
  ('VH012', '51M-23457', 'specialized', 3000, ARRAY['hazardous'], 'diesel', 'available', (SELECT id FROM depots OFFSET 4 LIMIT 1), 0)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- ENHANCED PERSONNEL (Nhân sự)
-- ============================================================================

INSERT INTO personnel (id, name, role, phone, email, certifications, status, depot_id) VALUES
  -- Drivers
  (uuid_generate_v4(), 'Nguyễn Văn An', 'driver', '0901234567', 'nguyenvanan@ecocheck.vn', ARRAY['B2', 'C'], 'active', (SELECT id FROM depots LIMIT 1)),
  (uuid_generate_v4(), 'Trần Văn Bình', 'driver', '0902345678', 'tranvanbinh@ecocheck.vn', ARRAY['B2', 'C'], 'active', (SELECT id FROM depots LIMIT 1)),
  (uuid_generate_v4(), 'Lê Văn Cường', 'driver', '0903456789', 'levancuong@ecocheck.vn', ARRAY['B2'], 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1)),
  (uuid_generate_v4(), 'Phạm Văn Dũng', 'driver', '0904567890', 'phamvandung@ecocheck.vn', ARRAY['B2', 'C'], 'active', (SELECT id FROM depots OFFSET 2 LIMIT 1)),
  (uuid_generate_v4(), 'Hoàng Văn Em', 'driver', '0905678901', 'hoangvanem@ecocheck.vn', ARRAY['B2'], 'active', (SELECT id FROM depots OFFSET 3 LIMIT 1)),
  
  -- Collectors
  (uuid_generate_v4(), 'Trần Thị Bình', 'collector', '0906789012', 'tranthib@ecocheck.vn', ARRAY['waste_handling'], 'active', (SELECT id FROM depots LIMIT 1)),
  (uuid_generate_v4(), 'Phạm Thị Dung', 'collector', '0907890123', 'phamthidung@ecocheck.vn', ARRAY['waste_handling'], 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1)),
  (uuid_generate_v4(), 'Nguyễn Thị Hoa', 'collector', '0908901234', 'nguyenthihoa@ecocheck.vn', ARRAY['waste_handling', 'recycling'], 'active', (SELECT id FROM depots OFFSET 2 LIMIT 1)),
  (uuid_generate_v4(), 'Lê Thị Kim', 'collector', '0909012345', 'lethikim@ecocheck.vn', ARRAY['waste_handling'], 'active', (SELECT id FROM depots OFFSET 3 LIMIT 1)),
  
  -- Managers
  (uuid_generate_v4(), 'Võ Văn Phong', 'manager', '0910123456', 'vovanphong@ecocheck.vn', ARRAY['management', 'logistics'], 'active', (SELECT id FROM depots LIMIT 1)),
  (uuid_generate_v4(), 'Đặng Thị Quỳnh', 'manager', '0911234567', 'dangthiquynh@ecocheck.vn', ARRAY['management'], 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1)),
  
  -- Dispatchers
  (uuid_generate_v4(), 'Võ Thị Phương', 'dispatcher', '0912345678', 'vothiphuong@ecocheck.vn', ARRAY['dispatch', 'route_planning'], 'active', (SELECT id FROM depots LIMIT 1)),
  (uuid_generate_v4(), 'Trương Văn Sơn', 'dispatcher', '0913456789', 'truongvanson@ecocheck.vn', ARRAY['dispatch'], 'active', (SELECT id FROM depots OFFSET 2 LIMIT 1)),
  
  -- Supervisors
  (uuid_generate_v4(), 'Phan Văn Tài', 'supervisor', '0914567890', 'phanvantai@ecocheck.vn', ARRAY['supervision', 'quality_control'], 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1)),
  (uuid_generate_v4(), 'Ngô Thị Uyên', 'supervisor', '0915678901', 'ngothiuyen@ecocheck.vn', ARRAY['supervision'], 'active', (SELECT id FROM depots OFFSET 3 LIMIT 1))
ON CONFLICT DO NOTHING;

-- ============================================================================
-- ENHANCED USERS (Người dùng - Người dân)
-- ============================================================================

INSERT INTO users (id, phone, email, vneid, role, status, profile) VALUES
  -- Regular citizens
  (uuid_generate_v4(), '0911111111', 'user1@example.com', 'VN001', 'citizen', 'active', '{"name": "Nguyễn Văn A", "age": 35}'::jsonb),
  (uuid_generate_v4(), '0922222222', 'user2@example.com', 'VN002', 'citizen', 'active', '{"name": "Trần Thị B", "age": 28}'::jsonb),
  (uuid_generate_v4(), '0933333333', 'user3@example.com', 'VN003', 'citizen', 'active', '{"name": "Lê Văn C", "age": 42}'::jsonb),
  (uuid_generate_v4(), '0944444444', 'user4@example.com', 'VN004', 'citizen', 'active', '{"name": "Phạm Thị D", "age": 31}'::jsonb),
  (uuid_generate_v4(), '0955555555', 'user5@example.com', 'VN005', 'citizen', 'active', '{"name": "Hoàng Văn E", "age": 38}'::jsonb),
  (uuid_generate_v4(), '0966666666', 'user6@example.com', 'VN006', 'citizen', 'active', '{"name": "Võ Thị F", "age": 25}'::jsonb),
  (uuid_generate_v4(), '0977777777', 'user7@example.com', 'VN007', 'citizen', 'active', '{"name": "Đặng Văn G", "age": 45}'::jsonb),
  (uuid_generate_v4(), '0988888888', 'user8@example.com', 'VN008', 'citizen', 'active', '{"name": "Trương Thị H", "age": 33}'::jsonb),
  (uuid_generate_v4(), '0999999999', 'user9@example.com', 'VN009', 'citizen', 'active', '{"name": "Phan Văn I", "age": 29}'::jsonb),
  (uuid_generate_v4(), '0900000000', 'user10@example.com', 'VN010', 'citizen', 'active', '{"name": "Ngô Thị K", "age": 36}'::jsonb),
  
  -- Worker accounts
  (uuid_generate_v4(), '0901234567', 'worker1@ecocheck.vn', 'WK001', 'worker', 'active', '{"name": "Nguyễn Văn An"}'::jsonb),
  (uuid_generate_v4(), '0903456789', 'worker2@ecocheck.vn', 'WK002', 'worker', 'active', '{"name": "Lê Văn Cường"}'::jsonb),
  
  -- Manager accounts
  (uuid_generate_v4(), '0910123456', 'manager1@ecocheck.vn', 'MG001', 'manager', 'active', '{"name": "Võ Văn Phong"}'::jsonb),
  (uuid_generate_v4(), '0911234567', 'manager2@ecocheck.vn', 'MG002', 'manager', 'active', '{"name": "Đặng Thị Quỳnh"}'::jsonb),
  
  -- Admin account
  (uuid_generate_v4(), '0900000001', 'admin@ecocheck.vn', 'ADMIN', 'admin', 'active', '{"name": "System Admin"}'::jsonb)
ON CONFLICT (phone) DO NOTHING;

-- Success message
SELECT 'Enhanced seed data (Part 1) inserted successfully!' AS message;

