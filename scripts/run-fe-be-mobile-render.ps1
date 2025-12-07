# Script chạy Frontend, Backend và Mobile App (Mobile dùng Render Database)
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHẠY FE + BE + MOBILE (RENDER DB)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptPath) { $scriptPath = $PWD }
$projectRoot = Split-Path -Parent $scriptPath

# Kiểm tra Node.js
Write-Host "[1/5] Kiểm tra Node.js..." -ForegroundColor Yellow
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js chưa được cài đặt!" -ForegroundColor Red
    exit 1
}
Write-Host "OK: Node.js $(node --version)" -ForegroundColor Green
Write-Host ""

# Kiểm tra Flutter
Write-Host "[2/5] Kiểm tra Flutter..." -ForegroundColor Yellow
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

try {
    $null = flutter --version 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Host "OK: Flutter đã sẵn sàng" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter chưa được cài đặt!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Chạy Backend trong terminal mới
Write-Host "[3/5] Khởi động Backend (Local)..." -ForegroundColor Yellow
$backendScript = Join-Path $scriptPath "start-backend.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$backendScript`"" -WindowStyle Normal
Write-Host "✅ Backend đang khởi động trong cửa sổ mới" -ForegroundColor Green
Start-Sleep -Seconds 3
Write-Host ""

# Chạy Frontend Web trong terminal mới
Write-Host "[4/5] Khởi động Frontend Web (Local)..." -ForegroundColor Yellow
$frontendScript = Join-Path $scriptPath "start-frontend.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$frontendScript`"" -WindowStyle Normal
Write-Host "✅ Frontend Web đang khởi động trong cửa sổ mới" -ForegroundColor Green
Start-Sleep -Seconds 3
Write-Host ""

# Chạy Mobile App (dùng Render Database)
Write-Host "[5/5] Khởi động Mobile App (Render Database)..." -ForegroundColor Yellow
Write-Host "⚠️  Mobile App sẽ kết nối với Render Database" -ForegroundColor Cyan
Write-Host "   API URL: https://ecocheck-olp-2025.onrender.com" -ForegroundColor Gray
Write-Host ""

$mobilePath = "$projectRoot\frontend-mobile\EcoCheck_User"
if (-not (Test-Path $mobilePath)) {
    Write-Host "ERROR: Không tìm thấy thư mục: $mobilePath" -ForegroundColor Red
    exit 1
}

Set-Location $mobilePath

# Kiểm tra dependencies
Write-Host "Đang kiểm tra Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Lỗi khi cài đặt Flutter dependencies!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Chạy mobile app trên Chrome (popup)
Write-Host "Đang chạy Mobile App trên Chrome..." -ForegroundColor Green
Write-Host "App sẽ tự động mở trong Chrome khi build xong" -ForegroundColor Cyan
Write-Host ""

flutter run -d chrome

Set-Location $projectRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ ĐÃ KHỞI CHẠY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Frontend Web:  http://localhost:5173" -ForegroundColor Yellow
Write-Host "🔧 Backend API:   http://localhost:3000" -ForegroundColor Yellow
Write-Host "📱 Mobile App:    Đang chạy trên Chrome" -ForegroundColor Yellow
Write-Host ""
Write-Host "📊 Database:" -ForegroundColor Cyan
Write-Host "   - Frontend/Backend: Local database" -ForegroundColor Gray
Write-Host "   - Mobile App:       Render database" -ForegroundColor Gray
Write-Host ""

