# PowerShell script to run migration 023: Add route_id to schedules
# MIT License - Copyright (c) 2025 Lil5354

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Migration 023: Add route_id to schedules" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Database connection parameters
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "ecocheck" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "ecocheck_user" }
$DB_PASSWORD = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "ecocheck_pass" }

# Check if running in Docker
$inDocker = $false
if ($env:DOCKER_CONTAINER) {
    $inDocker = $true
    Write-Host "Running in Docker container" -ForegroundColor Yellow
}

# Migration file path
$migrationFile = "db/migrations/023_add_route_id_to_schedules.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "Error: Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Migration file: $migrationFile" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is available
$dockerAvailable = Get-Command docker -ErrorAction SilentlyContinue

if ($dockerAvailable) {
    Write-Host "Using Docker to run migration..." -ForegroundColor Yellow
    
    # Check if postgres container is running
    $postgresRunning = docker ps --filter "name=ecocheck-postgres" --format "{{.Names}}" | Select-String "ecocheck-postgres"
    
    if (-not $postgresRunning) {
        # Try alternative container names
        $postgresRunning = docker ps --filter "name=postgres" --format "{{.Names}}" | Select-String "postgres"
    }
    
    if ($postgresRunning) {
        Write-Host "PostgreSQL container is running: $postgresRunning" -ForegroundColor Green
        
        # Get container name
        $containerName = $postgresRunning.ToString().Trim()
        
        # Run migration via Docker
        Write-Host "Running migration..." -ForegroundColor Yellow
        $env:PGPASSWORD = $DB_PASSWORD
        
        # Copy file to container and run, or use stdin
        Get-Content $migrationFile | docker exec -i $containerName psql -U $DB_USER -d $DB_NAME
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ Migration completed successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "What was done:" -ForegroundColor Cyan
            Write-Host "  - Added route_id column to schedules table" -ForegroundColor Gray
            Write-Host "  - Created index on route_id" -ForegroundColor Gray
            Write-Host "  - Added foreign key reference to routes(id)" -ForegroundColor Gray
            Write-Host ""
        } else {
            Write-Host ""
            Write-Host "✗ Migration failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "PostgreSQL container is not running" -ForegroundColor Red
        Write-Host "Please start Docker containers first:" -ForegroundColor Yellow
        Write-Host "  docker compose up -d postgres" -ForegroundColor Gray
        Write-Host "  OR" -ForegroundColor Gray
        Write-Host "  docker compose up -d" -ForegroundColor Gray
        exit 1
    }
} else {
    Write-Host "Docker not found. Trying direct psql connection..." -ForegroundColor Yellow
    
    # Try direct psql connection
    $psqlAvailable = Get-Command psql -ErrorAction SilentlyContinue
    
    if ($psqlAvailable) {
        $env:PGPASSWORD = $DB_PASSWORD
        psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $migrationFile
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✓ Migration completed successfully!" -ForegroundColor Green
            Write-Host ""
            Write-Host "What was done:" -ForegroundColor Cyan
            Write-Host "  - Added route_id column to schedules table" -ForegroundColor Gray
            Write-Host "  - Created index on route_id" -ForegroundColor Gray
            Write-Host "  - Added foreign key reference to routes(id)" -ForegroundColor Gray
            Write-Host ""
        } else {
            Write-Host ""
            Write-Host "✗ Migration failed!" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "Error: Neither Docker nor psql found" -ForegroundColor Red
        Write-Host "Please install Docker or PostgreSQL client tools" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""

