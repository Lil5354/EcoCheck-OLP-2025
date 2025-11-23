-- 008_create_alerts_table.sql
-- Create alerts table for CN7: Dynamic Dispatch

BEGIN;

CREATE TYPE alert_type AS ENUM ('missed_point', 'late_checkin');
CREATE TYPE alert_severity AS ENUM ('warning', 'critical');
CREATE TYPE alert_status AS ENUM ('open', 'acknowledged', 'resolved');

CREATE TABLE IF NOT EXISTS alerts (
    alert_id SERIAL PRIMARY KEY,
    alert_type alert_type NOT NULL,
    point_id uuid REFERENCES points(id) ON DELETE SET NULL,
    vehicle_id text REFERENCES vehicles(id) ON DELETE SET NULL,
    route_id uuid REFERENCES routes(id) ON DELETE SET NULL,
    severity alert_severity NOT NULL,
    status alert_status NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details JSONB
);

COMMENT ON TABLE alerts IS 'Stores alerts for operational incidents like missed points or late check-ins.';
COMMENT ON COLUMN alerts.alert_type IS 'The type of incident that triggered the alert.';
COMMENT ON COLUMN alerts.point_id IS 'The collection point related to the alert.';
COMMENT ON COLUMN alerts.vehicle_id IS 'The vehicle originally assigned or involved.';
COMMENT ON COLUMN alerts.route_id IS 'The route on which the incident occurred.';
COMMENT ON COLUMN alerts.severity IS 'Severity level of the alert (e.g., warning, critical).';
COMMENT ON COLUMN alerts.status IS 'The lifecycle status of the alert (open, acknowledged, resolved).';
COMMENT ON COLUMN alerts.details IS 'Additional JSON data, e.g., location where the alert was triggered.';

COMMIT;

