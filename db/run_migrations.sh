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

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Checking database connection...${NC}"
retries=15
while [ $retries -gt 0 ]; do
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Database connection successful${NC}"
        break
    fi
    retries=$((retries-1))
    echo "Waiting for database... ($retries retries left)"
    sleep 1
done

if [ $retries -eq 0 ]; then
    echo -e "${RED}✗ Could not connect to database after several attempts.${NC}"
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
# The script now automatically runs all .sql files in the migrations directory.
# A schema_migrations table is used to track which migrations have been applied.

# Create migrations tracking table if it doesn't exist
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE TABLE IF NOT EXISTS schema_migrations (version VARCHAR(255) PRIMARY KEY);" > /dev/null

for file in migrations/*.sql; do
    version=$(basename "$file")

    # Check if migration has already been run
    if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT version FROM schema_migrations WHERE version = '$version'" | grep -q "$version"; then
        echo -e "${GREEN}✓ Skipping already applied migration: $version${NC}"
    else
        description=$(echo "$version" | sed -e 's/^[0-9]*_//' -e 's/\.sql$//' -e 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1;')
        run_migration "$file" "$description"
        # Record the migration
        psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "INSERT INTO schema_migrations (version) VALUES ('$version');" > /dev/null
    fi
done


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

