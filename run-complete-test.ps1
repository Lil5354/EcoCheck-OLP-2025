# Script chạy HOÀN CHỈNH: Backend + Web + Mobile để test liên kết dữ liệu
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHẠY HOÀN CHỈNH ĐỂ TEST LIÊN KẾT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptPath) { $scriptPath = $PWD }

# Kiểm tra Node.js
Write-Host "[1/4] Kiểm tra Node.js..." -ForegroundColor Yellow
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js chua duoc cai dat!" -ForegroundColor Red
    exit 1
}
$nodeVersion = node --version
Write-Host "OK: Node.js $nodeVersion" -ForegroundColor Green
Write-Host ""

# Kiểm tra Docker/PostgreSQL
Write-Host "[2/4] Kiem tra Database..." -ForegroundColor Yellow
$dbCheck = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue
if ($dbCheck.TcpTestSucceeded) {
    Write-Host "OK: PostgreSQL dang chay" -ForegroundColor Green
} else {
    Write-Host "WARNING: PostgreSQL khong chay tren port 5432" -ForegroundColor Yellow
    Write-Host "   Dang khoi dong Docker services..." -ForegroundColor Cyan
    docker compose up -d postgres 2>&1 | Out-Null
    Start-Sleep -Seconds 3
    Write-Host "   Da khoi dong Docker services" -ForegroundColor Green
}
Write-Host ""

# Khởi động Backend
Write-Host "[3/4] Khoi dong Backend API..." -ForegroundColor Yellow
$backendScript = @"
cd '$scriptPath\backend'
`$env:NODE_ENV = 'development'
`$env:PORT = '3000'
`$env:DATABASE_URL = 'postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck'
`$env:ORION_LD_URL = 'http://localhost:1026'
if (-not (Test-Path 'node_modules')) {
    Write-Host 'Cai dat backend dependencies...' -ForegroundColor Cyan
    npm install
}
Write-Host 'Backend API: http://localhost:3000' -ForegroundColor Green
npm run dev
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendScript
Write-Host "OK: Backend dang khoi dong trong cua so rieng" -ForegroundColor Green
Start-Sleep -Seconds 5
Write-Host ""

# Khởi động Frontend Web
Write-Host "[4/4] Khoi dong Frontend Web..." -ForegroundColor Yellow
$webScript = Join-Path $scriptPath "run-frontend-web.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$webScript`""
Write-Host "OK: Frontend Web dang khoi dong trong cua so rieng" -ForegroundColor Green
Start-Sleep -Seconds 3
Write-Host ""

# Khởi động Mobile Worker
Write-Host "Khoi dong Mobile App Worker..." -ForegroundColor Yellow
$mobileWorkerScript = Join-Path $scriptPath "run-mobile-worker.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$mobileWorkerScript`""
Write-Host "OK: Mobile Worker dang khoi dong trong cua so rieng" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DA KHOI DONG TAT CA!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API:     http://localhost:3000" -ForegroundColor Yellow
Write-Host "   Health:       http://localhost:3000/health" -ForegroundColor Gray
Write-Host ""
Write-Host "Frontend Web:    http://localhost:5173" -ForegroundColor Yellow
Write-Host "   (Trinh duyet se tu dong mo sau 5 giay)" -ForegroundColor Gray
Write-Host ""
Write-Host "Mobile Worker:   Dang chay trong cua so PowerShell rieng" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  THONG TIN KET NOI" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Mobile app ket noi toi Backend qua:" -ForegroundColor Cyan
Write-Host "   - Windows Desktop: http://localhost:3000" -ForegroundColor White
Write-Host "   - Android Emulator: http://10.0.2.2:3000" -ForegroundColor White
Write-Host "   - iOS Simulator: http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "Web app ket noi toi Backend qua proxy:" -ForegroundColor Cyan
Write-Host "   - Frontend: http://localhost:5173" -ForegroundColor White
Write-Host "   - Backend:  http://localhost:3000/api" -ForegroundColor White
Write-Host ""
Write-Host "Dang kiem tra trang thai services..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Kiểm tra trạng thái
Write-Host ""
Write-Host "Kiem tra Backend API..." -ForegroundColor Yellow
try {
    $backendCheck = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($backendCheck.StatusCode -eq 200) {
        Write-Host "OK: Backend API dang chay!" -ForegroundColor Green
    }
} catch {
    Write-Host "INFO: Backend dang khoi dong, vui long doi them vai giay..." -ForegroundColor Yellow
}

try {
    $webCheck = Invoke-WebRequest -Uri "http://localhost:5173" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($webCheck.StatusCode -eq 200) {
        Write-Host "OK: Frontend Web dang chay!" -ForegroundColor Green
    }
} catch {
    Write-Host "INFO: Frontend Web dang khoi dong..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SAN SANG TEST LIEN KET DU LIEU!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Luu y:" -ForegroundColor Yellow
Write-Host "   - Tat ca cac service dang chay trong cac cua so PowerShell rieng" -ForegroundColor Gray
Write-Host "   - De dung, dong cac cua so PowerShell tuong ung" -ForegroundColor Gray
Write-Host "   - Mobile app co the mat 2-5 phut de build lan dau tien" -ForegroundColor Gray
Write-Host "   - Kiem tra console trong moi cua so de xem log" -ForegroundColor Gray
Write-Host ""












