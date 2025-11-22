-- EcoCheck - Operational schema (PostgreSQL + PostGIS + TimescaleDB)
-- Run after database is created. Requires extensions: postgis, timescaledb, uuid-ossp
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- EXTENSIONS
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Master Data
CREATE TABLE IF NOT EXISTS depots (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  geom geography(Point,4326) NOT NULL,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS depots_gix ON depots USING GIST(geom);

CREATE TABLE IF NOT EXISTS dumps (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  geom geography(Point,4326) NOT NULL,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS dumps_gix ON dumps USING GIST(geom);

CREATE TABLE IF NOT EXISTS vehicles (
  id text PRIMARY KEY,
  plate text UNIQUE NOT NULL,
  type text NOT NULL,
  capacity_kg int NOT NULL,
  accepted_types text[] NOT NULL DEFAULT '{}',
  status text NOT NULL DEFAULT 'available',
  depot_id uuid REFERENCES depots(id),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS personnel (
  id uuid PRIMARY KEY,
  name text NOT NULL,
  role text NOT NULL,
  phone text,
  status text NOT NULL DEFAULT 'active',
  depot_id uuid REFERENCES depots(id),
  created_at timestamptz DEFAULT now()
);

-- Citizen & points
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY,
  phone text UNIQUE,
  vneid text,
  role text NOT NULL DEFAULT 'citizen',
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_addresses (
  id uuid PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  label text,
  geom geography(Point,4326) NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS user_addresses_gix ON user_addresses USING GIST(geom);

CREATE TABLE IF NOT EXISTS points (
  id uuid PRIMARY KEY,
  address_id uuid REFERENCES user_addresses(id) ON DELETE SET NULL,
  geom geography(Point,4326) NOT NULL,
  ghost boolean NOT NULL DEFAULT false,
  last_waste_type text,
  last_level numeric(3,2),
  last_checkin_at timestamptz
);
CREATE INDEX IF NOT EXISTS points_gix ON points USING GIST(geom);

-- Operations
CREATE TABLE IF NOT EXISTS routes (
  id uuid PRIMARY KEY,
  vehicle_id text REFERENCES vehicles(id),
  depot_id uuid REFERENCES depots(id),
  dump_id uuid REFERENCES dumps(id),
  start_at timestamptz,
  end_at timestamptz,
  status text NOT NULL DEFAULT 'planned',
  meta jsonb DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS route_stops (
  id uuid PRIMARY KEY,
  route_id uuid NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
  point_id uuid REFERENCES points(id),
  seq int NOT NULL,
  planned_eta timestamptz,
  status text NOT NULL DEFAULT 'pending',
  actual_at timestamptz,
  reason text
);
CREATE UNIQUE INDEX IF NOT EXISTS route_stops_uniq ON route_stops(route_id, seq);

CREATE TABLE IF NOT EXISTS checkins (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES users(id),
  point_id uuid REFERENCES points(id),
  waste_type text NOT NULL,
  filling_level numeric(3,2) NOT NULL,
  geom geography(Point,4326) NOT NULL,
  photo_url text,
  source text,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS checkins_geom_gix ON checkins USING GIST(geom);
CREATE INDEX IF NOT EXISTS checkins_point_time ON checkins(point_id, created_at DESC);

CREATE TABLE IF NOT EXISTS incidents (
  id uuid PRIMARY KEY,
  reporter_id uuid,
  type text NOT NULL,
  description text,
  geom geography(Point,4326),
  photo_url text,
  status text NOT NULL DEFAULT 'open',
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS incidents_geom_gix ON incidents USING GIST(geom);

CREATE TABLE IF NOT EXISTS exceptions (
  id uuid PRIMARY KEY,
  route_id uuid REFERENCES routes(id),
  stop_id uuid REFERENCES route_stops(id),
  type text,
  reason text,
  photo_url text,
  status text NOT NULL DEFAULT 'pending',
  approved_by uuid,
  approved_at timestamptz,
  plan text,
  scheduled_at timestamptz,
  created_at timestamptz DEFAULT now()
);

