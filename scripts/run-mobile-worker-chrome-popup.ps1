# Script chay Mobile App EcoCheck Worker tren Chrome (Popup)
# EcoCheck OLP 2025

# Khong dung $ErrorActionPreference = "Stop" de tranh dung script neu co warning

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHAY MOBILE APP WORKER - CHROME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiem tra Flutter - giong script cu
Write-Host "[1/3] Kiem tra Flutter..." -ForegroundColor Yellow

# Them Flutter vao PATH neu can
$flutterPaths = @(
    "E:\flutter\flutter\bin",
    "$env:LOCALAPPDATA\flutter\bin",
    "$env:USERPROFILE\flutter\bin"
)

foreach ($path in $flutterPaths) {
    if (Test-Path "$path\flutter.bat") {
        $env:Path += ";$path"
        break
    }
}

# Kiem tra Flutter - dung cach kiem tra giong script cu
try {
    $null = flutter --version 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Host "OK: Flutter da san sang" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter chua duoc cai dat!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Vui long:" -ForegroundColor Yellow
    Write-Host "  1. Cai dat Flutter tu https://flutter.dev/docs/get-started/install" -ForegroundColor White
    Write-Host "  2. Them Flutter vao PATH" -ForegroundColor White
    Write-Host "  3. Chay: flutter doctor" -ForegroundColor White
    exit 1
}
Write-Host ""

# Tính đường dẫn root project
$projectRoot = Split-Path -Parent $PSScriptRoot

# Chuyen den thu muc mobile app
Write-Host "[2/3] Chuyen den thu muc mobile app..." -ForegroundColor Yellow
$mobilePath = "$projectRoot\frontend-mobile\EcoCheck_Worker"
if (-not (Test-Path $mobilePath)) {
    Write-Host "Khong tim thay thu muc: $mobilePath" -ForegroundColor Red
    exit 1
}
Set-Location $mobilePath
Write-Host "OK: Da chuyen den: $mobilePath" -ForegroundColor Green
Write-Host ""

# Kiem tra va cai dat dependencies Flutter
Write-Host "Kiem tra Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
Write-Host ""

# Chay mobile app tren Chrome
Write-Host "[3/3] Dang chay mobile app tren Chrome..." -ForegroundColor Yellow
Write-Host "URL: http://localhost:<port>" -ForegroundColor Cyan
Write-Host ""
Write-Host "Dang build va chay app..." -ForegroundColor Green
Write-Host "App se tu dong mo trong Chrome khi build xong" -ForegroundColor Cyan
Write-Host ""

flutter run -d chrome

Pop-Location

