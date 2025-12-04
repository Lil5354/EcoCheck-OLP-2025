# Clear All Routes and Schedules
# Purpose: Execute SQL script to remove all routes and schedules data

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Clear All Routes and Schedules Data" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This will delete all route and schedule data!" -ForegroundColor Yellow
Write-Host "Make sure you have a backup if needed." -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "Do you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Operation cancelled." -ForegroundColor Red
    exit 0
}

# Get database connection details from environment or use defaults
$DB_HOST = if ($env:DB_HOST) { $env:DB_HOST } else { "localhost" }
$DB_PORT = if ($env:DB_PORT) { $env:DB_PORT } else { "5432" }
$DB_NAME = if ($env:DB_NAME) { $env:DB_NAME } else { "ecocheck_db" }
$DB_USER = if ($env:DB_USER) { $env:DB_USER } else { "ecocheck_user" }
$DB_PASSWORD = $env:DB_PASSWORD

Write-Host ""
Write-Host "Connecting to database: $DB_NAME on ${DB_HOST}:${DB_PORT}" -ForegroundColor Cyan
Write-Host ""

# Set PGPASSWORD environment variable for psql
$env:PGPASSWORD = $DB_PASSWORD

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sqlFile = Join-Path $scriptDir "clear_all_routes_and_schedules.sql"

# Execute the SQL script
& psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $sqlFile

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "SUCCESS: All routes and schedules cleared!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Go to the web interface" -ForegroundColor White
    Write-Host "2. Create new routes" -ForegroundColor White
    Write-Host "3. Test the collection completion synchronization" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Failed to clear routes and schedules" -ForegroundColor Red
    Write-Host "Please check the error messages above" -ForegroundColor Red
    exit 1
}
