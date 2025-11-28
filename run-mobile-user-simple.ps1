# Script đơn giản chạy Mobile App User
# EcoCheck OLP 2025

Write-Host "Chay Mobile App User..." -ForegroundColor Cyan
Write-Host ""

# Thêm Flutter vào PATH
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

# Chuyển đến thư mục mobile app User
$currentPath = Get-Location
$mobileUserPath = Join-Path $currentPath "frontend-mobile\EcoCheck_User"

if (-not (Test-Path $mobileUserPath)) {
    Write-Host "ERROR: Khong tim thay thu muc: $mobileUserPath" -ForegroundColor Red
    Write-Host "Dang thu muc hien tai: $currentPath" -ForegroundColor Yellow
    exit 1
}

Set-Location $mobileUserPath
Write-Host "Da chuyen den: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Kiểm tra Flutter
Write-Host "Kiem tra Flutter..." -ForegroundColor Yellow
flutter --version | Select-Object -First 1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter khong tim thay!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Cài đặt dependencies nếu cần
if (-not (Test-Path "pubspec.lock")) {
    Write-Host "Cai dat dependencies..." -ForegroundColor Cyan
    flutter pub get
}
Write-Host ""

# Chạy app
Write-Host "Chay mobile app tren Windows..." -ForegroundColor Green
Write-Host "Qua trinh build co the mat 2-5 phut..." -ForegroundColor Yellow
Write-Host ""

flutter run -d windows


