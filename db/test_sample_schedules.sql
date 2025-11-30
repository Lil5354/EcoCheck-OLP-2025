-- ============================================================================
-- TEST SAMPLE SCHEDULES - Bình Thạnh District
-- Tạo 30 schedules mẫu cho ngày 28/11/2025 để test VRP optimization
-- LƯU Ý: Data này chỉ dùng để test, có thể xóa sau khi test xong
-- ============================================================================

-- Xóa schedules test cũ (nếu có) - chỉ xóa những schedule có address chứa "TEST_SAMPLE"
DELETE FROM schedules 
WHERE address LIKE '%TEST_SAMPLE%' 
  AND scheduled_date = '2025-11-28'::date;

-- Tạo 30 schedules mẫu trong khu vực Bình Thạnh
INSERT INTO schedules (
  schedule_id, 
  citizen_id, 
  scheduled_date, 
  time_slot,
  waste_type, 
  estimated_weight, 
  status, 
  address, 
  latitude, 
  longitude, 
  created_at, 
  updated_at
)
SELECT 
  gen_random_uuid() as schedule_id,
  COALESCE(
    (SELECT id::text FROM users WHERE role = 'citizen' LIMIT 1),
    (SELECT phone FROM users WHERE phone IS NOT NULL LIMIT 1),
    'TEST_USER_001'
  ) as citizen_id,
  '2025-11-28'::timestamptz as scheduled_date,
  (ARRAY['morning', 'afternoon', 'evening'])[floor(random() * 3 + 1)]::text as time_slot,
  (ARRAY['household', 'recyclable', 'bulky'])[floor(random() * 3 + 1)]::text as waste_type,
  (random() * 200 + 50)::numeric(10,2) as estimated_weight, -- 50-250kg
  'scheduled' as status,
  'TEST_SAMPLE - ' ||
  'Quận Bình Thạnh, ' || 
  (ARRAY[
    'Đường Xô Viết Nghệ Tĩnh', 
    'Đường Điện Biên Phủ', 
    'Đường Nguyễn Văn Đậu', 
    'Đường Phan Đăng Lưu', 
    'Đường Bạch Đằng', 
    'Đường Nguyễn Hữu Cảnh',
    'Đường D2',
    'Đường D1',
    'Đường Nguyễn Xí',
    'Đường Ung Văn Khiêm'
  ])[floor(random() * 10 + 1)] ||
  ', số ' || floor(random() * 200 + 1)::text as address,
  -- Tọa độ trong khu vực Bình Thạnh (khoảng 10.78 +/- 0.03)
  (10.78 + (random() * 0.06 - 0.03))::numeric(10,8) as latitude,  -- Khoảng 10.75 - 10.81
  -- Longitude (khoảng 106.70 +/- 0.03)
  (106.70 + (random() * 0.06 - 0.03))::numeric(11,8) as longitude, -- Khoảng 106.67 - 106.73
  NOW() as created_at,
  NOW() as updated_at
FROM generate_series(1, 30); -- Tạo 30 schedules mẫu

-- Hiển thị số lượng schedules đã tạo
SELECT 
  COUNT(*) as total_schedules,
  COUNT(DISTINCT waste_type) as waste_types,
  ROUND(AVG(estimated_weight), 2) as avg_weight_kg,
  ROUND(MIN(estimated_weight), 2) as min_weight_kg,
  ROUND(MAX(estimated_weight), 2) as max_weight_kg
FROM schedules 
WHERE address LIKE '%TEST_SAMPLE%' 
  AND scheduled_date = '2025-11-28'::date;

-- Thông báo thành công
SELECT '✅ Đã tạo 30 schedules mẫu cho Bình Thạnh - ngày 28/11/2025' AS message;
SELECT '💡 Để xóa data test sau khi test xong, chạy lệnh:' AS note;
SELECT '   DELETE FROM schedules WHERE address LIKE ''%TEST_SAMPLE%'' AND scheduled_date = ''2025-11-28''::date;' AS delete_command;

