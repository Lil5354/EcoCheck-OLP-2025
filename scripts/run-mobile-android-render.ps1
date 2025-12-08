# Script chạy Mobile App trên Android thật (Render Database)
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHẠY MOBILE APP TRÊN ANDROID" -ForegroundColor Cyan
Write-Host "  (Render Database)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptPath) { $scriptPath = $PWD }
$projectRoot = Split-Path -Parent $scriptPath
$mobilePath = "$projectRoot\frontend-mobile\EcoCheck_User"

# Kiểm tra thư mục
if (-not (Test-Path "$mobilePath\pubspec.yaml")) {
    Write-Host "ERROR: Không tìm thấy pubspec.yaml tại: $mobilePath" -ForegroundColor Red
    exit 1
}

Write-Host "[1/3] Kiểm tra Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Host "✅ Flutter đã sẵn sàng" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter chưa được cài đặt!" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "[2/3] Kiểm tra thiết bị Android..." -ForegroundColor Yellow
Set-Location $mobilePath
$devices = flutter devices 2>&1
$androidDevice = $devices | Select-String -Pattern "android" -CaseSensitive:$false

if (-not $androidDevice) {
    Write-Host "⚠️  Không tìm thấy thiết bị Android!" -ForegroundColor Yellow
    Write-Host "Vui lòng:" -ForegroundColor Cyan
    Write-Host "  1. Kết nối thiết bị Android qua USB" -ForegroundColor White
    Write-Host "  2. Bật USB Debugging trên thiết bị" -ForegroundColor White
    Write-Host "  3. Chấp nhận authorization trên thiết bị" -ForegroundColor White
    Write-Host ""
    Write-Host "Danh sách thiết bị hiện tại:" -ForegroundColor Cyan
    flutter devices
    exit 1
}

Write-Host "✅ Tìm thấy thiết bị Android" -ForegroundColor Green
Write-Host ""
Write-Host "Danh sách thiết bị:" -ForegroundColor Cyan
flutter devices
Write-Host ""

Write-Host "[3/3] Khởi chạy app trên Android..." -ForegroundColor Yellow
Write-Host "📱 App sẽ kết nối với Render Database" -ForegroundColor Cyan
Write-Host "   API: https://ecocheck-olp-2025.onrender.com" -ForegroundColor Gray
Write-Host ""
Write-Host "Đang build và cài đặt app (có thể mất 1-3 phút)..." -ForegroundColor Yellow
Write-Host ""

# Chạy flutter run - tự động chọn thiết bị Android đầu tiên
flutter run -d android

Set-Location $projectRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ HOÀN TẤT!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

