-- EcoCheck Seed Data
-- Dữ liệu mẫu cho development và testing

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Clear existing data (optional - uncomment if needed)
-- TRUNCATE TABLE exceptions, incidents, checkins, route_stops, routes, points, user_addresses, users, personnel, vehicles, dumps, depots CASCADE;

-- 1. DEPOTS (Trạm thu gom)
INSERT INTO depots (id, name, geom) VALUES
  (uuid_generate_v4(), 'Trạm Thu Gom Quận 1', ST_GeogFromText('POINT(106.6958 10.7769)')),
  (uuid_generate_v4(), 'Trạm Thu Gom Quận 3', ST_GeogFromText('POINT(106.6830 10.7830)')),
  (uuid_generate_v4(), 'Trạm Thu Gom Bình Thạnh', ST_GeogFromText('POINT(106.7054 10.8014)')),
  (uuid_generate_v4(), 'Trạm Thu Gom Tân Bình', ST_GeogFromText('POINT(106.6297 10.7992)'));

-- 2. DUMPS (Bãi rác / Trạm trung chuyển)
INSERT INTO dumps (id, name, geom) VALUES
  (uuid_generate_v4(), 'Bãi Rác Đa Phước', ST_GeogFromText('POINT(106.5500 10.8500)')),
  (uuid_generate_v4(), 'Trạm Trung Chuyển Gò Cát', ST_GeogFromText('POINT(106.7200 10.8100)')),
  (uuid_generate_v4(), 'Trạm Trung Chuyển Tân Sơn Nhất', ST_GeogFromText('POINT(106.6500 10.8200)'));

-- 3. VEHICLES (Phương tiện)
INSERT INTO vehicles (id, plate, type, capacity_kg, accepted_types, status, depot_id) VALUES
  ('VH001', '51A-12345', 'compactor', 5000, ARRAY['household', 'recyclable'], 'available', (SELECT id FROM depots LIMIT 1)),
  ('VH002', '51B-23456', 'compactor', 5000, ARRAY['household', 'recyclable'], 'available', (SELECT id FROM depots LIMIT 1)),
  ('VH003', '51C-34567', 'mini-truck', 2000, ARRAY['household', 'bulky'], 'available', (SELECT id FROM depots OFFSET 1 LIMIT 1)),
  ('VH004', '51D-45678', 'electric-trike', 500, ARRAY['recyclable'], 'available', (SELECT id FROM depots OFFSET 2 LIMIT 1)),
  ('VH005', '51E-56789', 'compactor', 5000, ARRAY['household', 'recyclable', 'bulky'], 'in_use', (SELECT id FROM depots OFFSET 3 LIMIT 1));

-- 4. PERSONNEL (Nhân sự)
INSERT INTO personnel (id, name, role, phone, status, depot_id) VALUES
  (uuid_generate_v4(), 'Nguyễn Văn An', 'driver', '0901234567', 'active', (SELECT id FROM depots LIMIT 1)),
  (uuid_generate_v4(), 'Trần Thị Bình', 'collector', '0902345678', 'active', (SELECT id FROM depots LIMIT 1)),
  (uuid_generate_v4(), 'Lê Văn Cường', 'driver', '0903456789', 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1)),
  (uuid_generate_v4(), 'Phạm Thị Dung', 'collector', '0904567890', 'active', (SELECT id FROM depots OFFSET 1 LIMIT 1)),
  (uuid_generate_v4(), 'Hoàng Văn Em', 'manager', '0905678901', 'active', (SELECT id FROM depots OFFSET 2 LIMIT 1)),
  (uuid_generate_v4(), 'Võ Thị Phương', 'dispatcher', '0906789012', 'active', (SELECT id FROM depots OFFSET 3 LIMIT 1));

-- 5. USERS (Người dùng - Người dân)
INSERT INTO users (id, phone, vneid, role, status) VALUES
  (uuid_generate_v4(), '0911111111', 'VN001', 'citizen', 'active'),
  (uuid_generate_v4(), '0922222222', 'VN002', 'citizen', 'active'),
  (uuid_generate_v4(), '0933333333', 'VN003', 'citizen', 'active'),
  (uuid_generate_v4(), '0944444444', 'VN004', 'citizen', 'active'),
  (uuid_generate_v4(), '0955555555', 'VN005', 'citizen', 'active');

-- 6. USER ADDRESSES (Địa chỉ người dùng)
INSERT INTO user_addresses (id, user_id, label, geom, is_default) VALUES
  -- User 1
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0911111111'), 'Nhà', ST_GeogFromText('POINT(106.6958 10.7769)'), true),
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0911111111'), 'Công ty', ST_GeogFromText('POINT(106.7000 10.7800)'), false),
  -- User 2
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0922222222'), 'Nhà', ST_GeogFromText('POINT(106.6830 10.7830)'), true),
  -- User 3
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0933333333'), 'Nhà', ST_GeogFromText('POINT(106.7054 10.8014)'), true),
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0933333333'), 'Nhà bố mẹ', ST_GeogFromText('POINT(106.7100 10.8050)'), false),
  -- User 4
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0944444444'), 'Nhà', ST_GeogFromText('POINT(106.6297 10.7992)'), true),
  -- User 5
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0955555555'), 'Nhà', ST_GeogFromText('POINT(106.6900 10.7750)'), true);

-- 7. POINTS (Điểm thu gom)
INSERT INTO points (id, address_id, geom, ghost, last_waste_type, last_level, last_checkin_at) VALUES
  -- Points từ user addresses
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0911111111')), 
   ST_GeogFromText('POINT(106.6958 10.7769)'), false, 'household', 0.75, NOW() - INTERVAL '2 hours'),
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Công ty' AND user_id = (SELECT id FROM users WHERE phone = '0911111111')), 
   ST_GeogFromText('POINT(106.7000 10.7800)'), false, 'recyclable', 0.50, NOW() - INTERVAL '1 day'),
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0922222222')), 
   ST_GeogFromText('POINT(106.6830 10.7830)'), false, 'household', 0.85, NOW() - INTERVAL '3 hours'),
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0933333333')), 
   ST_GeogFromText('POINT(106.7054 10.8014)'), false, 'bulky', 0.90, NOW() - INTERVAL '5 hours'),
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0944444444')), 
   ST_GeogFromText('POINT(106.6297 10.7992)'), false, 'household', 0.60, NOW() - INTERVAL '6 hours'),
  -- Ghost points (không có địa chỉ cụ thể)
  (uuid_generate_v4(), NULL, ST_GeogFromText('POINT(106.6950 10.7780)'), true, 'household', 0.70, NOW() - INTERVAL '4 hours'),
  (uuid_generate_v4(), NULL, ST_GeogFromText('POINT(106.6980 10.7790)'), true, 'recyclable', 0.55, NOW() - INTERVAL '8 hours');

-- 8. CHECKINS (Check-in rác)
INSERT INTO checkins (id, user_id, point_id, waste_type, filling_level, geom, photo_url, source, created_at) VALUES
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0911111111'),
   (SELECT id FROM points WHERE ghost = false LIMIT 1),
   'household', 0.75, ST_GeogFromText('POINT(106.6958 10.7769)'),
   'https://example.com/photos/checkin1.jpg', 'mobile_app', NOW() - INTERVAL '2 hours'),
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0922222222'),
   (SELECT id FROM points WHERE ghost = false OFFSET 2 LIMIT 1),
   'household', 0.85, ST_GeogFromText('POINT(106.6830 10.7830)'),
   'https://example.com/photos/checkin2.jpg', 'mobile_app', NOW() - INTERVAL '3 hours'),
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0933333333'),
   (SELECT id FROM points WHERE ghost = false OFFSET 3 LIMIT 1),
   'bulky', 0.90, ST_GeogFromText('POINT(106.7054 10.8014)'),
   'https://example.com/photos/checkin3.jpg', 'mobile_app', NOW() - INTERVAL '5 hours');

-- 9. INCIDENTS (Sự cố)
INSERT INTO incidents (id, reporter_id, type, description, geom, photo_url, status, created_at) VALUES
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0911111111'),
   'overflow', 'Thùng rác tràn ra đường', ST_GeogFromText('POINT(106.6960 10.7770)'),
   'https://example.com/photos/incident1.jpg', 'open', NOW() - INTERVAL '1 hour'),
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0922222222'),
   'illegal_dump', 'Có người đổ rác bừa bãi', ST_GeogFromText('POINT(106.6835 10.7835)'),
   'https://example.com/photos/incident2.jpg', 'in_progress', NOW() - INTERVAL '2 days');

-- 10. ROUTES (Tuyến đường - mẫu)
INSERT INTO routes (id, vehicle_id, depot_id, dump_id, start_at, end_at, status, meta) VALUES
  (uuid_generate_v4(), 'VH001', 
   (SELECT id FROM depots LIMIT 1),
   (SELECT id FROM dumps LIMIT 1),
   NOW() - INTERVAL '2 hours', NULL, 'in_progress',
   '{"driver": "Nguyễn Văn An", "collector": "Trần Thị Bình"}'::jsonb),
  (uuid_generate_v4(), 'VH002',
   (SELECT id FROM depots LIMIT 1),
   (SELECT id FROM dumps LIMIT 1),
   NOW() + INTERVAL '2 hours', NULL, 'planned',
   '{"driver": "Lê Văn Cường", "collector": "Phạm Thị Dung"}'::jsonb);

-- Success message
SELECT 'Seed data inserted successfully!' AS message;

