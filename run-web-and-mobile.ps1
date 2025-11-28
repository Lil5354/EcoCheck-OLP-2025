# Script chạy nhanh Frontend Web + Mobile Worker cùng lúc
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHẠY WEB + MOBILE CÙNG LÚC" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptPath) { $scriptPath = $PWD }

# Chạy Web trong terminal mới
Write-Host "Đang khởi chạy Frontend Web..." -ForegroundColor Green
$webScript = Join-Path $scriptPath "run-frontend-web.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$webScript`""

Start-Sleep -Seconds 3

# Chạy Mobile Worker trong terminal mới
Write-Host "Đang khởi chạy Mobile App Worker..." -ForegroundColor Green
$mobileScript = Join-Path $scriptPath "run-mobile-worker.ps1"
Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$mobileScript`""

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Đã khởi chạy!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend Web:  http://localhost:5173" -ForegroundColor Yellow
Write-Host "   (Trình duyệt sẽ tự động mở sau 5 giây)" -ForegroundColor Gray
Write-Host ""
Write-Host "Mobile Worker: Đang chạy trong cửa sổ PowerShell riêng" -ForegroundColor Yellow
Write-Host ""
Write-Host "Lưu ý:" -ForegroundColor Cyan
Write-Host "   - Frontend Web và Mobile App đang chạy trong 2 cửa sổ riêng" -ForegroundColor Gray
Write-Host "   - Để dừng, đóng các cửa sổ PowerShell tương ứng" -ForegroundColor Gray
Write-Host ""
Write-Host "Đang đợi 5 giây để xem trạng thái..." -ForegroundColor Cyan
Start-Sleep -Seconds 5
