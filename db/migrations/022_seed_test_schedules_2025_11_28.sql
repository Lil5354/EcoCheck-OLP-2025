-- EcoCheck - Seed Test Schedules for Route Optimization Testing
-- Date: 2025-11-28
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- TEST DATA: Schedules for Route Optimization (28/11/2025)
-- ============================================================================
-- This script adds test schedules across different districts in Ho Chi Minh City
-- to test route optimization functionality

-- Get a citizen user ID (use first available user)
DO $$
DECLARE
    v_citizen_id UUID;
    v_test_date TIMESTAMPTZ := '2025-11-28 08:00:00+07';
BEGIN
    -- Get first citizen user
    SELECT id INTO v_citizen_id FROM users WHERE role = 'citizen' LIMIT 1;
    
    -- If no citizen exists, create one
    IF v_citizen_id IS NULL THEN
        INSERT INTO users (id, phone, role, status)
        VALUES (gen_random_uuid(), '0900000001', 'citizen', 'active')
        RETURNING id INTO v_citizen_id;
    END IF;

    -- District 1 - Central area (Multiple points)
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, latitude, longitude, address, status, priority, notes) VALUES
        (v_citizen_id::text, v_test_date + INTERVAL '1 hour', 'morning', 'household', 25.50, 10.7769, 106.7009, '123 Nguyễn Du, Quận 1, TP.HCM', 'scheduled', 1, 'Test route optimization - District 1'),
        (v_citizen_id::text, v_test_date + INTERVAL '2 hours', 'morning', 'recyclable', 15.00, 10.7756, 106.7012, '45 Lê Lợi, Quận 1, TP.HCM', 'scheduled', 1, 'Test route optimization - District 1'),
        (v_citizen_id::text, v_test_date + INTERVAL '3 hours', 'morning', 'organic', 30.00, 10.7743, 106.7015, '78 Pasteur, Quận 1, TP.HCM', 'scheduled', 1, 'Test route optimization - District 1'),
        (v_citizen_id::text, v_test_date + INTERVAL '4 hours', 'afternoon', 'bulky', 50.00, 10.7730, 106.7018, '12 Đồng Khởi, Quận 1, TP.HCM', 'scheduled', 2, 'Test route optimization - District 1'),
        (v_citizen_id::text, v_test_date + INTERVAL '5 hours', 'afternoon', 'household', 20.00, 10.7717, 106.7021, '56 Nguyễn Huệ, Quận 1, TP.HCM', 'scheduled', 1, 'Test route optimization - District 1');

    -- District 3 - Near District 1
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, latitude, longitude, address, status, priority, notes) VALUES
        (v_citizen_id::text, v_test_date + INTERVAL '1 hour', 'morning', 'recyclable', 18.00, 10.7920, 106.6880, '89 Võ Văn Tần, Quận 3, TP.HCM', 'scheduled', 1, 'Test route optimization - District 3'),
        (v_citizen_id::text, v_test_date + INTERVAL '2 hours', 'morning', 'household', 22.50, 10.7907, 106.6883, '34 Nguyễn Đình Chiểu, Quận 3, TP.HCM', 'scheduled', 1, 'Test route optimization - District 3'),
        (v_citizen_id::text, v_test_date + INTERVAL '3 hours', 'afternoon', 'organic', 28.00, 10.7894, 106.6886, '67 Lý Tự Trọng, Quận 3, TP.HCM', 'scheduled', 1, 'Test route optimization - District 3'),
        (v_citizen_id::text, v_test_date + INTERVAL '4 hours', 'afternoon', 'recyclable', 16.50, 10.7881, 106.6889, '91 Trần Hưng Đạo, Quận 3, TP.HCM', 'scheduled', 1, 'Test route optimization - District 3');

    -- District 5 - Chinatown area
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, latitude, longitude, address, status, priority, notes) VALUES
        (v_citizen_id::text, v_test_date + INTERVAL '1 hour', 'morning', 'household', 35.00, 10.7550, 106.6780, '123 Chợ Lớn, Quận 5, TP.HCM', 'scheduled', 2, 'Test route optimization - District 5'),
        (v_citizen_id::text, v_test_date + INTERVAL '2 hours', 'morning', 'recyclable', 20.00, 10.7537, 106.6783, '45 Hải Thượng Lãn Ông, Quận 5, TP.HCM', 'scheduled', 1, 'Test route optimization - District 5'),
        (v_citizen_id::text, v_test_date + INTERVAL '3 hours', 'afternoon', 'bulky', 60.00, 10.7524, 106.6786, '78 Nguyễn Trãi, Quận 5, TP.HCM', 'scheduled', 3, 'Test route optimization - District 5'),
        (v_citizen_id::text, v_test_date + INTERVAL '4 hours', 'afternoon', 'household', 28.00, 10.7511, 106.6789, '12 Trần Hưng Đạo, Quận 5, TP.HCM', 'scheduled', 1, 'Test route optimization - District 5'),
        (v_citizen_id::text, v_test_date + INTERVAL '5 hours', 'evening', 'organic', 32.00, 10.7498, 106.6792, '56 Lý Thái Tổ, Quận 5, TP.HCM', 'scheduled', 1, 'Test route optimization - District 5');

    -- District 7 - New urban area
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, latitude, longitude, address, status, priority, notes) VALUES
        (v_citizen_id::text, v_test_date + INTERVAL '1 hour', 'morning', 'household', 30.00, 10.7300, 106.7200, '123 Nguyễn Thị Thập, Quận 7, TP.HCM', 'scheduled', 1, 'Test route optimization - District 7'),
        (v_citizen_id::text, v_test_date + INTERVAL '2 hours', 'morning', 'recyclable', 25.00, 10.7287, 106.7203, '45 Huỳnh Tấn Phát, Quận 7, TP.HCM', 'scheduled', 1, 'Test route optimization - District 7'),
        (v_citizen_id::text, v_test_date + INTERVAL '3 hours', 'afternoon', 'organic', 40.00, 10.7274, 106.7206, '78 Nguyễn Lương Bằng, Quận 7, TP.HCM', 'scheduled', 2, 'Test route optimization - District 7'),
        (v_citizen_id::text, v_test_date + INTERVAL '4 hours', 'afternoon', 'household', 27.50, 10.7261, 106.7209, '12 Lê Văn Lương, Quận 7, TP.HCM', 'scheduled', 1, 'Test route optimization - District 7');

    -- District 10 - Near airport
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, latitude, longitude, address, status, priority, notes) VALUES
        (v_citizen_id::text, v_test_date + INTERVAL '1 hour', 'morning', 'recyclable', 22.00, 10.7670, 106.6660, '123 3 Tháng 2, Quận 10, TP.HCM', 'scheduled', 1, 'Test route optimization - District 10'),
        (v_citizen_id::text, v_test_date + INTERVAL '2 hours', 'morning', 'household', 26.00, 10.7657, 106.6663, '45 Lý Thường Kiệt, Quận 10, TP.HCM', 'scheduled', 1, 'Test route optimization - District 10'),
        (v_citizen_id::text, v_test_date + INTERVAL '3 hours', 'afternoon', 'bulky', 55.00, 10.7644, 106.6666, '78 Nguyễn Tri Phương, Quận 10, TP.HCM', 'scheduled', 3, 'Test route optimization - District 10'),
        (v_citizen_id::text, v_test_date + INTERVAL '4 hours', 'afternoon', 'organic', 33.00, 10.7631, 106.6669, '12 Cách Mạng Tháng 8, Quận 10, TP.HCM', 'scheduled', 1, 'Test route optimization - District 10'),
        (v_citizen_id::text, v_test_date + INTERVAL '5 hours', 'evening', 'recyclable', 19.50, 10.7618, 106.6672, '56 Điện Biên Phủ, Quận 10, TP.HCM', 'scheduled', 1, 'Test route optimization - District 10');

    -- District Bình Thạnh - Mixed area
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, latitude, longitude, address, status, priority, notes) VALUES
        (v_citizen_id::text, v_test_date + INTERVAL '1 hour', 'morning', 'household', 24.00, 10.8020, 106.7100, '123 Xô Viết Nghệ Tĩnh, Quận Bình Thạnh, TP.HCM', 'scheduled', 1, 'Test route optimization - Bình Thạnh'),
        (v_citizen_id::text, v_test_date + INTERVAL '2 hours', 'morning', 'recyclable', 17.00, 10.8007, 106.7103, '45 Bạch Đằng, Quận Bình Thạnh, TP.HCM', 'scheduled', 1, 'Test route optimization - Bình Thạnh'),
        (v_citizen_id::text, v_test_date + INTERVAL '3 hours', 'afternoon', 'organic', 29.00, 10.7994, 106.7106, '78 Điện Biên Phủ, Quận Bình Thạnh, TP.HCM', 'scheduled', 1, 'Test route optimization - Bình Thạnh'),
        (v_citizen_id::text, v_test_date + INTERVAL '4 hours', 'afternoon', 'household', 31.00, 10.7981, 106.7109, '12 Nguyễn Xí, Quận Bình Thạnh, TP.HCM', 'scheduled', 1, 'Test route optimization - Bình Thạnh');

    -- District Tân Bình - Near airport
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, latitude, longitude, address, status, priority, notes) VALUES
        (v_citizen_id::text, v_test_date + INTERVAL '1 hour', 'morning', 'recyclable', 21.00, 10.7900, 106.6500, '123 Cộng Hòa, Quận Tân Bình, TP.HCM', 'scheduled', 1, 'Test route optimization - Tân Bình'),
        (v_citizen_id::text, v_test_date + INTERVAL '2 hours', 'morning', 'household', 23.50, 10.7887, 106.6503, '45 Hoàng Văn Thụ, Quận Tân Bình, TP.HCM', 'scheduled', 1, 'Test route optimization - Tân Bình'),
        (v_citizen_id::text, v_test_date + INTERVAL '3 hours', 'afternoon', 'bulky', 48.00, 10.7874, 106.6506, '78 Trường Chinh, Quận Tân Bình, TP.HCM', 'scheduled', 2, 'Test route optimization - Tân Bình'),
        (v_citizen_id::text, v_test_date + INTERVAL '4 hours', 'afternoon', 'organic', 36.00, 10.7861, 106.6509, '12 Lạc Long Quân, Quận Tân Bình, TP.HCM', 'scheduled', 1, 'Test route optimization - Tân Bình'),
        (v_citizen_id::text, v_test_date + INTERVAL '5 hours', 'evening', 'household', 25.00, 10.7848, 106.6512, '56 Tân Sơn Nhì, Quận Tân Bình, TP.HCM', 'scheduled', 1, 'Test route optimization - Tân Bình');

    -- District Phú Nhuận - Central area
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, latitude, longitude, address, status, priority, notes) VALUES
        (v_citizen_id::text, v_test_date + INTERVAL '1 hour', 'morning', 'household', 26.50, 10.8000, 106.6900, '123 Phan Đăng Lưu, Quận Phú Nhuận, TP.HCM', 'scheduled', 1, 'Test route optimization - Phú Nhuận'),
        (v_citizen_id::text, v_test_date + INTERVAL '2 hours', 'morning', 'recyclable', 18.50, 10.7987, 106.6903, '45 Nguyễn Văn Trỗi, Quận Phú Nhuận, TP.HCM', 'scheduled', 1, 'Test route optimization - Phú Nhuận'),
        (v_citizen_id::text, v_test_date + INTERVAL '3 hours', 'afternoon', 'organic', 27.00, 10.7974, 106.6906, '78 Hoàng Minh Giám, Quận Phú Nhuận, TP.HCM', 'scheduled', 1, 'Test route optimization - Phú Nhuận'),
        (v_citizen_id::text, v_test_date + INTERVAL '4 hours', 'afternoon', 'household', 29.50, 10.7961, 106.6909, '12 Đặng Văn Ngữ, Quận Phú Nhuận, TP.HCM', 'scheduled', 1, 'Test route optimization - Phú Nhuận');

    RAISE NOTICE 'Successfully inserted test schedules for 2025-11-28';
END $$;

-- Verify the inserted data
SELECT 
    COUNT(*) as total_schedules,
    COUNT(DISTINCT time_slot) as time_slots,
    COUNT(DISTINCT waste_type) as waste_types,
    MIN(estimated_weight) as min_weight,
    MAX(estimated_weight) as max_weight,
    AVG(estimated_weight) as avg_weight
FROM schedules 
WHERE scheduled_date::date = '2025-11-28'
AND notes LIKE 'Test route optimization%';

SELECT 'Test schedules inserted successfully for route optimization testing!' AS message;

