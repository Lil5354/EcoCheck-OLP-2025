-- Migration: Seed Citizen Incident Reports
-- Description: Add test data for citizen reports (violations and damages)
-- Version: 015
-- Date: 2025-12-03

-- ============================================================================
-- SEED CITIZEN INCIDENT REPORTS
-- ============================================================================

-- Get user IDs for citizens
DO $$
DECLARE
    citizen1_id UUID;
    citizen2_id UUID;
    citizen3_id UUID;
    citizen4_id UUID;
    citizen5_id UUID;
BEGIN
    -- Get citizen user IDs
    SELECT id INTO citizen1_id FROM users WHERE role = 'citizen' AND status = 'active' LIMIT 1;
    SELECT id INTO citizen2_id FROM users WHERE role = 'citizen' AND status = 'active' OFFSET 1 LIMIT 1;
    SELECT id INTO citizen3_id FROM users WHERE role = 'citizen' AND status = 'active' OFFSET 2 LIMIT 1;
    SELECT id INTO citizen4_id FROM users WHERE role = 'citizen' AND status = 'active' OFFSET 3 LIMIT 1;
    SELECT id INTO citizen5_id FROM users WHERE role = 'citizen' AND status = 'active' OFFSET 4 LIMIT 1;

    -- If no citizens exist, create some
    IF citizen1_id IS NULL THEN
        INSERT INTO users (id, phone, email, role, status, profile, created_at)
        VALUES 
            (gen_random_uuid(), '0911111111', 'citizen1@example.com', 'citizen', 'active', '{"name": "Nguyễn Văn A"}'::jsonb, NOW())
        RETURNING id INTO citizen1_id;
    END IF;

    IF citizen2_id IS NULL THEN
        SELECT id INTO citizen2_id FROM users WHERE role = 'citizen' AND status = 'active' OFFSET 1 LIMIT 1;
        IF citizen2_id IS NULL THEN
            INSERT INTO users (id, phone, email, role, status, profile, created_at)
            VALUES 
                (gen_random_uuid(), '0922222222', 'citizen2@example.com', 'citizen', 'active', '{"name": "Trần Thị B"}'::jsonb, NOW())
            RETURNING id INTO citizen2_id;
        END IF;
    END IF;

    IF citizen3_id IS NULL THEN
        SELECT id INTO citizen3_id FROM users WHERE role = 'citizen' AND status = 'active' OFFSET 2 LIMIT 1;
        IF citizen3_id IS NULL THEN
            INSERT INTO users (id, phone, email, role, status, profile, created_at)
            VALUES 
                (gen_random_uuid(), '0933333333', 'citizen3@example.com', 'citizen', 'active', '{"name": "Lê Văn C"}'::jsonb, NOW())
            RETURNING id INTO citizen3_id;
        END IF;
    END IF;

    IF citizen4_id IS NULL THEN
        SELECT id INTO citizen4_id FROM users WHERE role = 'citizen' AND status = 'active' OFFSET 3 LIMIT 1;
        IF citizen4_id IS NULL THEN
            INSERT INTO users (id, phone, email, role, status, profile, created_at)
            VALUES 
                (gen_random_uuid(), '0944444444', 'citizen4@example.com', 'citizen', 'active', '{"name": "Phạm Thị D"}'::jsonb, NOW())
            RETURNING id INTO citizen4_id;
        END IF;
    END IF;

    IF citizen5_id IS NULL THEN
        SELECT id INTO citizen5_id FROM users WHERE role = 'citizen' AND status = 'active' OFFSET 4 LIMIT 1;
        IF citizen5_id IS NULL THEN
            INSERT INTO users (id, phone, email, role, status, profile, created_at)
            VALUES 
                (gen_random_uuid(), '0955555555', 'citizen5@example.com', 'citizen', 'active', '{"name": "Hoàng Văn E"}'::jsonb, NOW())
            RETURNING id INTO citizen5_id;
        END IF;
    END IF;

    -- Insert VIOLATION reports (Vi phạm) from citizens
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
        citizen1_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen1_id),
        (SELECT phone FROM users WHERE id = citizen1_id),
        'violation',
        'illegal_dump',
        'Tôi phát hiện có người đổ rác trái phép tại khu vực gần nhà. Rác thải sinh hoạt được đổ bừa bãi ra đường, gây mất vệ sinh và ảnh hưởng đến môi trường. Mong được xử lý sớm.',
        ST_SetSRID(ST_MakePoint(106.7010, 10.7770), 4326)::geography,
        '123 Đường Nguyễn Huệ, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'high',
        'pending',
        NOW() - INTERVAL '1 hour',
        NOW() - INTERVAL '1 hour'
    ),
    -- Violation 2: Wrong classification
    (
        citizen2_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen2_id),
        (SELECT phone FROM users WHERE id = citizen2_id),
        'violation',
        'wrong_classification',
        'Hàng xóm của tôi thường xuyên bỏ rác tái chế vào thùng rác sinh hoạt. Tôi đã nhắc nhở nhiều lần nhưng không cải thiện. Cần có biện pháp tuyên truyền.',
        ST_SetSRID(ST_MakePoint(106.6610, 10.7630), 4326)::geography,
        '456 Đường Lê Lợi, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400'],
        'medium',
        'open',
        NOW() - INTERVAL '3 hours',
        NOW() - INTERVAL '2 hours'
    ),
    -- Violation 3: Overloaded bin
    (
        citizen3_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen3_id),
        (SELECT phone FROM users WHERE id = citizen3_id),
        'violation',
        'overloaded_bin',
        'Thùng rác tại khu vực chợ đã quá tải từ sáng, rác tràn ra ngoài. Mùi hôi thối gây khó chịu cho người dân xung quanh. Cần tăng tần suất thu gom.',
        ST_SetSRID(ST_MakePoint(106.6670, 10.7510), 4326)::geography,
        'Chợ Bến Thành, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400', 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400'],
        'urgent',
        'in_progress',
        NOW() - INTERVAL '6 hours',
        NOW() - INTERVAL '4 hours'
    ),
    -- Violation 4: Littering
    (
        citizen4_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen4_id),
        (SELECT phone FROM users WHERE id = citizen4_id),
        'violation',
        'littering',
        'Nhiều người xả rác bừa bãi tại khu vực công viên, đặc biệt là sau các buổi tối. Rác thải nằm rải rác khắp nơi, ảnh hưởng đến cảnh quan.',
        ST_SetSRID(ST_MakePoint(106.6910, 10.7810), 4326)::geography,
        'Công viên 23/9, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400', 'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400'],
        'medium',
        'resolved',
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '1 day'
    ),
    -- Violation 5: Burning waste
    (
        citizen5_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen5_id),
        (SELECT phone FROM users WHERE id = citizen5_id),
        'violation',
        'burning_waste',
        'Có người đốt rác tại khu vực ngoại thành, khói bụi bay vào khu dân cư gây ô nhiễm không khí nghiêm trọng. Cần xử lý ngay.',
        ST_SetSRID(ST_MakePoint(106.7010, 10.8010), 4326)::geography,
        'Xã An Phú Đông, Quận 12, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'high',
        'open',
        NOW() - INTERVAL '4 hours',
        NOW() - INTERVAL '4 hours'
    ),
    -- Violation 6: Illegal dump (another one)
    (
        citizen1_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen1_id),
        (SELECT phone FROM users WHERE id = citizen1_id),
        'violation',
        'illegal_dump',
        'Phát hiện thêm một điểm đổ rác trái phép khác tại khu vực gần trường học. Rác thải có thể ảnh hưởng đến sức khỏe học sinh.',
        ST_SetSRID(ST_MakePoint(106.7020, 10.7780), 4326)::geography,
        'Gần Trường THPT Nguyễn Thị Minh Khai, Quận 3, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400'],
        'high',
        'pending',
        NOW() - INTERVAL '30 minutes',
        NOW() - INTERVAL '30 minutes'
    );

    -- Insert DAMAGE reports (Hư hỏng) from citizens
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
        citizen2_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen2_id),
        (SELECT phone FROM users WHERE id = citizen2_id),
        'damage',
        'broken_bin',
        'Thùng rác gần nhà tôi bị hỏng nắp, không đóng được. Mỗi khi có gió, rác bay ra ngoài gây mất vệ sinh. Mong được sửa chữa sớm.',
        ST_SetSRID(ST_MakePoint(106.6810, 10.7710), 4326)::geography,
        'Đường Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400', 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400'],
        'medium',
        'pending',
        NOW() - INTERVAL '2 hours',
        NOW() - INTERVAL '2 hours'
    ),
    -- Damage 2: Missed collection
    (
        citizen3_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen3_id),
        (SELECT phone FROM users WHERE id = citizen3_id),
        'damage',
        'missed_collection',
        'Xe thu gom đã bỏ sót nhà tôi trong lần thu gom hôm nay. Rác đã để từ sáng nhưng không được thu gom. Mong được xử lý.',
        ST_SetSRID(ST_MakePoint(106.6710, 10.7610), 4326)::geography,
        '789 Đường Pasteur, Quận 3, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'medium',
        'open',
        NOW() - INTERVAL '5 hours',
        NOW() - INTERVAL '3 hours'
    ),
    -- Damage 3: Overflow
    (
        citizen4_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen4_id),
        (SELECT phone FROM users WHERE id = citizen4_id),
        'damage',
        'overflow',
        'Thùng rác tại khu chung cư đã đầy và tràn ra ngoài. Rác thải nằm rải rác xung quanh thùng, gây mất vệ sinh. Cần thu gom ngay.',
        ST_SetSRID(ST_MakePoint(106.7110, 10.7910), 4326)::geography,
        'Chung cư Vinhomes, Quận 7, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400', 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'high',
        'in_progress',
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '10 hours'
    ),
    -- Damage 4: Road damage
    (
        citizen5_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen5_id),
        (SELECT phone FROM users WHERE id = citizen5_id),
        'damage',
        'road_damage',
        'Đường vào khu vực nhà tôi bị sụt lún, có ổ gà lớn. Xe thu gom rác khó di chuyển vào, có thể ảnh hưởng đến việc thu gom. Cần sửa chữa đường.',
        ST_SetSRID(ST_MakePoint(106.6510, 10.7510), 4326)::geography,
        'Đường Nguyễn Văn Cừ, Quận 5, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400'],
        'medium',
        'open',
        NOW() - INTERVAL '3 days',
        NOW() - INTERVAL '2 days'
    ),
    -- Damage 5: Broken bin (another one)
    (
        citizen1_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen1_id),
        (SELECT phone FROM users WHERE id = citizen1_id),
        'damage',
        'broken_bin',
        'Thùng rác tại công viên bị vỡ, không thể sử dụng được. Người dân phải để rác bên cạnh thùng, gây mất mỹ quan.',
        ST_SetSRID(ST_MakePoint(106.6760, 10.7660), 4326)::geography,
        'Công viên Lê Văn Tám, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1611273426858-450d8e3c9fce?w=400'],
        'medium',
        'resolved',
        NOW() - INTERVAL '4 days',
        NOW() - INTERVAL '2 days'
    ),
    -- Damage 6: Overflow (another one)
    (
        citizen2_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen2_id),
        (SELECT phone FROM users WHERE id = citizen2_id),
        'damage',
        'overflow',
        'Thùng rác tại chợ đã đầy và tràn ra ngoài từ sáng sớm. Rác thải ướt chảy ra đường, gây mất vệ sinh và cản trở giao thông.',
        ST_SetSRID(ST_MakePoint(106.6660, 10.7520), 4326)::geography,
        'Chợ Tân Định, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=400', 'https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'urgent',
        'open',
        NOW() - INTERVAL '8 hours',
        NOW() - INTERVAL '8 hours'
    ),
    -- Damage 7: Missed collection (another one)
    (
        citizen3_id,
        (SELECT profile->>'name' FROM users WHERE id = citizen3_id),
        (SELECT phone FROM users WHERE id = citizen3_id),
        'damage',
        'missed_collection',
        'Xe thu gom đã bỏ sót khu vực nhà tôi trong 2 ngày liên tiếp. Rác đã tích tụ nhiều, gây mùi hôi và thu hút ruồi muỗi.',
        ST_SetSRID(ST_MakePoint(106.6720, 10.7620), 4326)::geography,
        'Khu phố 2, Phường Đa Kao, Quận 1, TP.HCM',
        ARRAY['https://images.unsplash.com/photo-1621451537084-482c73073a0f?w=400'],
        'high',
        'closed',
        NOW() - INTERVAL '5 days',
        NOW() - INTERVAL '3 days'
    );

    RAISE NOTICE 'Đã thêm dữ liệu test cho báo cáo người dân thành công!';
END $$;

-- Migration completed
SELECT 'Migration 015: Seeded citizen incident reports' as status;

