-- Simple test alerts for CN7
BEGIN;

-- Insert missed_point (open)
INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
SELECT 
  'missed_point',
  p.id,
  'V01',
  NULL, -- route not linked for test
  'critical',
  'open',
  jsonb_build_object('detected_at', NOW(), 'test_data', true, 'note', 'Inserted by db/test_insert_alerts.sql')
FROM points p
LIMIT 1;

-- Insert late_checkin (open)
INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
SELECT 
  'late_checkin',
  p.id,
  'V02',
  NULL,
  'warning',
  'open',
  jsonb_build_object('detected_at', NOW(), 'test_data', true, 'note', 'Inserted by db/test_insert_alerts.sql')
FROM points p
OFFSET 1
LIMIT 1;

-- Show summary
SELECT alert_id, alert_type, severity, status, point_id, vehicle_id, created_at
FROM alerts
ORDER BY alert_id DESC
LIMIT 10;

COMMIT;

