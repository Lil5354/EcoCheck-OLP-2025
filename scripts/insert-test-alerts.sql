-- CN7 Test Alerts Insertion Script
-- This script manually inserts test alerts into the database
-- Use this if the automated test route method doesn't work

-- Usage:
-- psql -h localhost -U ecocheck_user -d ecocheck -f scripts/insert-test-alerts.sql

BEGIN;

-- Check if alerts table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'alerts') THEN
        RAISE EXCEPTION 'alerts table does not exist. Please run migration 008 first.';
    END IF;
END $$;

-- Check if we have points to reference
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM points LIMIT 1) THEN
        RAISE EXCEPTION 'No points exist in the database. Please seed data first.';
    END IF;
END $$;

-- Insert test missed_point alert (critical)
INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
SELECT 
    'missed_point',
    p.id,
    'V01',
    gen_random_uuid(),
    'critical',
    'open',
    jsonb_build_object(
        'detected_at', NOW(),
        'test_data', true,
        'vehicle_location', jsonb_build_object('lat', 10.78, 'lon', 106.70),
        'note', 'Test alert created by insert-test-alerts.sql'
    )
FROM points p
LIMIT 1;

-- Insert test late_checkin alert (warning)
INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
SELECT 
    'late_checkin',
    p.id,
    'V02',
    gen_random_uuid(),
    'warning',
    'open',
    jsonb_build_object(
        'detected_at', NOW(),
        'test_data', true,
        'note', 'Test late check-in alert'
    )
FROM points p
OFFSET 1
LIMIT 1;

-- Insert an acknowledged alert (to test different statuses)
INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
SELECT 
    'missed_point',
    p.id,
    'V03',
    gen_random_uuid(),
    'critical',
    'acknowledged',
    jsonb_build_object(
        'detected_at', NOW() - INTERVAL '10 minutes',
        'assigned_at', NOW() - INTERVAL '5 minutes',
        'assigned_vehicle_id', 'V04',
        'new_route_id', gen_random_uuid(),
        'test_data', true,
        'note', 'Test acknowledged alert'
    )
FROM points p
OFFSET 2
LIMIT 1;

-- Insert a resolved alert (to test complete lifecycle)
INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
SELECT 
    'missed_point',
    p.id,
    'V04',
    gen_random_uuid(),
    'critical',
    'resolved',
    jsonb_build_object(
        'detected_at', NOW() - INTERVAL '30 minutes',
        'assigned_at', NOW() - INTERVAL '20 minutes',
        'resolved_at', NOW() - INTERVAL '5 minutes',
        'assigned_vehicle_id', 'V02',
        'resolved_by_vehicle', 'V02',
        'test_data', true,
        'note', 'Test resolved alert'
    )
FROM points p
OFFSET 3
LIMIT 1;

COMMIT;

-- Display inserted alerts
SELECT 
    alert_id,
    alert_type,
    severity,
    status,
    vehicle_id,
    created_at,
    details->>'note' as note
FROM alerts
WHERE details->>'test_data' = 'true'
ORDER BY created_at DESC;

-- Summary
SELECT 
    status,
    alert_type,
    COUNT(*) as count
FROM alerts
WHERE details->>'test_data' = 'true'
GROUP BY status, alert_type
ORDER BY status, alert_type;

\echo ''
\echo '✅ Test alerts inserted successfully!'
\echo ''
\echo 'Next steps:'
\echo '1. Refresh the Dynamic Dispatch page: http://localhost:3001/operations/dynamic-dispatch'
\echo '2. You should see the test alerts in the table'
\echo '3. Try clicking "Tạo tuyến mới" on an open alert'
\echo ''
\echo 'To remove test alerts:'
\echo 'DELETE FROM alerts WHERE details->>''test_data'' = ''true'';'
\echo ''

