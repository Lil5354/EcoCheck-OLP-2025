# Script chạy Frontend Web và mở trình duyệt
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHẠY FRONTEND WEB - ECOCHECK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Node.js
Write-Host "[1/3] Kiểm tra Node.js..." -ForegroundColor Yellow
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js chua duoc cai dat!" -ForegroundColor Red
    Write-Host "   Vui long cai dat Node.js tu https://nodejs.org/" -ForegroundColor Red
    exit 1
}
$nodeVersion = node --version
Write-Host "OK: Node.js $nodeVersion" -ForegroundColor Green
Write-Host ""

# Kiểm tra và cài đặt dependencies
Write-Host "[2/3] Kiểm tra dependencies..." -ForegroundColor Yellow
$webPath = "frontend-web-manager"
if (-not (Test-Path $webPath)) {
    Write-Host "ERROR: Khong tim thay thu muc: $webPath" -ForegroundColor Red
    exit 1
}

Push-Location $webPath

if (-not (Test-Path "node_modules")) {
    Write-Host "Dang cai dat dependencies..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Loi khi cai dat dependencies!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
}
Write-Host "OK: Dependencies da san sang" -ForegroundColor Green
Write-Host ""

# Khởi chạy dev server và mở trình duyệt sau 5 giây
Write-Host "[3/3] Khoi chay Frontend Web..." -ForegroundColor Yellow
Write-Host "URL: http://localhost:5173" -ForegroundColor Cyan
Write-Host ""
Write-Host "Dang khoi dong server... (se mo trinh duyet sau 5 giay)" -ForegroundColor Green
Write-Host ""

# Mở trình duyệt sau 5 giây (sử dụng background job đơn giản hơn)
$job = Start-Job -ScriptBlock {
    Start-Sleep -Seconds 5
    $url = "http://localhost:5173"
    Start-Process $url
}

# Chạy dev server
npm run dev

# Dọn dẹp job nếu server dừng
Remove-Job $job -Force -ErrorAction SilentlyContinue

Pop-Location
