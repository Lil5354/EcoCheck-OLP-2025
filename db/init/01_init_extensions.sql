-- EcoCheck - Initialize Database Extensions
-- This script runs first when the database is created
-- MIT License - Copyright (c) 2025 Lil5354

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- For text search optimization
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- For advanced indexing

-- Verify extensions
SELECT 
    extname AS "Extension Name",
    extversion AS "Version"
FROM pg_extension
WHERE extname IN ('postgis', 'timescaledb', 'uuid-ossp', 'pg_trgm', 'btree_gist')
ORDER BY extname;

-- Success message
SELECT 'Database extensions initialized successfully!' AS message;

