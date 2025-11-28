# Script test chạy Mobile App đơn giản
# EcoCheck OLP 2025

Write-Host "Test chay Mobile App..." -ForegroundColor Cyan
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
        Write-Host "Tim thay Flutter tai: $path" -ForegroundColor Green
        break
    }
}

# Kiểm tra Flutter
Write-Host "Kiem tra Flutter..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Flutter khong tim thay!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Chuyển đến thư mục mobile app
$mobilePath = "frontend-mobile\EcoCheck_Worker"
if (-not (Test-Path $mobilePath)) {
    Write-Host "ERROR: Khong tim thay thu muc: $mobilePath" -ForegroundColor Red
    exit 1
}

Set-Location $mobilePath
Write-Host "Da chuyen den: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Kiểm tra devices
Write-Host "Kiem tra Flutter devices:" -ForegroundColor Yellow
flutter devices
Write-Host ""

# Chạy app trên Windows
Write-Host "Chay app tren Windows..." -ForegroundColor Green
Write-Host "Qua trinh build co the mat 2-5 phut lan dau tien..." -ForegroundColor Yellow
Write-Host ""

flutter run -d windows


