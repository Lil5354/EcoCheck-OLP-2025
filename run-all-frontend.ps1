# Script chạy TẤT CẢ Frontend: Web + Mobile Worker + Mobile User
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHẠY TẤT CẢ FRONTEND" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptPath) { $scriptPath = $PWD }

# Chạy Web trong terminal mới
Write-Host "[1/3] Đang khởi chạy Frontend Web..." -ForegroundColor Green
$webScript = Join-Path $scriptPath "run-frontend-web.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$webScript`""

Start-Sleep -Seconds 3

# Chạy Mobile Worker trong terminal mới
Write-Host "[2/3] Đang khởi chạy Mobile App Worker..." -ForegroundColor Green
$mobileWorkerScript = Join-Path $scriptPath "run-mobile-worker.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$mobileWorkerScript`""

Start-Sleep -Seconds 3

# Chạy Mobile User trong terminal mới
Write-Host "[3/3] Đang khởi chạy Mobile App User..." -ForegroundColor Green
$mobileUserScript = Join-Path $scriptPath "run-mobile-user.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$mobileUserScript`""

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Đã khởi chạy TẤT CẢ!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend Web:     http://localhost:5173" -ForegroundColor Yellow
Write-Host "   (Trình duyệt sẽ tự động mở sau 5 giây)" -ForegroundColor Gray
Write-Host ""
Write-Host "Mobile Worker:    Đang chạy trong cửa sổ PowerShell riêng" -ForegroundColor Yellow
Write-Host "Mobile User:      Đang chạy trong cửa sổ PowerShell riêng" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  THÔNG TIN KẾT NỐI" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API:      http://localhost:3000" -ForegroundColor Cyan
Write-Host "Health Check:     http://localhost:3000/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "Lưu ý:" -ForegroundColor Yellow
Write-Host "   - Tất cả các app đang chạy trong các cửa sổ PowerShell riêng" -ForegroundColor Gray
Write-Host "   - Để dừng, đóng các cửa sổ PowerShell tương ứng" -ForegroundColor Gray
Write-Host "   - Web sẽ tự động mở trình duyệt sau 5 giây" -ForegroundColor Gray
Write-Host "   - Mobile apps sẽ build và chạy (có thể mất 2-5 phút lần đầu)" -ForegroundColor Gray
Write-Host ""
Write-Host "Đang đợi 5 giây để các service khởi động..." -ForegroundColor Cyan
Start-Sleep -Seconds 5


