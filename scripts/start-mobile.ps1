# Script khởi chạy Mobile App
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EcoCheck - Khởi chạy Mobile App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Flutter
Write-Host "[1/3] Kiểm tra Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✅ Flutter đã cài đặt" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter chưa được cài đặt hoặc chưa có trong PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Vui lòng:" -ForegroundColor Yellow
    Write-Host "  1. Cài đặt Flutter từ https://flutter.dev/docs/get-started/install" -ForegroundColor White
    Write-Host "  2. Thêm Flutter vào PATH" -ForegroundColor White
    Write-Host "  3. Chạy: flutter doctor" -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host ""

# Tính đường dẫn root project
$projectRoot = Split-Path -Parent $PSScriptRoot

# Kiểm tra devices
Write-Host "[2/3] Kiểm tra Flutter devices..." -ForegroundColor Yellow
Push-Location "$projectRoot\frontend-mobile\EcoCheck_Worker"
flutter devices
Write-Host ""

# Khởi chạy app
Write-Host "[3/3] Khởi chạy Mobile App..." -ForegroundColor Yellow
Write-Host "Đang khởi chạy Flutter app..." -ForegroundColor Cyan
Write-Host ""

flutter run

Pop-Location



