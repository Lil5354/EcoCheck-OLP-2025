# EcoCheck Database Migration Script (PowerShell)
# MIT License - Copyright (c) 2025 Lil5354

$ErrorActionPreference = "Stop"

# Database connection parameters
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "ecocheck" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "ecocheck_user" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "ecocheck_pass" }

# Set password environment variable for psql
$env:PGPASSWORD = $DB_PASSWORD

Write-Host "========================================" -ForegroundColor Green
Write-Host "EcoCheck Database Migration" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if psql is available
try {
    $null = Get-Command psql -ErrorAction Stop
} catch {
    Write-Host "Error: psql command not found" -ForegroundColor Red
    Write-Host "Please install PostgreSQL client tools and add them to PATH"
    exit 1
}

# Check database connection
Write-Host "Checking database connection..." -ForegroundColor Yellow
try {
    $testQuery = "SELECT 1;"
    $null = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $testQuery 2>&1
    Write-Host "✓ Database connection successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Cannot connect to database" -ForegroundColor Red
    Write-Host "Please check your connection parameters:"
    Write-Host "  Host: $DB_HOST"
    Write-Host "  Port: $DB_PORT"
    Write-Host "  Database: $DB_NAME"
    Write-Host "  User: $DB_USER"
    exit 1
}

Write-Host ""

# Function to run a migration file
function Run-Migration {
    param(
        [string]$File,
        [string]$Description
    )
    
    Write-Host "Running: $Description" -ForegroundColor Yellow
    Write-Host "  File: $File"
    
    try {
        $null = & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $File 2>&1
        Write-Host "✓ Success" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed" -ForegroundColor Red
        Write-Host "Error running migration: $File"
        Write-Host $_.Exception.Message
        exit 1
    }
    
    Write-Host ""
}

# Run migrations in order
Write-Host "Starting migrations..." -ForegroundColor Green
Write-Host ""

# Check if we're in the correct directory
if (-not (Test-Path "migrations")) {
    Write-Host "Error: migrations directory not found" -ForegroundColor Red
    Write-Host "Please run this script from the db directory"
    exit 1
}

# Initialize extensions (if init directory exists)
if ((Test-Path "init") -and (Test-Path "init/01_init_extensions.sql")) {
    Run-Migration -File "init/01_init_extensions.sql" -Description "Initialize database extensions"
}

# Run main migrations
Run-Migration -File "migrations/001_init.sql" -Description "001: Initialize base schema"
Run-Migration -File "migrations/002_comprehensive_schema.sql" -Description "002: Comprehensive schema enhancement"
Run-Migration -File "migrations/003_seed_badges.sql" -Description "003: Seed gamification badges"
Run-Migration -File "migrations/004_enhanced_seed_data.sql" -Description "004: Seed master data and users"
Run-Migration -File "migrations/005_seed_addresses_points.sql" -Description "005: Seed addresses and collection points"
Run-Migration -File "migrations/006_seed_checkins_operations.sql" -Description "006: Seed check-ins and operations"
Run-Migration -File "migrations/007_seed_routes_billing.sql" -Description "007: Seed routes and billing data"

Write-Host "========================================" -ForegroundColor Green
Write-Host "All migrations completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Display summary
Write-Host "Database Summary:" -ForegroundColor Yellow
$summaryQuery = @"
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 10;
"@
& psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $summaryQuery

Write-Host ""
Write-Host "Record Counts:" -ForegroundColor Yellow
$countQuery = @"
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
"@
& psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $countQuery

Write-Host ""
Write-Host "Database setup complete!" -ForegroundColor Green
Write-Host "Connection string: postgresql://$DB_USER`:****@$DB_HOST`:$DB_PORT/$DB_NAME"

