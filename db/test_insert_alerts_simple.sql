BEGIN;

-- Insert simple alerts without FK dependencies (vehicle_id, route_id set to NULL)
INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
SELECT 'missed_point', p.id, NULL, NULL, 'critical', 'open', jsonb_build_object('detected_at', NOW(), 'test_data', true)
FROM points p
LIMIT 1;

INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
SELECT 'late_checkin', p.id, NULL, NULL, 'warning', 'open', jsonb_build_object('detected_at', NOW(), 'test_data', true)
FROM points p
OFFSET 1
LIMIT 1;

COMMIT;

