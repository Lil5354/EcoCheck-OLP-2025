# Script chạy Mobile App EcoCheck User
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHẠY MOBILE APP - ECOCHECK USER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Thêm Flutter vào PATH nếu cần
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

# Kiểm tra Flutter
Write-Host "[1/3] Kiem tra Flutter..." -ForegroundColor Yellow
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

# Chuyển đến thư mục mobile app
Write-Host "[2/3] Chuyen den thu muc mobile app..." -ForegroundColor Yellow
$mobilePath = "$projectRoot\frontend-mobile\EcoCheck_User"
if (-not (Test-Path $mobilePath)) {
    Write-Host "ERROR: Khong tim thay thu muc: $mobilePath" -ForegroundColor Red
    exit 1
}
Set-Location $mobilePath
Write-Host "OK: Da chuyen den: $mobilePath" -ForegroundColor Green
Write-Host ""

# Kiểm tra và cài đặt dependencies Flutter
Write-Host "Kiem tra Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Loi khi cai dat Flutter dependencies!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Kiểm tra devices
Write-Host "[3/3] Kiem tra Flutter devices..." -ForegroundColor Yellow
Write-Host "Dang liet ke cac thiet bi co san..." -ForegroundColor Cyan
flutter devices
Write-Host ""

# Chạy mobile app
Write-Host "Dang build va chay mobile app..." -ForegroundColor Green
Write-Host "Qua trinh nay co the mat vai phut..." -ForegroundColor Cyan
Write-Host ""

# Đơn giản hóa: luôn chạy trên Windows để test
Write-Host "Chay tren Windows..." -ForegroundColor Yellow
flutter run -d windows
