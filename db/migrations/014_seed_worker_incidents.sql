-- Migration: Seed Worker Incident Reports
-- Description: Add test data for worker reports (violations and damages)
-- Version: 014
-- Date: 2025-12-03

-- ============================================================================
-- SEED WORKER INCIDENT REPORTS
-- ============================================================================

-- Get personnel IDs for workers
DO $$
DECLARE
    driver1_id UUID;
    driver2_id UUID;
    collector1_id UUID;
    collector2_id UUID;
    manager1_id UUID;
BEGIN
    -- Get personnel IDs
    SELECT id INTO driver1_id FROM personnel WHERE role = 'driver' AND status = 'active' LIMIT 1;
    SELECT id INTO driver2_id FROM personnel WHERE role = 'driver' AND status = 'active' OFFSET 1 LIMIT 1;
    SELECT id INTO collector1_id FROM personnel WHERE role = 'collector' AND status = 'active' LIMIT 1;
    SELECT id INTO collector2_id FROM personnel WHERE role = 'collector' AND status = 'active' OFFSET 1 LIMIT 1;
    SELECT id INTO manager1_id FROM personnel WHERE role = 'manager' AND status = 'active' LIMIT 1;

    -- If no personnel exists, create some
    IF driver1_id IS NULL THEN
        INSERT INTO personnel (id, name, role, phone, email, status, hired_at)
        VALUES 
            (gen_random_uuid(), 'Nguyễn Văn Tài', 'driver', '0901111111', 'nguyenvantai@ecocheck.vn', 'active', NOW())
        RETURNING id INTO driver1_id;
    END IF;

    IF driver2_id IS NULL THEN
        SELECT id INTO driver2_id FROM personnel WHERE role = 'driver' AND status = 'active' OFFSET 1 LIMIT 1;
        IF driver2_id IS NULL THEN
            INSERT INTO personnel (id, name, role, phone, email, status, hired_at)
            VALUES 
                (gen_random_uuid(), 'Trần Văn Hùng', 'driver', '0902222222', 'tranvanhung@ecocheck.vn', 'active', NOW())
            RETURNING id INTO driver2_id;
        END IF;
    END IF;

    IF collector1_id IS NULL THEN
        SELECT id INTO collector1_id FROM personnel WHERE role = 'collector' AND status = 'active' LIMIT 1;
        IF collector1_id IS NULL THEN
            INSERT INTO personnel (id, name, role, phone, email, status, hired_at)
            VALUES 
                (gen_random_uuid(), 'Lê Thị Mai', 'collector', '0903333333', 'lethimai@ecocheck.vn', 'active', NOW())
            RETURNING id INTO collector1_id;
        END IF;
    END IF;

    IF collector2_id IS NULL THEN
        SELECT id INTO collector2_id FROM personnel WHERE role = 'collector' AND status = 'active' OFFSET 1 LIMIT 1;
        IF collector2_id IS NULL THEN
            INSERT INTO personnel (id, name, role, phone, email, status, hired_at)
            VALUES 
                (gen_random_uuid(), 'Phạm Thị Lan', 'collector', '0904444444', 'phamthilan@ecocheck.vn', 'active', NOW())
            RETURNING id INTO collector2_id;
        END IF;
    END IF;

    IF manager1_id IS NULL THEN
        INSERT INTO personnel (id, name, role, phone, email, status, hired_at)
        VALUES 
            (gen_random_uuid(), 'Võ Văn Quang', 'manager', '0905555555', 'vovanquang@ecocheck.vn', 'active', NOW())
        RETURNING id INTO manager1_id;
    END IF;

    -- Insert VIOLATION reports (Vi phạm)
    INSERT INTO incidents (
        reporter_id,
        reporter_name,
        reporter_phone,
        report_category,
        type,
        description,
        geom,
        location_address,
        image_urls,
        priority,
        status,
        created_at,
        updated_at
    ) VALUES
    -- Violation 1: Illegal dump
    (
        driver1_id,
        (SELECT name FROM personnel WHERE id = driver1_id),
        (SELECT phone FROM personnel WHERE id = driver1_id),
        'violation',
        'illegal_dump',
        'Phát hiện điểm đổ rác trái phép tại khu vực công viên. Rác thải sinh hoạt được đổ bừa bãi, không đúng nơi quy định. Cần xử lý ngay để tránh ảnh hưởng môi trường.',
        ST_SetSRID(ST_MakePoint(106.7009, 10.7769), 4326)::geography,
        'Công viên Lê Văn Tám, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'high',
        'pending',
        NOW() - INTERVAL '2 hours',
        NOW() - INTERVAL '2 hours'
    ),
    -- Violation 2: Wrong classification
    (
        collector1_id,
        (SELECT name FROM personnel WHERE id = collector1_id),
        (SELECT phone FROM personnel WHERE id = collector1_id),
        'violation',
        'wrong_classification',
        'Người dân phân loại rác sai. Rác tái chế được bỏ vào thùng rác sinh hoạt. Cần tuyên truyền lại về cách phân loại rác đúng.',
        ST_SetSRID(ST_MakePoint(106.660172, 10.762622), 4326)::geography,
        '123 Nguyễn Huệ, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400'],
        'medium',
        'open',
        NOW() - INTERVAL '5 hours',
        NOW() - INTERVAL '4 hours'
    ),
    -- Violation 3: Overloaded bin
    (
        driver2_id,
        (SELECT name FROM personnel WHERE id = driver2_id),
        (SELECT phone FROM personnel WHERE id = driver2_id),
        'violation',
        'overloaded_bin',
        'Thùng rác tại khu vực chợ đã quá tải, rác tràn ra ngoài. Cần tăng tần suất thu gom hoặc thêm thùng rác mới.',
        ST_SetSRID(ST_MakePoint(106.6667, 10.7500), 4326)::geography,
        'Chợ Bến Thành, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400', 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'urgent',
        'in_progress',
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '12 hours'
    ),
    -- Violation 4: Littering
    (
        collector2_id,
        (SELECT name FROM personnel WHERE id = collector2_id),
        (SELECT phone FROM personnel WHERE id = collector2_id),
        'violation',
        'littering',
        'Xả rác bừa bãi tại khu vực trường học. Học sinh và phụ huynh vứt rác không đúng nơi quy định.',
        ST_SetSRID(ST_MakePoint(106.6900, 10.7800), 4326)::geography,
        'Trường THCS Nguyễn Du, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400'],
        'medium',
        'resolved',
        NOW() - INTERVAL '3 days',
        NOW() - INTERVAL '1 day'
    ),
    -- Violation 5: Burning waste
    (
        driver1_id,
        (SELECT name FROM personnel WHERE id = driver1_id),
        (SELECT phone FROM personnel WHERE id = driver1_id),
        'violation',
        'burning_waste',
        'Phát hiện người dân đốt rác tại khu vực ngoại thành. Khói bụi gây ô nhiễm không khí nghiêm trọng.',
        ST_SetSRID(ST_MakePoint(106.7000, 10.8000), 4326)::geography,
        'Xã An Phú Đông, Quận 12, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400', 'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400'],
        'high',
        'open',
        NOW() - INTERVAL '6 hours',
        NOW() - INTERVAL '6 hours'
    );

    -- Insert DAMAGE reports (Hư hỏng)
    INSERT INTO incidents (
        reporter_id,
        reporter_name,
        reporter_phone,
        report_category,
        type,
        description,
        geom,
        location_address,
        image_urls,
        priority,
        status,
        created_at,
        updated_at
    ) VALUES
    -- Damage 1: Broken bin
    (
        collector1_id,
        (SELECT name FROM personnel WHERE id = collector1_id),
        (SELECT phone FROM personnel WHERE id = collector1_id),
        'damage',
        'broken_bin',
        'Thùng rác bị hỏng nắp, không đóng được. Rác bên trong có thể bị rơi ra ngoài hoặc bị mưa làm ướt.',
        ST_SetSRID(ST_MakePoint(106.6800, 10.7700), 4326)::geography,
        'Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400', 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400'],
        'medium',
        'pending',
        NOW() - INTERVAL '3 hours',
        NOW() - INTERVAL '3 hours'
    ),
    -- Damage 2: Damaged equipment
    (
        driver2_id,
        (SELECT name FROM personnel WHERE id = driver2_id),
        (SELECT phone FROM personnel WHERE id = driver2_id),
        'damage',
        'damaged_equipment',
        'Thiết bị nén rác trên xe bị hỏng. Cần sửa chữa hoặc thay thế để đảm bảo hoạt động thu gom.',
        ST_SetSRID(ST_MakePoint(106.6700, 10.7600), 4326)::geography,
        'Bãi đỗ xe Depot 1, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'high',
        'in_progress',
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '18 hours'
    ),
    -- Damage 3: Road damage
    (
        collector2_id,
        (SELECT name FROM personnel WHERE id = collector2_id),
        (SELECT phone FROM personnel WHERE id = collector2_id),
        'damage',
        'road_damage',
        'Đường vào khu vực thu gom bị sụt lún, có ổ gà lớn. Xe thu gom khó di chuyển, cần sửa chữa đường.',
        ST_SetSRID(ST_MakePoint(106.7100, 10.7900), 4326)::geography,
        'Đường Nguyễn Văn Cừ, Quận 5, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400', 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'medium',
        'open',
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '1 day'
    ),
    -- Damage 4: Facility damage
    (
        manager1_id,
        (SELECT name FROM personnel WHERE id = manager1_id),
        (SELECT phone FROM personnel WHERE id = manager1_id),
        'damage',
        'facility_damage',
        'Cơ sở vật chất tại trạm thu gom bị hư hỏng. Cửa ra vào bị kẹt, hệ thống điện có vấn đề.',
        ST_SetSRID(ST_MakePoint(106.6500, 10.7500), 4326)::geography,
        'Trạm thu gom Quận 3, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'high',
        'resolved',
        NOW() - INTERVAL '5 days',
        NOW() - INTERVAL '2 days'
    ),
    -- Damage 5: Vehicle issue
    (
        driver1_id,
        (SELECT name FROM personnel WHERE id = driver1_id),
        (SELECT phone FROM personnel WHERE id = driver1_id),
        'damage',
        'vehicle_issue',
        'Xe thu gom bị sự cố động cơ, không thể khởi động. Cần cửa hàng sửa chữa kiểm tra và sửa chữa.',
        ST_SetSRID(ST_MakePoint(106.7000, 10.7800), 4326)::geography,
        'Đường Võ Văn Tần, Quận 3, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400', 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400'],
        'urgent',
        'in_progress',
        NOW() - INTERVAL '4 hours',
        NOW() - INTERVAL '2 hours'
    ),
    -- Damage 6: Missed collection
    (
        collector1_id,
        (SELECT name FROM personnel WHERE id = collector1_id),
        (SELECT phone FROM personnel WHERE id = collector1_id),
        'damage',
        'missed_collection',
        'Bỏ sót thu gom tại một số điểm trong tuyến đường. Người dân phản ánh rác không được thu gom đúng lịch.',
        ST_SetSRID(ST_MakePoint(106.6750, 10.7650), 4326)::geography,
        'Khu phố 1, Phường Bến Nghé, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'medium',
        'closed',
        NOW() - INTERVAL '7 days',
        NOW() - INTERVAL '5 days'
    ),
    -- Damage 7: Overflow
    (
        driver2_id,
        (SELECT name FROM personnel WHERE id = driver2_id),
        (SELECT phone FROM personnel WHERE id = driver2_id),
        'damage',
        'overflow',
        'Rác tràn ra ngoài thùng do thùng đầy và chưa được thu gom kịp thời. Cần tăng tần suất thu gom.',
        ST_SetSRID(ST_MakePoint(106.6650, 10.7550), 4326)::geography,
        'Chung cư Sunrise, Quận 7, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400'],
        'high',
        'open',
        NOW() - INTERVAL '8 hours',
        NOW() - INTERVAL '8 hours'
    );

    RAISE NOTICE 'Đã thêm dữ liệu test cho báo cáo nhân viên thành công!';
END $$;

-- Migration completed
SELECT 'Migration 014: Seeded worker incident reports' as status;

