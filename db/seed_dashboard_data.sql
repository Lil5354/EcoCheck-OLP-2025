/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Seed Dashboard Data for Testing
 * Tạo dữ liệu test cho dashboard để hiển thị metrics
 */

-- Seed dữ liệu schedules cho hôm nay và hôm qua để dashboard có số liệu

DO $$
DECLARE
    v_citizen_id UUID;
    v_employee_id UUID;
    v_today DATE := CURRENT_DATE;
    v_yesterday DATE := CURRENT_DATE - INTERVAL '1 day';
    v_scheduled_date TIMESTAMPTZ;
    v_completed_at TIMESTAMPTZ;
    v_total_weight_today NUMERIC := 0;
    v_total_weight_yesterday NUMERIC := 0;
BEGIN
    -- Lấy citizen và employee đầu tiên
    SELECT id INTO v_citizen_id FROM users WHERE role = 'citizen' LIMIT 1;
    SELECT id INTO v_employee_id FROM personnel WHERE status = 'active' LIMIT 1;
    
    -- Nếu chưa có, tạo tạm
    IF v_citizen_id IS NULL THEN
        INSERT INTO users (id, phone, role, status)
        VALUES (gen_random_uuid(), '0900000000', 'citizen', 'active')
        RETURNING id INTO v_citizen_id;
    END IF;
    
    IF v_employee_id IS NULL THEN
        INSERT INTO personnel (id, name, role, phone, status)
        VALUES (gen_random_uuid(), 'Test Worker', 'collector', '0900000000', 'active')
        RETURNING id INTO v_employee_id;
    END IF;
    
    -- ========== SCHEDULES CHO HÔM NAY ==========
    -- Completed schedules (6 schedules) - Tổng: 172.6 kg = 0.17 tấn
    -- Morning
    v_scheduled_date := v_today + INTERVAL '8 hours';
    v_completed_at := v_today + INTERVAL '9 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'morning', 'household', 25.5, 25.5, 'completed', v_employee_id, v_completed_at, 10.7769, 106.7009, '123 Đường Lê Lợi, Q1, HCM');
    v_total_weight_today := v_total_weight_today + 25.5;
    
    v_scheduled_date := v_today + INTERVAL '8 hours 30 minutes';
    v_completed_at := v_today + INTERVAL '9 hours 30 minutes';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'morning', 'recyclable', 18.2, 18.2, 'completed', v_employee_id, v_completed_at, 10.7770, 106.7010, '124 Đường Lê Lợi, Q1, HCM');
    v_total_weight_today := v_total_weight_today + 18.2;
    
    -- Afternoon
    v_scheduled_date := v_today + INTERVAL '14 hours';
    v_completed_at := v_today + INTERVAL '15 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'afternoon', 'household', 32.1, 32.1, 'completed', v_employee_id, v_completed_at, 10.7771, 106.7011, '125 Đường Lê Lợi, Q1, HCM');
    v_total_weight_today := v_total_weight_today + 32.1;
    
    v_scheduled_date := v_today + INTERVAL '14 hours 30 minutes';
    v_completed_at := v_today + INTERVAL '15 hours 30 minutes';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'afternoon', 'bulky', 45.8, 45.8, 'completed', v_employee_id, v_completed_at, 10.7772, 106.7012, '126 Đường Lê Lợi, Q1, HCM');
    v_total_weight_today := v_total_weight_today + 45.8;
    
    -- Evening
    v_scheduled_date := v_today + INTERVAL '18 hours';
    v_completed_at := v_today + INTERVAL '19 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'evening', 'recyclable', 22.3, 22.3, 'completed', v_employee_id, v_completed_at, 10.7773, 106.7013, '127 Đường Lê Lợi, Q1, HCM');
    v_total_weight_today := v_total_weight_today + 22.3;
    
    v_scheduled_date := v_today + INTERVAL '18 hours 30 minutes';
    v_completed_at := v_today + INTERVAL '19 hours 30 minutes';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'evening', 'household', 28.7, 28.7, 'completed', v_employee_id, v_completed_at, 10.7774, 106.7014, '128 Đường Lê Lợi, Q1, HCM');
    v_total_weight_today := v_total_weight_today + 28.7;
    
    -- In progress/assigned schedules (3 schedules) - Chưa completed
    v_scheduled_date := v_today + INTERVAL '9 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'morning', 'household', 20.0, NULL, 'in_progress', v_employee_id, 10.7775, 106.7015, '129 Đường Lê Lợi, Q1, HCM');
    
    v_scheduled_date := v_today + INTERVAL '15 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'afternoon', 'recyclable', 15.0, NULL, 'assigned', v_employee_id, 10.7776, 106.7016, '130 Đường Lê Lợi, Q1, HCM');
    
    v_scheduled_date := v_today + INTERVAL '19 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'evening', 'bulky', 30.0, NULL, 'assigned', v_employee_id, 10.7777, 106.7017, '131 Đường Lê Lợi, Q1, HCM');
    
    -- ========== SCHEDULES CHO HÔM QUA ==========
    -- Completed schedules (3 schedules) - Tổng: 65.5 kg = 0.07 tấn
    v_scheduled_date := v_yesterday + INTERVAL '8 hours';
    v_completed_at := v_yesterday + INTERVAL '9 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'morning', 'household', 20.0, 20.0, 'completed', v_employee_id, v_completed_at, 10.7769, 106.7009, '123 Đường Lê Lợi, Q1, HCM');
    v_total_weight_yesterday := v_total_weight_yesterday + 20.0;
    
    v_scheduled_date := v_yesterday + INTERVAL '14 hours';
    v_completed_at := v_yesterday + INTERVAL '15 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'afternoon', 'recyclable', 15.5, 15.5, 'completed', v_employee_id, v_completed_at, 10.7770, 106.7010, '124 Đường Lê Lợi, Q1, HCM');
    v_total_weight_yesterday := v_total_weight_yesterday + 15.5;
    
    v_scheduled_date := v_yesterday + INTERVAL '18 hours';
    v_completed_at := v_yesterday + INTERVAL '19 hours';
    INSERT INTO schedules (citizen_id, scheduled_date, time_slot, waste_type, estimated_weight, actual_weight, status, employee_id, completed_at, latitude, longitude, address)
    VALUES (v_citizen_id::text, v_scheduled_date, 'evening', 'household', 30.0, 30.0, 'completed', v_employee_id, v_completed_at, 10.7771, 106.7011, '125 Đường Lê Lợi, Q1, HCM');
    v_total_weight_yesterday := v_total_weight_yesterday + 30.0;
    
    RAISE NOTICE '✅ Seeded dashboard data successfully!';
    RAISE NOTICE '   Today: 9 schedules (6 completed, 3 in progress) - Total: % kg', v_total_weight_today;
    RAISE NOTICE '   Yesterday: 3 schedules (all completed) - Total: % kg', v_total_weight_yesterday;
    RAISE NOTICE '   Collection Rate Today: 66.7%% (6/9)';
    RAISE NOTICE '   Today Tons: %.1f t', (v_total_weight_today / 1000);
END $$;

SELECT 'Dashboard data seeded successfully!' as status;

