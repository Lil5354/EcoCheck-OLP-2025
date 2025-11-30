# Script chay Mobile App EcoCheck User tren Chrome
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHAY MOBILE APP USER - CHROME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Them Flutter vao PATH neu can
$flutterPaths = @(
    "E:\flutter\flutter\bin",
    "$env:LOCALAPPDATA\flutter\bin",
    "$env:USERPROFILE\flutter\bin"
)

$flutterFound = $false
foreach ($path in $flutterPaths) {
    if (Test-Path "$path\flutter.bat") {
        $env:Path += ";$path"
        $flutterFound = $true
        break
    }
}

# Kiem tra Flutter
Write-Host "[1/3] Kiem tra Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Flutter chua duoc cai dat!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Vui long:" -ForegroundColor Yellow
        Write-Host "  1. Cai dat Flutter tu https://flutter.dev/docs/get-started/install" -ForegroundColor White
        Write-Host "  2. Them Flutter vao PATH" -ForegroundColor White
        Write-Host "  3. Chay: flutter doctor" -ForegroundColor White
        exit 1
    }
    Write-Host "OK: Flutter da san sang" -ForegroundColor Green
} catch {
    Write-Host "Flutter chua duoc cai dat hoac chua co trong PATH" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Chuyen den thu muc mobile app
Write-Host "[2/3] Chuyen den thu muc mobile app..." -ForegroundColor Yellow
$mobilePath = "frontend-mobile\EcoCheck_User"
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
Write-Host "Dang build va chay app (quá trình này có thể mất vài phút)..." -ForegroundColor Green
Write-Host ""

flutter run -d chrome

Pop-Location












