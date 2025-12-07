# EcoCheck - Reset and Seed TPHCM Data Script
# Script để reset và seed lại dữ liệu đa dạng chỉ trong TPHCM
# MIT License - Copyright (c) 2025 Lil5354

param(
    [string]$DB_HOST = $env:DB_HOST,
    [string]$DB_PORT = $env:DB_PORT,
    [string]$DB_NAME = $env:DB_NAME,
    [string]$DB_USER = $env:DB_USER,
    [string]$DB_PASSWORD = $env:DB_PASSWORD
)

# Default values nếu không có env vars
if (-not $DB_HOST) { $DB_HOST = "localhost" }
if (-not $DB_PORT) { $DB_PORT = "5432" }
if (-not $DB_NAME) { $DB_NAME = "ecocheck" }
if (-not $DB_USER) { $DB_USER = "ecocheck_user" }
if (-not $DB_PASSWORD) { $DB_PASSWORD = "ecocheck_pass" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESET AND SEED TPHCM DATA" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set PGPASSWORD environment variable
$env:PGPASSWORD = $DB_PASSWORD

Write-Host "Database: $DB_NAME" -ForegroundColor Yellow
Write-Host "Host: $DB_HOST:$DB_PORT" -ForegroundColor Yellow
Write-Host "User: $DB_USER" -ForegroundColor Yellow
Write-Host ""

# Kiểm tra kết nối
Write-Host "Checking database connection..." -ForegroundColor Yellow
$testQuery = "SELECT 1;"
try {
    $result = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $testQuery 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Cannot connect to database!" -ForegroundColor Red
        Write-Host $result -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Database connection successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Error connecting to database: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Xác nhận reset
Write-Host "⚠️  WARNING: This will DELETE all existing data!" -ForegroundColor Red
Write-Host "   Press Ctrl+C to cancel, or Enter to continue..." -ForegroundColor Yellow
$null = Read-Host

Write-Host ""
Write-Host "Running reset and seed script..." -ForegroundColor Yellow
Write-Host ""

# Chạy script SQL
$scriptPath = Join-Path $PSScriptRoot "reset_and_seed_tphcm_data.sql"

if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Script file not found: $scriptPath" -ForegroundColor Red
    exit 1
}

try {
    $output = psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f $scriptPath 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Reset and seed completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host $output -ForegroundColor White
    } else {
        Write-Host "❌ Error running script:" -ForegroundColor Red
        Write-Host $output -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ DONE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

