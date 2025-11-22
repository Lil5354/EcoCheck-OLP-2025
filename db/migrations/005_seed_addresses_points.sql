-- EcoCheck - Seed User Addresses and Collection Points
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- USER ADDRESSES (Địa chỉ người dùng)
-- ============================================================================

-- User 1 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0911111111'), 'Nhà', '123 Nguyễn Huệ, Quận 1, TP.HCM', 
   ST_GeogFromText('POINT(106.6958 10.7769)'), true, true),
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0911111111'), 'Công ty', '456 Lê Lợi, Quận 1, TP.HCM', 
   ST_GeogFromText('POINT(106.7000 10.7800)'), false, true);

-- User 2 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0922222222'), 'Nhà', '789 Võ Văn Tần, Quận 3, TP.HCM', 
   ST_GeogFromText('POINT(106.6830 10.7830)'), true, true);

-- User 3 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0933333333'), 'Nhà', '321 Xô Viết Nghệ Tĩnh, Bình Thạnh, TP.HCM', 
   ST_GeogFromText('POINT(106.7054 10.8014)'), true, true),
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0933333333'), 'Nhà bố mẹ', '654 Điện Biên Phủ, Bình Thạnh, TP.HCM', 
   ST_GeogFromText('POINT(106.7100 10.8050)'), false, true);

-- User 4 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0944444444'), 'Nhà', '987 Cộng Hòa, Tân Bình, TP.HCM', 
   ST_GeogFromText('POINT(106.6297 10.7992)'), true, true);

-- User 5 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0955555555'), 'Nhà', '147 Nguyễn Văn Trỗi, Phú Nhuận, TP.HCM', 
   ST_GeogFromText('POINT(106.6900 10.7750)'), true, true);

-- User 6 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0966666666'), 'Nhà', '258 Phan Đăng Lưu, Phú Nhuận, TP.HCM', 
   ST_GeogFromText('POINT(106.6850 10.7980)'), true, true),
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0966666666'), 'Chung cư', '369 Hoàng Văn Thụ, Phú Nhuận, TP.HCM', 
   ST_GeogFromText('POINT(106.6820 10.7960)'), false, true);

-- User 7 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0977777777'), 'Nhà', '741 Trường Chinh, Tân Bình, TP.HCM', 
   ST_GeogFromText('POINT(106.6350 10.8050)'), true, true);

-- User 8 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0988888888'), 'Nhà', '852 Lý Thường Kiệt, Quận 10, TP.HCM', 
   ST_GeogFromText('POINT(106.6650 10.7720)'), true, true);

-- User 9 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0999999999'), 'Nhà', '963 Nguyễn Thị Minh Khai, Quận 3, TP.HCM', 
   ST_GeogFromText('POINT(106.6880 10.7850)'), true, true);

-- User 10 addresses
INSERT INTO user_addresses (id, user_id, label, address_text, geom, is_default, verified) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0900000000'), 'Nhà', '159 Pasteur, Quận 1, TP.HCM', 
   ST_GeogFromText('POINT(106.6920 10.7780)'), true, true);

-- ============================================================================
-- COLLECTION POINTS (Điểm thu gom)
-- ============================================================================

-- Points from user addresses (verified locations)
INSERT INTO points (id, address_id, geom, ghost, last_waste_type, last_level, last_checkin_at, total_checkins) VALUES
  -- User 1 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0911111111')), 
   ST_GeogFromText('POINT(106.6958 10.7769)'), false, 'household', 0.75, NOW() - INTERVAL '2 hours', 15),
  
  -- User 1 office
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Công ty' AND user_id = (SELECT id FROM users WHERE phone = '0911111111')), 
   ST_GeogFromText('POINT(106.7000 10.7800)'), false, 'recyclable', 0.50, NOW() - INTERVAL '1 day', 8),
  
  -- User 2 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0922222222')), 
   ST_GeogFromText('POINT(106.6830 10.7830)'), false, 'household', 0.85, NOW() - INTERVAL '3 hours', 22),
  
  -- User 3 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0933333333')), 
   ST_GeogFromText('POINT(106.7054 10.8014)'), false, 'bulky', 0.90, NOW() - INTERVAL '5 hours', 5),
  
  -- User 3 parents' home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà bố mẹ' AND user_id = (SELECT id FROM users WHERE phone = '0933333333')), 
   ST_GeogFromText('POINT(106.7100 10.8050)'), false, 'household', 0.60, NOW() - INTERVAL '1 day', 12),
  
  -- User 4 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0944444444')), 
   ST_GeogFromText('POINT(106.6297 10.7992)'), false, 'household', 0.60, NOW() - INTERVAL '6 hours', 18),
  
  -- User 5 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0955555555')), 
   ST_GeogFromText('POINT(106.6900 10.7750)'), false, 'recyclable', 0.70, NOW() - INTERVAL '4 hours', 25),
  
  -- User 6 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0966666666')), 
   ST_GeogFromText('POINT(106.6850 10.7980)'), false, 'household', 0.55, NOW() - INTERVAL '8 hours', 10),
  
  -- User 6 apartment
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Chung cư' AND user_id = (SELECT id FROM users WHERE phone = '0966666666')), 
   ST_GeogFromText('POINT(106.6820 10.7960)'), false, 'recyclable', 0.80, NOW() - INTERVAL '5 hours', 14),
  
  -- User 7 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0977777777')), 
   ST_GeogFromText('POINT(106.6350 10.8050)'), false, 'household', 0.65, NOW() - INTERVAL '7 hours', 20),
  
  -- User 8 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0988888888')), 
   ST_GeogFromText('POINT(106.6650 10.7720)'), false, 'bulky', 0.95, NOW() - INTERVAL '2 days', 3),
  
  -- User 9 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0999999999')), 
   ST_GeogFromText('POINT(106.6880 10.7850)'), false, 'household', 0.70, NOW() - INTERVAL '10 hours', 16),
  
  -- User 10 home
  (uuid_generate_v4(), (SELECT id FROM user_addresses WHERE label = 'Nhà' AND user_id = (SELECT id FROM users WHERE phone = '0900000000')), 
   ST_GeogFromText('POINT(106.6920 10.7780)'), false, 'recyclable', 0.45, NOW() - INTERVAL '12 hours', 30);

-- Ghost points (unregistered locations with check-ins)
INSERT INTO points (id, address_id, geom, ghost, last_waste_type, last_level, last_checkin_at, total_checkins) VALUES
  (uuid_generate_v4(), NULL, ST_GeogFromText('POINT(106.6950 10.7780)'), true, 'household', 0.70, NOW() - INTERVAL '4 hours', 2),
  (uuid_generate_v4(), NULL, ST_GeogFromText('POINT(106.6980 10.7790)'), true, 'recyclable', 0.55, NOW() - INTERVAL '8 hours', 1),
  (uuid_generate_v4(), NULL, ST_GeogFromText('POINT(106.6870 10.7840)'), true, 'household', 0.60, NOW() - INTERVAL '1 day', 3),
  (uuid_generate_v4(), NULL, ST_GeogFromText('POINT(106.7020 10.8020)'), true, 'bulky', 0.85, NOW() - INTERVAL '2 days', 1);

-- Success message
SELECT 'User addresses and collection points seeded successfully!' AS message;

