-- Migration: Create Groups Management Tables
-- Description: Create tables for group management (groups, group_members, group_checkins)
-- Version: 015
-- Date: 2025-01-28

-- ============================================================================
-- GROUPS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS groups (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  code text UNIQUE,
  description text,
  vehicle_id text REFERENCES vehicles(id) ON DELETE SET NULL,
  route_id uuid REFERENCES routes(id) ON DELETE SET NULL,
  depot_id uuid REFERENCES depots(id) ON DELETE SET NULL,
  operating_area text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  meta jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================================================
-- GROUP MEMBERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_members (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  personnel_id uuid NOT NULL REFERENCES personnel(id) ON DELETE CASCADE,
  role_in_group text DEFAULT 'member' CHECK (role_in_group IN ('leader', 'member')),
  joined_at timestamptz DEFAULT now(),
  left_at timestamptz,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  UNIQUE(group_id, personnel_id) WHERE status = 'active'
);

-- ============================================================================
-- GROUP CHECKINS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS group_checkins (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  group_id uuid NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  route_id uuid REFERENCES routes(id) ON DELETE SET NULL,
  route_stop_id uuid REFERENCES route_stops(id) ON DELETE SET NULL,
  checked_by uuid NOT NULL REFERENCES personnel(id) ON DELETE SET NULL,
  waste_type text NOT NULL CHECK (waste_type IN ('household', 'recyclable', 'bulky')),
  collected_weight_kg numeric(10,2) NOT NULL DEFAULT 0,
  quantity_bags int DEFAULT 0,
  notes text,
  photo_urls text[],
  geom geography(Point,4326),
  checked_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- INDEXES
-- ============================================================================
CREATE INDEX IF NOT EXISTS groups_status_idx ON groups(status);
CREATE INDEX IF NOT EXISTS groups_route_idx ON groups(route_id) WHERE route_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS groups_vehicle_idx ON groups(vehicle_id) WHERE vehicle_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS groups_depot_idx ON groups(depot_id) WHERE depot_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS groups_code_idx ON groups(code) WHERE code IS NOT NULL;

CREATE INDEX IF NOT EXISTS group_members_group_idx ON group_members(group_id);
CREATE INDEX IF NOT EXISTS group_members_personnel_idx ON group_members(personnel_id);
CREATE INDEX IF NOT EXISTS group_members_active_idx ON group_members(group_id, personnel_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS group_members_status_idx ON group_members(status);

CREATE INDEX IF NOT EXISTS group_checkins_group_idx ON group_checkins(group_id);
CREATE INDEX IF NOT EXISTS group_checkins_route_idx ON group_checkins(route_id);
CREATE INDEX IF NOT EXISTS group_checkins_route_stop_idx ON group_checkins(route_stop_id) WHERE route_stop_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS group_checkins_checked_by_idx ON group_checkins(checked_by);
CREATE INDEX IF NOT EXISTS group_checkins_checked_at_idx ON group_checkins(checked_at DESC);
CREATE INDEX IF NOT EXISTS group_checkins_waste_type_idx ON group_checkins(waste_type);
CREATE INDEX IF NOT EXISTS group_checkins_geom_gix ON group_checkins USING GIST(geom);

-- ============================================================================
-- FUNCTION: Auto-generate group code
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_group_code()
RETURNS TRIGGER AS $$
DECLARE
  prefix text;
  counter int;
  new_code text;
BEGIN
  IF NEW.code IS NULL OR NEW.code = '' THEN
    -- Generate code: GRP-{counter}-{date}
    prefix := 'GRP';
    
    -- Find next counter for today
    SELECT COALESCE(MAX(CAST(SUBSTRING(code FROM 'GRP-(\d+)-') AS int)), 0) + 1
    INTO counter
    FROM groups
    WHERE code LIKE prefix || '-%' 
      AND code LIKE '%-' || TO_CHAR(NOW(), 'YYYY-MM-DD');
    
    new_code := prefix || '-' || LPAD(counter::text, 3, '0') || '-' || TO_CHAR(NOW(), 'YYYY-MM-DD');
    NEW.code := new_code;
  END IF;
  
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for auto-generate code
DROP TRIGGER IF EXISTS trigger_generate_group_code ON groups;
CREATE TRIGGER trigger_generate_group_code
  BEFORE INSERT OR UPDATE ON groups
  FOR EACH ROW
  EXECUTE FUNCTION generate_group_code();

-- ============================================================================
-- FUNCTION: Update updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS trigger_update_groups_updated_at ON groups;
CREATE TRIGGER trigger_update_groups_updated_at
  BEFORE UPDATE ON groups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Migration completed
SELECT 'Migration 015: Created groups management tables' as status;

