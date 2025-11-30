# Run Migration 018: Seed Dashboard Points
# MIT License - Copyright (c) 2025 Lil5354

$ErrorActionPreference = "Stop"

# Database connection parameters
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "ecocheck" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "ecocheck_user" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "ecocheck_pass" }

# Set password environment variable
$env:PGPASSWORD = $DB_PASSWORD

Write-Host "========================================" -ForegroundColor Green
Write-Host "Running Migration 018" -ForegroundColor Green
Write-Host "Seed Dashboard Points Data" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check if using Docker
$usingDocker = $false
try {
    docker ps --filter "name=postgres" --format "{{.Names}}" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $dockerContainer = docker ps --filter "name=postgres" --format "{{.Names}}" | Select-Object -First 1
        if ($dockerContainer) {
            $usingDocker = $true
            Write-Host "✓ Detected Docker PostgreSQL container: $dockerContainer" -ForegroundColor Green
        }
    }
} catch {
    # Docker not available or not running
}

$migrationFile = "migrations/018_seed_dashboard_points.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "✗ Migration file not found: $migrationFile" -ForegroundColor Red
    Write-Host "Please run this script from the db directory"
    exit 1
}

if ($usingDocker) {
    Write-Host "Running migration via Docker..." -ForegroundColor Yellow
    docker exec -i $dockerContainer psql -U $DB_USER -d $DB_NAME < $migrationFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Migration failed" -ForegroundColor Red
        exit 1
    }
} else {
    # Try direct psql
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        Write-Host "✗ psql not found. Please:" -ForegroundColor Red
        Write-Host "  1. Install PostgreSQL client tools, OR" -ForegroundColor Yellow
        Write-Host "  2. Use Docker: docker exec -i <postgres-container> psql -U $DB_USER -d $DB_NAME < $migrationFile" -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "Running migration via psql..." -ForegroundColor Yellow
    & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $migrationFile -v ON_ERROR_STOP=1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ Migration failed" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "✓ Migration 018 completed successfully!" -ForegroundColor Green
Write-Host ""

# Verify data
Write-Host "Verifying data..." -ForegroundColor Yellow
$verifyQuery = @"
SELECT 
    CASE 
        WHEN ghost = true THEN 'Ghost (Grey)'
        WHEN last_waste_type = 'bulky' THEN 'Bulky/Incident (Red)'
        WHEN last_level >= 0.7 THEN 'High (Orange)'
        ELSE 'Low/Medium (Green)'
    END as point_type,
    COUNT(*) as count
FROM points
GROUP BY 
    CASE 
        WHEN ghost = true THEN 'Ghost (Grey)'
        WHEN last_waste_type = 'bulky' THEN 'Bulky/Incident (Red)'
        WHEN last_level >= 0.7 THEN 'High (Orange)'
        ELSE 'Low/Medium (Green)'
    END
ORDER BY point_type;
"@

if ($usingDocker) {
    docker exec -i $dockerContainer psql -U $DB_USER -d $DB_NAME -c $verifyQuery
} else {
    & psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $verifyQuery
}

Write-Host ""
Write-Host "✅ Dashboard points seeded successfully!" -ForegroundColor Green
Write-Host "Refresh dashboard to see the new points on the map!" -ForegroundColor Cyan
