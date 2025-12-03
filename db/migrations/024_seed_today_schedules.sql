-- Migration: Seed test schedules for today
-- Description: Create test schedules with completed status for today to test Dashboard
-- Version: 024
-- Date: 2025-12-04

-- ============================================================================
-- CREATE TEST SCHEDULES FOR TODAY
-- ============================================================================

-- Get a citizen user ID (or create one if none exists)
DO $$
DECLARE
    test_citizen_id UUID;
    test_employee_id UUID;
    today_date DATE := CURRENT_DATE;
BEGIN
    -- Get or create a test citizen
    SELECT id INTO test_citizen_id FROM users WHERE role = 'citizen' LIMIT 1;
    
    IF test_citizen_id IS NULL THEN
        -- Create a test citizen if none exists
        INSERT INTO users (id, phone, role, status, profile)
        VALUES (
            gen_random_uuid(),
            '0900000000',
            'citizen',
            'active',
            '{"name": "Test Citizen"}'::jsonb
        )
        RETURNING id INTO test_citizen_id;
    END IF;
    
    -- Get an active employee (driver or collector)
    SELECT id INTO test_employee_id 
    FROM personnel 
    WHERE status = 'active' AND role IN ('driver', 'collector')
    LIMIT 1;
    
    -- Create 10 completed schedules for today (morning)
    INSERT INTO schedules (
        schedule_id,
        citizen_id,
        scheduled_date,
        time_slot,
        waste_type,
        estimated_weight,
        actual_weight,
        latitude,
        longitude,
        location,
        address,
        status,
        employee_id,
        completed_at,
        created_at,
        updated_at
    )
    SELECT
        gen_random_uuid(),
        test_citizen_id::TEXT,
        today_date,
        'morning',
        CASE (ROW_NUMBER() OVER ()) % 4
            WHEN 0 THEN 'household'
            WHEN 1 THEN 'recyclable'
            WHEN 2 THEN 'bulky'
            ELSE 'organic'
        END,
        15.0 + (ROW_NUMBER() OVER () * 2.5), -- estimated_weight: 15-40kg
        18.0 + (ROW_NUMBER() OVER () * 3.0), -- actual_weight: 18-48kg (slightly higher)
        10.78 + (random() - 0.5) * 0.1, -- lat: around HCMC center
        106.7 + (random() - 0.5) * 0.1, -- lon: around HCMC center
        ST_SetSRID(ST_MakePoint(
            106.7 + (random() - 0.5) * 0.1,
            10.78 + (random() - 0.5) * 0.1
        ), 4326)::geography,
        'Test Address ' || ROW_NUMBER() OVER () || ', Quận ' || (1 + (ROW_NUMBER() OVER () % 12)) || ', TP.HCM',
        'completed',
        test_employee_id,
        today_date + INTERVAL '8 hours' + (ROW_NUMBER() OVER () * INTERVAL '30 minutes'), -- completed_at: today 8:00-12:30
        today_date - INTERVAL '2 days', -- created 2 days ago
        today_date + INTERVAL '8 hours' + (ROW_NUMBER() OVER () * INTERVAL '30 minutes')
    FROM generate_series(1, 10);
    
    -- Create 5 completed schedules for today (afternoon)
    INSERT INTO schedules (
        schedule_id,
        citizen_id,
        scheduled_date,
        time_slot,
        waste_type,
        estimated_weight,
        actual_weight,
        latitude,
        longitude,
        location,
        address,
        status,
        employee_id,
        completed_at,
        created_at,
        updated_at
    )
    SELECT
        gen_random_uuid(),
        test_citizen_id::TEXT,
        today_date,
        'afternoon',
        CASE (ROW_NUMBER() OVER () + 10) % 4
            WHEN 0 THEN 'household'
            WHEN 1 THEN 'recyclable'
            WHEN 2 THEN 'bulky'
            ELSE 'organic'
        END,
        20.0 + (ROW_NUMBER() OVER () * 3.0), -- estimated_weight: 20-35kg
        22.0 + (ROW_NUMBER() OVER () * 3.5), -- actual_weight: 22-39.5kg
        10.78 + (random() - 0.5) * 0.1,
        106.7 + (random() - 0.5) * 0.1,
        ST_SetSRID(ST_MakePoint(
            106.7 + (random() - 0.5) * 0.1,
            10.78 + (random() - 0.5) * 0.1
        ), 4326)::geography,
        'Test Address ' || (ROW_NUMBER() OVER () + 10) || ', Quận ' || (1 + ((ROW_NUMBER() OVER () + 10) % 12)) || ', TP.HCM',
        'completed',
        test_employee_id,
        today_date + INTERVAL '13 hours' + (ROW_NUMBER() OVER () * INTERVAL '30 minutes'), -- completed_at: today 13:00-15:30
        today_date - INTERVAL '2 days',
        today_date + INTERVAL '13 hours' + (ROW_NUMBER() OVER () * INTERVAL '30 minutes')
    FROM generate_series(1, 5);
    
    -- Create 3 scheduled (not completed) schedules for today
    INSERT INTO schedules (
        schedule_id,
        citizen_id,
        scheduled_date,
        time_slot,
        waste_type,
        estimated_weight,
        latitude,
        longitude,
        location,
        address,
        status,
        employee_id,
        created_at,
        updated_at
    )
    SELECT
        gen_random_uuid(),
        test_citizen_id::TEXT,
        today_date,
        'evening',
        CASE (ROW_NUMBER() OVER () + 15) % 4
            WHEN 0 THEN 'household'
            WHEN 1 THEN 'recyclable'
            WHEN 2 THEN 'bulky'
            ELSE 'organic'
        END,
        12.0 + (ROW_NUMBER() OVER () * 2.0), -- estimated_weight: 12-16kg
        10.78 + (random() - 0.5) * 0.1,
        106.7 + (random() - 0.5) * 0.1,
        ST_SetSRID(ST_MakePoint(
            106.7 + (random() - 0.5) * 0.1,
            10.78 + (random() - 0.5) * 0.1
        ), 4326)::geography,
        'Test Address ' || (ROW_NUMBER() OVER () + 15) || ', Quận ' || (1 + ((ROW_NUMBER() OVER () + 15) % 12)) || ', TP.HCM',
        'scheduled', -- Not completed yet
        test_employee_id,
        today_date - INTERVAL '1 day',
        today_date - INTERVAL '1 day'
    FROM generate_series(1, 3);
    
    RAISE NOTICE '✅ Created test schedules for today (%)', today_date;
    RAISE NOTICE '   - 15 completed schedules (10 morning + 5 afternoon)';
    RAISE NOTICE '   - 3 scheduled (not completed) schedules';
END $$;

-- Verify the data
SELECT 
    COUNT(*) FILTER (WHERE status = 'completed' AND DATE(completed_at) = CURRENT_DATE) as completed_today,
    COUNT(*) FILTER (WHERE status = 'completed' AND DATE(completed_at) = CURRENT_DATE) as total_completed,
    COUNT(*) FILTER (WHERE scheduled_date = CURRENT_DATE) as total_scheduled_today,
    COALESCE(SUM(actual_weight), 0) / 1000.0 as total_tons_today
FROM schedules
WHERE scheduled_date = CURRENT_DATE OR DATE(completed_at) = CURRENT_DATE;

SELECT 'Migration 024: Created test schedules for today' as status;

