# Script khởi chạy Backend, Frontend Web và Mobile Popup
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  KHỞI CHẠY TẤT CẢ SERVICES - ECOCHECK" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra và khởi động PostgreSQL nếu chưa chạy
Write-Host "[1/4] Kiểm tra PostgreSQL..." -ForegroundColor Yellow
$postgresRunning = docker ps --filter "name=ecocheck-postgres" --format "{{.Names}}" | Select-String "ecocheck-postgres"
if (-not $postgresRunning) {
    Write-Host "PostgreSQL chưa chạy. Đang khởi động..." -ForegroundColor Yellow
    docker-compose up -d postgres
    Write-Host "Đang đợi PostgreSQL sẵn sàng..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
    Write-Host "OK: PostgreSQL đã sẵn sàng" -ForegroundColor Green
} else {
    Write-Host "OK: PostgreSQL đang chạy" -ForegroundColor Green
}
Write-Host ""

# Khởi chạy Backend
Write-Host "[2/4] Khởi chạy Backend..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendScript = @"
`$env:NODE_ENV = 'development'
Set-Location '$projectRoot\backend'
Write-Host '🚀 EcoCheck Backend đang khởi động...' -ForegroundColor Green
Write-Host 'Đợi backend kết nối database...' -ForegroundColor Cyan
npm run dev
"@
$backendScript | Out-File -FilePath "$env:TEMP\start-backend.ps1" -Encoding UTF8
Start-Process powershell -ArgumentList "-NoExit", "-File", "$env:TEMP\start-backend.ps1"
Write-Host "OK: Backend đang khởi động trong terminal riêng" -ForegroundColor Green
Write-Host ""

# Đợi backend khởi động
Write-Host "Đợi backend khởi động (10 giây)..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Khởi chạy Frontend Web
Write-Host "[3/4] Khởi chạy Frontend Web..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
$frontendScript = @"
Set-Location '$projectRoot\frontend-web-manager'
Write-Host '🌐 EcoCheck Frontend Web đang khởi động...' -ForegroundColor Green
Write-Host 'URL: http://localhost:5173' -ForegroundColor Cyan
npm run dev
"@
$frontendScript | Out-File -FilePath "$env:TEMP\start-frontend-web.ps1" -Encoding UTF8
Start-Process powershell -ArgumentList "-NoExit", "-File", "$env:TEMP\start-frontend-web.ps1"
Write-Host "OK: Frontend Web đang khởi động trong terminal riêng" -ForegroundColor Green
Write-Host ""

# Đợi frontend khởi động
Write-Host "Đợi frontend khởi động (8 giây)..." -ForegroundColor Cyan
Start-Sleep -Seconds 8

# Khởi chạy Mobile Popup
Write-Host "[4/4] Khởi chạy Mobile App Popup..." -ForegroundColor Yellow
$projectRoot = Split-Path -Parent $PSScriptRoot
$popupScript = @"
Set-Location '$projectRoot'
Write-Host '📱 EcoCheck Mobile App Popup đang khởi động...' -ForegroundColor Green
& '$PSScriptRoot\run-mobile-user-chrome-popup.ps1'
"@
$popupScript | Out-File -FilePath "$env:TEMP\start-popup.ps1" -Encoding UTF8
Start-Process powershell -ArgumentList "-NoExit", "-File", "$env:TEMP\start-popup.ps1"
Write-Host "OK: Mobile Popup đang khởi động trong terminal riêng" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ TẤT CẢ SERVICES ĐÃ ĐƯỢC KHỞI CHẠY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Backend:    http://localhost:3000" -ForegroundColor Cyan
Write-Host "Frontend:   http://localhost:5173" -ForegroundColor Cyan
Write-Host "Mobile App: Sẽ mở trong Chrome" -ForegroundColor Cyan
Write-Host ""
Write-Host "Các terminal riêng đã được mở. Kiểm tra kết nối database trong terminal Backend." -ForegroundColor Yellow

