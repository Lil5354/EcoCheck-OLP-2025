# Run Migration 015: Create Groups Tables
# EcoCheck OLP 2025

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
Write-Host "Running Migration 015: Create Groups Tables" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if psql is available
if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Host "Error: psql command not found" -ForegroundColor Red
    Write-Host "Please install PostgreSQL client tools or use Docker to run migrations."
    Write-Host ""
    Write-Host "Alternative: Run SQL directly via backend API or pgAdmin"
    exit 1
}

# Check database connection
Write-Host "Checking database connection..." -ForegroundColor Yellow
$testQuery = "SELECT 1;"
& psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $testQuery -v ON_ERROR_STOP=1 > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Cannot connect to database" -ForegroundColor Red
    Write-Host "Please check your connection parameters or if the DB is running."
    exit 1
} else {
    Write-Host "✓ Database connection successful" -ForegroundColor Green
}

Write-Host ""

# Run migration
$migrationFile = "migrations\015_create_groups.sql"
if (-not (Test-Path $migrationFile)) {
    Write-Host "✗ Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Running migration: 015_create_groups.sql" -ForegroundColor Yellow
Write-Host "  File: $migrationFile"
Write-Host ""

& psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $migrationFile -v ON_ERROR_STOP=1
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed running migration" -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "✓ Migration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tables created:" -ForegroundColor Cyan
    Write-Host "  - groups" -ForegroundColor White
    Write-Host "  - group_members" -ForegroundColor White
    Write-Host "  - group_checkins" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Migration 015 completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

