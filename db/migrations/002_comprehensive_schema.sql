-- EcoCheck - Comprehensive Schema Enhancement
-- Adds gamification, billing, analytics, and tracking features
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- ENHANCE MASTER DATA TABLES
-- ============================================================================

-- Add columns to depots
ALTER TABLE depots ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE depots ADD COLUMN IF NOT EXISTS capacity_vehicles int DEFAULT 10;
ALTER TABLE depots ADD COLUMN IF NOT EXISTS opening_hours text DEFAULT '18:00-06:00';
ALTER TABLE depots ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE depots ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE depots ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';
ALTER TABLE depots ADD CONSTRAINT depots_status_check CHECK (status IN ('active', 'inactive', 'maintenance'));

-- Add columns to dumps
ALTER TABLE dumps ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE dumps ADD COLUMN IF NOT EXISTS accepted_waste_types text[] DEFAULT ARRAY['household', 'recyclable', 'bulky'];
ALTER TABLE dumps ADD COLUMN IF NOT EXISTS capacity_tons numeric(10,2);
ALTER TABLE dumps ADD COLUMN IF NOT EXISTS opening_hours text DEFAULT '18:00-06:00';
ALTER TABLE dumps ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE dumps ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE dumps ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';
ALTER TABLE dumps ADD CONSTRAINT dumps_status_check CHECK (status IN ('active', 'inactive', 'full'));

-- Add columns to vehicles
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS fuel_type text DEFAULT 'diesel';
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS current_load_kg int DEFAULT 0;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS last_maintenance_at timestamptz;
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE vehicles ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE vehicles ADD CONSTRAINT vehicles_type_check CHECK (type IN ('compactor', 'mini-truck', 'electric-trike', 'specialized'));
ALTER TABLE vehicles ADD CONSTRAINT vehicles_fuel_check CHECK (fuel_type IN ('diesel', 'electric', 'hybrid', 'cng'));
ALTER TABLE vehicles ADD CONSTRAINT vehicles_status_check CHECK (status IN ('available', 'in_use', 'maintenance', 'retired'));
ALTER TABLE vehicles ADD CONSTRAINT vehicles_capacity_check CHECK (capacity_kg > 0);
ALTER TABLE vehicles ADD CONSTRAINT vehicles_load_check CHECK (current_load_kg >= 0);

-- Add columns to personnel
ALTER TABLE personnel ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE personnel ADD COLUMN IF NOT EXISTS certifications text[] DEFAULT '{}';
ALTER TABLE personnel ADD COLUMN IF NOT EXISTS hired_at timestamptz DEFAULT now();
ALTER TABLE personnel ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE personnel ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE personnel ADD CONSTRAINT personnel_role_check CHECK (role IN ('driver', 'collector', 'manager', 'dispatcher', 'supervisor'));
ALTER TABLE personnel ADD CONSTRAINT personnel_status_check CHECK (status IN ('active', 'inactive', 'on_leave'));

-- Add indexes for enhanced columns
CREATE INDEX IF NOT EXISTS vehicles_fuel_type_idx ON vehicles(fuel_type);
CREATE INDEX IF NOT EXISTS personnel_email_idx ON personnel(email) WHERE email IS NOT NULL;

-- ============================================================================
-- ENHANCE USER TABLES
-- ============================================================================

-- Add columns to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile jsonb DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at timestamptz;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('citizen', 'worker', 'manager', 'admin'));
ALTER TABLE users ADD CONSTRAINT users_status_check CHECK (status IN ('active', 'inactive', 'suspended', 'banned'));
ALTER TABLE users ADD CONSTRAINT users_email_unique UNIQUE (email);

-- Add columns to user_addresses
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS address_text text;
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS verified boolean DEFAULT false;
ALTER TABLE user_addresses ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Add columns to points
ALTER TABLE points ADD COLUMN IF NOT EXISTS total_checkins int DEFAULT 0;
ALTER TABLE points ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE points ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE points ADD CONSTRAINT points_level_check CHECK (last_level >= 0 AND last_level <= 1);

-- Add columns to checkins
ALTER TABLE checkins ADD COLUMN IF NOT EXISTS verified boolean DEFAULT false;
ALTER TABLE checkins ADD COLUMN IF NOT EXISTS verified_at timestamptz;
ALTER TABLE checkins ADD COLUMN IF NOT EXISTS verified_by uuid REFERENCES users(id);
ALTER TABLE checkins ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE checkins ADD CONSTRAINT checkins_waste_type_check CHECK (waste_type IN ('household', 'recyclable', 'bulky', 'hazardous', 'organic'));
ALTER TABLE checkins ADD CONSTRAINT checkins_level_check CHECK (filling_level >= 0 AND filling_level <= 1);
ALTER TABLE checkins ADD CONSTRAINT checkins_source_check CHECK (source IN ('mobile_app', 'web', 'api', 'system'));

-- Add indexes
CREATE INDEX IF NOT EXISTS users_email_idx ON users(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS checkins_verified_idx ON checkins(verified) WHERE verified = false;
CREATE INDEX IF NOT EXISTS checkins_waste_type_idx ON checkins(waste_type);

-- Convert checkins to hypertable for time-series optimization
SELECT create_hypertable('checkins', 'created_at', if_not_exists => TRUE, migrate_data => TRUE);

-- ============================================================================
-- GAMIFICATION TABLES
-- ============================================================================

-- User Points (Điểm tích lũy của người dùng)
CREATE TABLE IF NOT EXISTS user_points (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  points int NOT NULL DEFAULT 0 CHECK (points >= 0),
  level int NOT NULL DEFAULT 1 CHECK (level >= 1),
  total_checkins int DEFAULT 0,
  total_recyclable int DEFAULT 0,
  total_bulky int DEFAULT 0,
  streak_days int DEFAULT 0,
  last_checkin_date date,
  meta jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);
CREATE INDEX IF NOT EXISTS user_points_user_idx ON user_points(user_id);
CREATE INDEX IF NOT EXISTS user_points_points_idx ON user_points(points DESC);
CREATE INDEX IF NOT EXISTS user_points_level_idx ON user_points(level DESC);

-- Point Transactions (Lịch sử giao dịch điểm)
CREATE TABLE IF NOT EXISTS point_transactions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  points int NOT NULL,
  type text NOT NULL CHECK (type IN ('earn', 'spend', 'bonus', 'penalty', 'adjustment')),
  reason text NOT NULL,
  reference_id uuid,
  reference_type text,
  meta jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS point_transactions_user_idx ON point_transactions(user_id);
CREATE INDEX IF NOT EXISTS point_transactions_created_idx ON point_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS point_transactions_type_idx ON point_transactions(type);

-- Convert point_transactions to hypertable
SELECT create_hypertable('point_transactions', 'created_at', if_not_exists => TRUE, migrate_data => TRUE);



-- Badges (Huy hiệu)
CREATE TABLE IF NOT EXISTS badges (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  description text,
  icon_url text,
  criteria jsonb NOT NULL,
  points_reward int DEFAULT 0,
  rarity text DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS badges_code_idx ON badges(code);
CREATE INDEX IF NOT EXISTS badges_active_idx ON badges(active) WHERE active = true;

-- User Badges (Huy hiệu của người dùng)
CREATE TABLE IF NOT EXISTS user_badges (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_id uuid NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at timestamptz DEFAULT now(),
  UNIQUE(user_id, badge_id)
);
CREATE INDEX IF NOT EXISTS user_badges_user_idx ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS user_badges_badge_idx ON user_badges(badge_id);
CREATE INDEX IF NOT EXISTS user_badges_earned_idx ON user_badges(earned_at DESC);

-- ============================================================================
-- ENHANCE OPERATIONS TABLES
-- ============================================================================

-- Add columns to routes
ALTER TABLE routes ADD COLUMN IF NOT EXISTS driver_id uuid REFERENCES personnel(id) ON DELETE SET NULL;
ALTER TABLE routes ADD COLUMN IF NOT EXISTS collector_id uuid REFERENCES personnel(id) ON DELETE SET NULL;
ALTER TABLE routes ADD COLUMN IF NOT EXISTS planned_distance_km numeric(10,2);
ALTER TABLE routes ADD COLUMN IF NOT EXISTS actual_distance_km numeric(10,2);
ALTER TABLE routes ADD COLUMN IF NOT EXISTS planned_duration_min int;
ALTER TABLE routes ADD COLUMN IF NOT EXISTS actual_duration_min int;
ALTER TABLE routes ADD COLUMN IF NOT EXISTS optimization_score numeric(5,2);
ALTER TABLE routes ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE routes ADD CONSTRAINT routes_status_check CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled'));

-- Add columns to route_stops
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS actual_arrival_at timestamptz;
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS actual_departure_at timestamptz;
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS collected_waste_type text;
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS collected_weight_kg numeric(10,2);
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS photo_url text;
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE route_stops ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE route_stops ADD CONSTRAINT route_stops_status_check CHECK (status IN ('pending', 'skipped', 'completed', 'failed'));
ALTER TABLE route_stops ADD CONSTRAINT route_stops_seq_check CHECK (seq >= 0);

-- Add columns to incidents
ALTER TABLE incidents ADD COLUMN IF NOT EXISTS priority text DEFAULT 'medium';
ALTER TABLE incidents ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES personnel(id) ON DELETE SET NULL;
ALTER TABLE incidents ADD COLUMN IF NOT EXISTS resolved_at timestamptz;
ALTER TABLE incidents ADD COLUMN IF NOT EXISTS resolution_notes text;
ALTER TABLE incidents ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE incidents ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE incidents ADD CONSTRAINT incidents_type_check CHECK (type IN ('overflow', 'illegal_dump', 'missed_collection', 'vehicle_issue', 'other'));
ALTER TABLE incidents ADD CONSTRAINT incidents_status_check CHECK (status IN ('open', 'in_progress', 'resolved', 'closed', 'rejected'));
ALTER TABLE incidents ADD CONSTRAINT incidents_priority_check CHECK (priority IN ('low', 'medium', 'high', 'urgent'));

-- Add columns to exceptions
ALTER TABLE exceptions ADD COLUMN IF NOT EXISTS meta jsonb DEFAULT '{}';
ALTER TABLE exceptions ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();
ALTER TABLE exceptions ADD CONSTRAINT exceptions_type_check CHECK (type IN ('cannot_collect', 'road_blocked', 'vehicle_breakdown', 'wrong_waste_type', 'other'));
ALTER TABLE exceptions ADD CONSTRAINT exceptions_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'resolved'));

-- Add indexes
CREATE INDEX IF NOT EXISTS routes_driver_idx ON routes(driver_id);
CREATE INDEX IF NOT EXISTS routes_collector_idx ON routes(collector_id);
CREATE INDEX IF NOT EXISTS incidents_assigned_idx ON incidents(assigned_to);
CREATE INDEX IF NOT EXISTS incidents_priority_idx ON incidents(priority);

-- ============================================================================
-- BILLING & PAYT (Pay-As-You-Throw)
-- ============================================================================

-- Billing Cycles (Chu kỳ tính phí)
CREATE TABLE IF NOT EXISTS billing_cycles (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed', 'cancelled')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(start_date, end_date)
);
CREATE INDEX IF NOT EXISTS billing_cycles_dates_idx ON billing_cycles(start_date, end_date);
CREATE INDEX IF NOT EXISTS billing_cycles_status_idx ON billing_cycles(status);

-- User Bills (Hóa đơn người dùng)
CREATE TABLE IF NOT EXISTS user_bills (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  billing_cycle_id uuid NOT NULL REFERENCES billing_cycles(id) ON DELETE CASCADE,
  total_checkins int DEFAULT 0,
  total_weight_estimated_kg numeric(10,2) DEFAULT 0,
  base_fee numeric(10,2) DEFAULT 0,
  variable_fee numeric(10,2) DEFAULT 0,
  discount numeric(10,2) DEFAULT 0,
  total_amount numeric(10,2) NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'overdue', 'cancelled')),
  due_date date,
  paid_at timestamptz,
  payment_method text,
  meta jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, billing_cycle_id)
);
CREATE INDEX IF NOT EXISTS user_bills_user_idx ON user_bills(user_id);
CREATE INDEX IF NOT EXISTS user_bills_cycle_idx ON user_bills(billing_cycle_id);
CREATE INDEX IF NOT EXISTS user_bills_status_idx ON user_bills(status);
CREATE INDEX IF NOT EXISTS user_bills_due_date_idx ON user_bills(due_date);

-- ============================================================================
-- ANALYTICS & TRACKING TABLES
-- ============================================================================

-- Vehicle Tracking (Theo dõi vị trí xe thời gian thực)
CREATE TABLE IF NOT EXISTS vehicle_tracking (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_id text NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
  route_id uuid REFERENCES routes(id) ON DELETE SET NULL,
  geom geography(Point,4326) NOT NULL,
  speed_kmh numeric(5,2),
  heading numeric(5,2),
  accuracy_m numeric(10,2),
  battery_level int,
  meta jsonb DEFAULT '{}',
  recorded_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS vehicle_tracking_vehicle_idx ON vehicle_tracking(vehicle_id);
CREATE INDEX IF NOT EXISTS vehicle_tracking_route_idx ON vehicle_tracking(route_id);
CREATE INDEX IF NOT EXISTS vehicle_tracking_gix ON vehicle_tracking USING GIST(geom);
CREATE INDEX IF NOT EXISTS vehicle_tracking_recorded_idx ON vehicle_tracking(recorded_at DESC);

-- Convert vehicle_tracking to hypertable
SELECT create_hypertable('vehicle_tracking', 'recorded_at', if_not_exists => TRUE, migrate_data => TRUE);

-- System Logs (Nhật ký hệ thống)
CREATE TABLE IF NOT EXISTS system_logs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  level text NOT NULL CHECK (level IN ('debug', 'info', 'warning', 'error', 'critical')),
  category text NOT NULL,
  message text NOT NULL,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  entity_type text,
  entity_id uuid,
  meta jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS system_logs_level_idx ON system_logs(level);
CREATE INDEX IF NOT EXISTS system_logs_category_idx ON system_logs(category);
CREATE INDEX IF NOT EXISTS system_logs_created_idx ON system_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS system_logs_user_idx ON system_logs(user_id);

-- Convert system_logs to hypertable
SELECT create_hypertable('system_logs', 'created_at', if_not_exists => TRUE, migrate_data => TRUE);

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to tables with updated_at
CREATE TRIGGER update_depots_updated_at BEFORE UPDATE ON depots FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dumps_updated_at BEFORE UPDATE ON dumps FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vehicles_updated_at BEFORE UPDATE ON vehicles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_personnel_updated_at BEFORE UPDATE ON personnel FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_addresses_updated_at BEFORE UPDATE ON user_addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_points_updated_at BEFORE UPDATE ON points FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_points_updated_at BEFORE UPDATE ON user_points FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_route_stops_updated_at BEFORE UPDATE ON route_stops FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_incidents_updated_at BEFORE UPDATE ON incidents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_exceptions_updated_at BEFORE UPDATE ON exceptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_bills_updated_at BEFORE UPDATE ON user_bills FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to update point statistics when checkin is created
CREATE OR REPLACE FUNCTION update_point_on_checkin()
RETURNS TRIGGER AS $$
BEGIN
    -- Update point statistics
    UPDATE points
    SET
        last_waste_type = NEW.waste_type,
        last_level = NEW.filling_level,
        last_checkin_at = NEW.created_at,
        total_checkins = total_checkins + 1
    WHERE id = NEW.point_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_point_on_checkin
    AFTER INSERT ON checkins
    FOR EACH ROW
    EXECUTE FUNCTION update_point_on_checkin();

-- Function to award points to users on checkin
CREATE OR REPLACE FUNCTION award_points_on_checkin()
RETURNS TRIGGER AS $$
DECLARE
    points_to_award INT := 10; -- Base points
    current_date DATE := CURRENT_DATE;
    last_date DATE;
    streak INT := 0;
BEGIN
    -- Calculate points based on waste type
    CASE NEW.waste_type
        WHEN 'recyclable' THEN points_to_award := 20;
        WHEN 'bulky' THEN points_to_award := 30;
        WHEN 'hazardous' THEN points_to_award := 25;
        WHEN 'organic' THEN points_to_award := 15;
        ELSE points_to_award := 10;
    END CASE;

    -- Insert or update user_points
    INSERT INTO user_points (user_id, points, total_checkins, last_checkin_date)
    VALUES (NEW.user_id, points_to_award, 1, current_date)
    ON CONFLICT (user_id) DO UPDATE
    SET
        points = user_points.points + points_to_award,
        total_checkins = user_points.total_checkins + 1,
        total_recyclable = CASE WHEN NEW.waste_type = 'recyclable' THEN user_points.total_recyclable + 1 ELSE user_points.total_recyclable END,
        total_bulky = CASE WHEN NEW.waste_type = 'bulky' THEN user_points.total_bulky + 1 ELSE user_points.total_bulky END,
        streak_days = CASE
            WHEN user_points.last_checkin_date = current_date - INTERVAL '1 day' THEN user_points.streak_days + 1
            WHEN user_points.last_checkin_date = current_date THEN user_points.streak_days
            ELSE 1
        END,
        last_checkin_date = current_date,
        level = CASE
            WHEN (user_points.points + points_to_award) >= 1000 THEN 5
            WHEN (user_points.points + points_to_award) >= 500 THEN 4
            WHEN (user_points.points + points_to_award) >= 200 THEN 3
            WHEN (user_points.points + points_to_award) >= 50 THEN 2
            ELSE 1
        END;

    -- Record transaction
    INSERT INTO point_transactions (user_id, points, type, reason, reference_id, reference_type)
    VALUES (NEW.user_id, points_to_award, 'earn', 'Check-in ' || NEW.waste_type, NEW.id, 'checkin');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_award_points_on_checkin
    AFTER INSERT ON checkins
    FOR EACH ROW
    EXECUTE FUNCTION award_points_on_checkin();

-- Success message
SELECT 'Comprehensive schema enhancement completed successfully!' AS message;

