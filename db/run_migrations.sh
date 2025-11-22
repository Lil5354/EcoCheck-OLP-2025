#!/bin/bash
# EcoCheck Database Migration Script
# MIT License - Copyright (c) 2025 Lil5354

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Database connection parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ecocheck}"
DB_USER="${DB_USER:-ecocheck_user}"
DB_PASSWORD="${DB_PASSWORD:-ecocheck_pass}"

# Export password for psql
export PGPASSWORD="$DB_PASSWORD"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}EcoCheck Database Migration${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if PostgreSQL is accessible
echo -e "${YELLOW}Checking database connection...${NC}"
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Cannot connect to database${NC}"
    echo "Please check your connection parameters:"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    exit 1
fi

echo ""

# Function to run a migration file
run_migration() {
    local file=$1
    local description=$2
    
    echo -e "${YELLOW}Running: $description${NC}"
    echo "  File: $file"
    
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Success${NC}"
    else
        echo -e "${RED}✗ Failed${NC}"
        echo "Error running migration: $file"
        exit 1
    fi
    
    echo ""
}

# Run migrations in order
echo -e "${GREEN}Starting migrations...${NC}"
echo ""

# Check if we're in the correct directory
if [ ! -d "migrations" ]; then
    echo -e "${RED}Error: migrations directory not found${NC}"
    echo "Please run this script from the db directory"
    exit 1
fi

# Initialize extensions (if init directory exists)
if [ -d "init" ] && [ -f "init/01_init_extensions.sql" ]; then
    run_migration "init/01_init_extensions.sql" "Initialize database extensions"
fi

# Run main migrations
run_migration "migrations/001_init.sql" "001: Initialize base schema"
run_migration "migrations/002_comprehensive_schema.sql" "002: Comprehensive schema enhancement"
run_migration "migrations/003_seed_badges.sql" "003: Seed gamification badges"
run_migration "migrations/004_enhanced_seed_data.sql" "004: Seed master data and users"
run_migration "migrations/005_seed_addresses_points.sql" "005: Seed addresses and collection points"
run_migration "migrations/006_seed_checkins_operations.sql" "006: Seed check-ins and operations"
run_migration "migrations/007_seed_routes_billing.sql" "007: Seed routes and billing data"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All migrations completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Display summary
echo -e "${YELLOW}Database Summary:${NC}"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
"

echo ""
echo -e "${YELLOW}Record Counts:${NC}"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
SELECT 'depots' as table_name, COUNT(*) as count FROM depots
UNION ALL SELECT 'dumps', COUNT(*) FROM dumps
UNION ALL SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL SELECT 'personnel', COUNT(*) FROM personnel
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'user_addresses', COUNT(*) FROM user_addresses
UNION ALL SELECT 'points', COUNT(*) FROM points
UNION ALL SELECT 'checkins', COUNT(*) FROM checkins
UNION ALL SELECT 'badges', COUNT(*) FROM badges
UNION ALL SELECT 'routes', COUNT(*) FROM routes
UNION ALL SELECT 'incidents', COUNT(*) FROM incidents
UNION ALL SELECT 'billing_cycles', COUNT(*) FROM billing_cycles
ORDER BY count DESC;
"

echo ""
echo -e "${GREEN}Database setup complete!${NC}"
echo "Connection string: postgresql://$DB_USER:****@$DB_HOST:$DB_PORT/$DB_NAME"

