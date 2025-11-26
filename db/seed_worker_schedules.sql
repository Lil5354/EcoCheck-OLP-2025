-- Create sample schedules assigned to worker for testing
-- Worker ID: 9c3f67d1-dfd9-4678-9769-3de7b1a3ae6e

-- First, ensure worker exists in personnel table and get a citizen
DO $$
DECLARE
    worker_id uuid := '9c3f67d1-dfd9-4678-9769-3de7b1a3ae6e';
    citizen_id varchar(100);
BEGIN
    -- Create worker in personnel table if not exists
    INSERT INTO personnel (id, name, role, phone, email, status, hired_at)
    VALUES (
        worker_id,
        'Nguyễn Văn Worker',
        'collector',
        '0987654321',
        'worker@ecocheck.com',
        'active',
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    -- Get first citizen (citizen_id is varchar in schedules table)
    SELECT id::text INTO citizen_id FROM users WHERE role = 'citizen' LIMIT 1;
    
    -- If no citizen exists, create one
    IF citizen_id IS NULL THEN
        INSERT INTO users (id, phone, role, status, profile)
        VALUES (
            gen_random_uuid(),
            '0911111111',
            'citizen',
            'active',
            jsonb_build_object('name', 'Nguyễn Văn A', 'address', '123 Lê Lợi, Q1, HCM')
        )
        RETURNING id::text INTO citizen_id;
    END IF;

    -- Create 5 sample schedules
    -- Schedule 1: Scheduled for today morning
    INSERT INTO schedules (
        schedule_id, citizen_id, scheduled_date, time_slot, waste_type,
        estimated_weight, latitude, longitude, address,
        status, priority, employee_id, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        citizen_id,
        CURRENT_DATE,
        'morning',
        'organic',
        15.5,
        10.7769,
        106.7009,
        '123 Đường Lê Lợi, Quận 1, TP.HCM',
        'assigned',
        1, -- high priority
        worker_id,
        NOW(),
        NOW()
    );

    -- Schedule 2: Scheduled for today afternoon
    INSERT INTO schedules (
        schedule_id, citizen_id, scheduled_date, time_slot, waste_type,
        estimated_weight, latitude, longitude, address,
        status, priority, employee_id, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        citizen_id,
        CURRENT_DATE,
        'afternoon',
        'recyclable',
        8.0,
        10.7800,
        106.7050,
        '456 Nguyễn Huệ, Quận 1, TP.HCM',
        'assigned',
        0, -- normal priority
        worker_id,
        NOW(),
        NOW()
    );

    -- Schedule 3: Scheduled for tomorrow
    INSERT INTO schedules (
        schedule_id, citizen_id, scheduled_date, time_slot, waste_type,
        estimated_weight, latitude, longitude, address,
        status, priority, employee_id, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        citizen_id,
        CURRENT_DATE + INTERVAL '1 day',
        'morning',
        'general',
        12.0,
        10.7750,
        106.6980,
        '789 Pasteur, Quận 3, TP.HCM',
        'scheduled',
        0,
        worker_id,
        NOW(),
        NOW()
    );

    -- Schedule 4: In progress
    INSERT INTO schedules (
        schedule_id, citizen_id, scheduled_date, time_slot, waste_type,
        estimated_weight, latitude, longitude, address,
        status, priority, employee_id, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        citizen_id,
        CURRENT_DATE,
        'morning',
        'hazardous',
        5.5,
        10.7820,
        106.7100,
        '321 Võ Văn Tần, Quận 3, TP.HCM',
        'in_progress',
        2, -- urgent
        worker_id,
        NOW(),
        NOW()
    );

    -- Schedule 5: Completed yesterday
    INSERT INTO schedules (
        schedule_id, citizen_id, scheduled_date, time_slot, waste_type,
        estimated_weight, actual_weight, latitude, longitude, address,
        status, priority, employee_id, completed_at, created_at, updated_at
    ) VALUES (
        gen_random_uuid(),
        citizen_id,
        CURRENT_DATE - INTERVAL '1 day',
        'afternoon',
        'organic',
        10.0,
        9.5,
        10.7700,
        106.6950,
        '555 Hai Bà Trưng, Quận 1, TP.HCM',
        'completed',
        0,
        worker_id,
        NOW() - INTERVAL '1 day',
        NOW() - INTERVAL '2 days',
        NOW() - INTERVAL '1 day'
    );

    RAISE NOTICE 'Created 5 sample schedules for worker';
END $$;

-- Verify
SELECT 
    schedule_id,
    TO_CHAR(scheduled_date, 'YYYY-MM-DD') as date,
    time_slot,
    waste_type,
    status,
    priority,
    estimated_weight
FROM schedules 
WHERE employee_id = '9c3f67d1-dfd9-4678-9769-3de7b1a3ae6e'
ORDER BY scheduled_date, time_slot;
