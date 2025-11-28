# Script chạy mobile app EcoCheck Worker
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🚀 CHẠY MOBILE APP ECOCHECK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Thêm Flutter vào PATH
$env:Path += ";E:\flutter\flutter\bin"

# Kiểm tra Flutter
Write-Host "[1/3] Kiểm tra Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Flutter chưa được cài đặt!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Flutter đã sẵn sàng" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter chưa được cài đặt!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Chuyển đến thư mục mobile app
Write-Host "[2/3] Chuyển đến thư mục mobile app..." -ForegroundColor Yellow
$mobilePath = "frontend-mobile\EcoCheck_Worker"
if (-not (Test-Path $mobilePath)) {
    Write-Host "❌ Không tìm thấy thư mục: $mobilePath" -ForegroundColor Red
    exit 1
}
Set-Location $mobilePath
Write-Host "✅ Đã chuyển đến: $mobilePath" -ForegroundColor Green

Write-Host ""

# Chạy mobile app
Write-Host "[3/3] Đang build và chạy mobile app trên Windows..." -ForegroundColor Yellow
Write-Host "⏳ Quá trình này có thể mất vài phút..." -ForegroundColor Cyan
Write-Host ""

flutter run -d windows


