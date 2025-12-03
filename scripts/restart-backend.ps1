# PowerShell script to restart backend
# MIT License - Copyright (c) 2025 Lil5354

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🔄 RESTART BACKEND" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running on port 3000
$portProcess = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty OwningProcess -Unique

if ($portProcess) {
    Write-Host "⚠️  Backend đang chạy trên port 3000. Đang dừng..." -ForegroundColor Yellow
    Write-Host "   Process ID: $portProcess" -ForegroundColor Gray
    Stop-Process -Id $portProcess -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "✓ Đã dừng backend" -ForegroundColor Green
    Write-Host ""
}

# Change to backend directory
$backendPath = Join-Path $PSScriptRoot "..\backend"
Set-Location -Path $backendPath

Write-Host "📂 Đang chuyển đến thư mục backend..." -ForegroundColor Cyan
Write-Host "   $(Get-Location)" -ForegroundColor Gray
Write-Host ""

# Check if node_modules exists
if (-not (Test-Path "node_modules")) {
    Write-Host "⚠️  node_modules không tồn tại. Đang cài đặt dependencies..." -ForegroundColor Yellow
    npm install
    Write-Host ""
}

# Start backend
Write-Host "🚀 Đang khởi động backend..." -ForegroundColor Cyan
Write-Host ""

# Start in new window
$currentPath = Get-Location
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$currentPath'; npm run dev"

Write-Host "✓ Backend đã được khởi động trong cửa sổ mới" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Kiểm tra cửa sổ PowerShell mới để xem logs" -ForegroundColor Yellow
Write-Host "   Backend sẽ chạy tại: http://localhost:3000" -ForegroundColor Gray
Write-Host ""
