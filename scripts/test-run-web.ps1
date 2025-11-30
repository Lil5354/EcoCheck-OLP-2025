# Script test chạy Frontend Web đơn giản
# EcoCheck OLP 2025

Write-Host "Test chay Frontend Web..." -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Node.js
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js chua duoc cai dat!" -ForegroundColor Red
    exit 1
}
Write-Host "Node.js version: $(node --version)" -ForegroundColor Green
Write-Host ""

# Chuyển đến thư mục web
$webPath = "frontend-web-manager"
if (-not (Test-Path $webPath)) {
    Write-Host "ERROR: Khong tim thay thu muc: $webPath" -ForegroundColor Red
    exit 1
}

Set-Location $webPath
Write-Host "Da chuyen den: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Cài đặt dependencies nếu cần
if (-not (Test-Path "node_modules")) {
    Write-Host "Cai dat dependencies..." -ForegroundColor Yellow
    npm install
}
Write-Host ""

# Mở trình duyệt sau 5 giây
Write-Host "Se mo trinh duyet sau 5 giay tai: http://localhost:5173" -ForegroundColor Cyan
$job = Start-Job -ScriptBlock {
    Start-Sleep -Seconds 5
    Start-Process "http://localhost:5173"
}

# Chạy dev server
Write-Host "Khoi chay dev server..." -ForegroundColor Green
Write-Host ""

npm run dev












