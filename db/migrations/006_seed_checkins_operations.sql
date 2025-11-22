-- EcoCheck - Seed Check-ins and Operations Data
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- CHECK-INS (Check-in rác từ người dân)
-- ============================================================================

-- Recent check-ins (last 24 hours)
INSERT INTO checkins (id, user_id, point_id, waste_type, filling_level, geom, photo_url, source, verified, created_at) VALUES
  -- User 1 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0911111111'),
   (SELECT id FROM points WHERE ghost = false LIMIT 1),
   'household', 0.75, ST_GeogFromText('POINT(106.6958 10.7769)'),
   'https://storage.ecocheck.vn/photos/checkin_001.jpg', 'mobile_app', true, NOW() - INTERVAL '2 hours'),
  
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0911111111'),
   (SELECT id FROM points WHERE ghost = false OFFSET 1 LIMIT 1),
   'recyclable', 0.50, ST_GeogFromText('POINT(106.7000 10.7800)'),
   'https://storage.ecocheck.vn/photos/checkin_002.jpg', 'mobile_app', true, NOW() - INTERVAL '1 day'),
  
  -- User 2 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0922222222'),
   (SELECT id FROM points WHERE ghost = false OFFSET 2 LIMIT 1),
   'household', 0.85, ST_GeogFromText('POINT(106.6830 10.7830)'),
   'https://storage.ecocheck.vn/photos/checkin_003.jpg', 'mobile_app', true, NOW() - INTERVAL '3 hours'),
  
  -- User 3 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0933333333'),
   (SELECT id FROM points WHERE ghost = false OFFSET 3 LIMIT 1),
   'bulky', 0.90, ST_GeogFromText('POINT(106.7054 10.8014)'),
   'https://storage.ecocheck.vn/photos/checkin_004.jpg', 'mobile_app', false, NOW() - INTERVAL '5 hours'),
  
  -- User 4 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0944444444'),
   (SELECT id FROM points WHERE ghost = false OFFSET 5 LIMIT 1),
   'household', 0.60, ST_GeogFromText('POINT(106.6297 10.7992)'),
   'https://storage.ecocheck.vn/photos/checkin_005.jpg', 'mobile_app', true, NOW() - INTERVAL '6 hours'),
  
  -- User 5 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0955555555'),
   (SELECT id FROM points WHERE ghost = false OFFSET 6 LIMIT 1),
   'recyclable', 0.70, ST_GeogFromText('POINT(106.6900 10.7750)'),
   'https://storage.ecocheck.vn/photos/checkin_006.jpg', 'mobile_app', true, NOW() - INTERVAL '4 hours'),
  
  -- User 6 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0966666666'),
   (SELECT id FROM points WHERE ghost = false OFFSET 7 LIMIT 1),
   'household', 0.55, ST_GeogFromText('POINT(106.6850 10.7980)'),
   NULL, 'mobile_app', false, NOW() - INTERVAL '8 hours'),
  
  -- User 7 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0977777777'),
   (SELECT id FROM points WHERE ghost = false OFFSET 9 LIMIT 1),
   'household', 0.65, ST_GeogFromText('POINT(106.6350 10.8050)'),
   'https://storage.ecocheck.vn/photos/checkin_007.jpg', 'mobile_app', true, NOW() - INTERVAL '7 hours'),
  
  -- User 8 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0988888888'),
   (SELECT id FROM points WHERE ghost = false OFFSET 10 LIMIT 1),
   'bulky', 0.95, ST_GeogFromText('POINT(106.6650 10.7720)'),
   'https://storage.ecocheck.vn/photos/checkin_008.jpg', 'mobile_app', false, NOW() - INTERVAL '2 days'),
  
  -- User 9 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0999999999'),
   (SELECT id FROM points WHERE ghost = false OFFSET 11 LIMIT 1),
   'household', 0.70, ST_GeogFromText('POINT(106.6880 10.7850)'),
   'https://storage.ecocheck.vn/photos/checkin_009.jpg', 'mobile_app', true, NOW() - INTERVAL '10 hours'),
  
  -- User 10 check-ins
  (uuid_generate_v4(), 
   (SELECT id FROM users WHERE phone = '0900000000'),
   (SELECT id FROM points WHERE ghost = false OFFSET 12 LIMIT 1),
   'recyclable', 0.45, ST_GeogFromText('POINT(106.6920 10.7780)'),
   'https://storage.ecocheck.vn/photos/checkin_010.jpg', 'mobile_app', true, NOW() - INTERVAL '12 hours');

-- Historical check-ins (older data for analytics)
INSERT INTO checkins (id, user_id, point_id, waste_type, filling_level, geom, source, verified, created_at) VALUES
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0911111111'), 
   (SELECT id FROM points WHERE ghost = false LIMIT 1), 'household', 0.70, 
   ST_GeogFromText('POINT(106.6958 10.7769)'), 'mobile_app', true, NOW() - INTERVAL '3 days'),
  
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0922222222'), 
   (SELECT id FROM points WHERE ghost = false OFFSET 2 LIMIT 1), 'recyclable', 0.60, 
   ST_GeogFromText('POINT(106.6830 10.7830)'), 'mobile_app', true, NOW() - INTERVAL '4 days'),
  
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0933333333'), 
   (SELECT id FROM points WHERE ghost = false OFFSET 3 LIMIT 1), 'household', 0.80, 
   ST_GeogFromText('POINT(106.7054 10.8014)'), 'mobile_app', true, NOW() - INTERVAL '5 days'),
  
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0955555555'), 
   (SELECT id FROM points WHERE ghost = false OFFSET 6 LIMIT 1), 'recyclable', 0.65, 
   ST_GeogFromText('POINT(106.6900 10.7750)'), 'mobile_app', true, NOW() - INTERVAL '6 days'),
  
  (uuid_generate_v4(), (SELECT id FROM users WHERE phone = '0900000000'), 
   (SELECT id FROM points WHERE ghost = false OFFSET 12 LIMIT 1), 'recyclable', 0.50, 
   ST_GeogFromText('POINT(106.6920 10.7780)'), 'mobile_app', true, NOW() - INTERVAL '7 days');

-- ============================================================================
-- INCIDENTS (Sự cố / Báo cáo từ người dân)
-- ============================================================================

INSERT INTO incidents (id, reporter_id, type, description, geom, photo_url, status, priority, created_at) VALUES
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0911111111'),
   'overflow', 'Thùng rác tràn ra đường, cần xử lý gấp', 
   ST_GeogFromText('POINT(106.6960 10.7770)'),
   'https://storage.ecocheck.vn/incidents/incident_001.jpg', 
   'open', 'high', NOW() - INTERVAL '1 hour'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0922222222'),
   'illegal_dump', 'Có người đổ rác bừa bãi tại góc đường', 
   ST_GeogFromText('POINT(106.6835 10.7835)'),
   'https://storage.ecocheck.vn/incidents/incident_002.jpg', 
   'in_progress', 'medium', NOW() - INTERVAL '2 days'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0933333333'),
   'missed_collection', 'Xe thu gom đã bỏ qua điểm của tôi', 
   ST_GeogFromText('POINT(106.7060 10.8020)'),
   'https://storage.ecocheck.vn/incidents/incident_003.jpg', 
   'resolved', 'medium', NOW() - INTERVAL '3 days'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0944444444'),
   'vehicle_issue', 'Xe rác rò rỉ nước thải', 
   ST_GeogFromText('POINT(106.6300 10.7995)'),
   'https://storage.ecocheck.vn/incidents/incident_004.jpg', 
   'open', 'urgent', NOW() - INTERVAL '4 hours'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0955555555'),
   'other', 'Mùi hôi từ điểm thu gom', 
   ST_GeogFromText('POINT(106.6905 10.7755)'),
   NULL, 
   'closed', 'low', NOW() - INTERVAL '5 days');

-- Success message
SELECT 'Check-ins and incidents seeded successfully!' AS message;

