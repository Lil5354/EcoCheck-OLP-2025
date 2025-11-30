# Script khởi chạy Backend và Frontend Web (Development Mode)
# Sử dụng khi Docker Desktop chưa chạy hoặc muốn chạy trực tiếp

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EcoCheck - Khởi chạy Development" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Node.js
Write-Host "[1/4] Kiểm tra Node.js..." -ForegroundColor Yellow
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js chưa được cài đặt!" -ForegroundColor Red
    Write-Host "   Vui lòng cài đặt Node.js từ https://nodejs.org/" -ForegroundColor Red
    exit 1
}
$nodeVersion = node --version
Write-Host "✅ Node.js $nodeVersion" -ForegroundColor Green
Write-Host ""

# Kiểm tra PostgreSQL (nếu chạy trực tiếp)
Write-Host "[2/4] Kiểm tra kết nối Database..." -ForegroundColor Yellow
$dbCheck = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue
if ($dbCheck.TcpTestSucceeded) {
    Write-Host "✅ PostgreSQL đang chạy trên port 5432" -ForegroundColor Green
} else {
    Write-Host "⚠️  PostgreSQL không chạy trên port 5432" -ForegroundColor Yellow
    Write-Host "   Backend sẽ không thể kết nối database!" -ForegroundColor Yellow
    Write-Host "   Vui lòng khởi động Docker Desktop và chạy: docker compose up -d postgres" -ForegroundColor Yellow
}
Write-Host ""

# Tính đường dẫn root project
$projectRoot = Split-Path -Parent $PSScriptRoot

# Kiểm tra dependencies
Write-Host "[3/4] Kiểm tra dependencies..." -ForegroundColor Yellow
if (-not (Test-Path "$projectRoot\backend\node_modules")) {
    Write-Host "📦 Cài đặt backend dependencies..." -ForegroundColor Cyan
    Push-Location "$projectRoot\backend"
    npm install
    Pop-Location
}
if (-not (Test-Path "$projectRoot\frontend-web-manager\node_modules")) {
    Write-Host "📦 Cài đặt frontend dependencies..." -ForegroundColor Cyan
    Push-Location "$projectRoot\frontend-web-manager"
    npm install
    Pop-Location
}
Write-Host "✅ Dependencies đã sẵn sàng" -ForegroundColor Green
Write-Host ""

# Khởi chạy Backend và Frontend
Write-Host "[4/4] Khởi chạy services..." -ForegroundColor Yellow
Write-Host ""

# Tạo biến môi trường cho backend
$env:NODE_ENV = "development"
$env:PORT = "3000"
$env:DATABASE_URL = "postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck"
$env:ORION_LD_URL = "http://localhost:1026"

# Tính đường dẫn root project
$projectRoot = Split-Path -Parent $PSScriptRoot

# Khởi chạy Backend trong terminal mới
Write-Host "🚀 Khởi chạy Backend trên http://localhost:3000" -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectRoot\backend'; `$env:NODE_ENV='development'; `$env:PORT='3000'; `$env:DATABASE_URL='postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck'; npm run dev"

# Đợi backend khởi động
Start-Sleep -Seconds 3

# Khởi chạy Frontend trong terminal mới
Write-Host "🚀 Khởi chạy Frontend Web trên http://localhost:5173" -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$projectRoot\frontend-web-manager'; npm run dev"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ Đã khởi chạy Backend và Frontend!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📍 Backend API:  http://localhost:3000" -ForegroundColor Yellow
Write-Host "📍 Frontend Web: http://localhost:5173" -ForegroundColor Yellow
Write-Host ""
Write-Host "💡 Lưu ý: Đảm bảo PostgreSQL đang chạy!" -ForegroundColor Cyan
Write-Host "   Nếu chưa có, chạy: docker compose up -d postgres" -ForegroundColor Cyan
Write-Host ""

