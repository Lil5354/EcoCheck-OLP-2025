# Script chạy Frontend Web và Mobile App cùng lúc
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CHẠY FRONTEND WEB & MOBILE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Hiển thị menu chọn
Write-Host "Chọn ứng dụng bạn muốn chạy:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Chỉ Frontend Web" -ForegroundColor White
Write-Host "  2. Chỉ Mobile App (Worker)" -ForegroundColor White
Write-Host "  3. Chỉ Mobile App (User)" -ForegroundColor White
Write-Host "  4. Web + Mobile Worker (2 cửa sổ riêng)" -ForegroundColor White
Write-Host "  5. Web + Mobile User (2 cửa sổ riêng)" -ForegroundColor White
Write-Host ""
$choice = Read-Host "Nhập lựa chọn (1-5)"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptPath) { $scriptPath = $PWD }

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "Khoi chay Frontend Web..." -ForegroundColor Green
        Write-Host ""
        & "$scriptPath\run-frontend-web.ps1"
    }
    "2" {
        Write-Host ""
        Write-Host "Khoi chay Mobile App Worker..." -ForegroundColor Green
        Write-Host ""
        & "$scriptPath\run-mobile-worker.ps1"
    }
    "3" {
        Write-Host ""
        Write-Host "Khoi chay Mobile App User..." -ForegroundColor Green
        Write-Host ""
        & "$scriptPath\run-mobile-user.ps1"
    }
    "4" {
        Write-Host ""
        Write-Host "Khoi chay Web + Mobile Worker..." -ForegroundColor Green
        Write-Host ""
        
        $webScript = Join-Path $scriptPath "run-frontend-web.ps1"
        $mobileScript = Join-Path $scriptPath "run-mobile-worker.ps1"
        
        Write-Host "Mo Frontend Web trong cua so moi..." -ForegroundColor Cyan
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$webScript`""
        
        Start-Sleep -Seconds 2
        
        Write-Host "Mo Mobile App Worker trong cua so moi..." -ForegroundColor Cyan
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$mobileScript`""
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Da khoi chay Web va Mobile Worker!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Frontend Web:  http://localhost:5173" -ForegroundColor Yellow
        Write-Host "Mobile Worker: Dang chay trong cua so rieng" -ForegroundColor Yellow
        Write-Host ""
    }
    "5" {
        Write-Host ""
        Write-Host "Khoi chay Web + Mobile User..." -ForegroundColor Green
        Write-Host ""
        
        $webScript = Join-Path $scriptPath "run-frontend-web.ps1"
        $mobileScript = Join-Path $scriptPath "run-mobile-user.ps1"
        
        Write-Host "Mo Frontend Web trong cua so moi..." -ForegroundColor Cyan
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$webScript`""
        
        Start-Sleep -Seconds 2
        
        Write-Host "Mo Mobile App User trong cua so moi..." -ForegroundColor Cyan
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$mobileScript`""
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "  Da khoi chay Web va Mobile User!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Frontend Web: http://localhost:5173" -ForegroundColor Yellow
        Write-Host "Mobile User:  Dang chay trong cua so rieng" -ForegroundColor Yellow
        Write-Host ""
    }
    default {
        Write-Host ""
        Write-Host "ERROR: Lua chon khong hop le!" -ForegroundColor Red
        Write-Host "   Vui long chon tu 1-5" -ForegroundColor Yellow
        exit 1
    }
}
