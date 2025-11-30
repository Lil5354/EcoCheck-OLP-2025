# Script khởi chạy tất cả: Backend, Frontend Web và mở trình duyệt
# EcoCheck OLP 2025

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EcoCheck - Khởi chạy Tất cả Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Kiểm tra và khởi động Docker Services
Write-Host "[1/4] Khởi động Docker Services..." -ForegroundColor Yellow
docker compose up -d
Start-Sleep -Seconds 5
Write-Host "✅ Docker services đã khởi động" -ForegroundColor Green
Write-Host ""

# 2. Kiểm tra Backend và Frontend
Write-Host "[2/4] Kiểm tra Services..." -ForegroundColor Yellow
$backendReady = $false
$frontendReady = $false

$maxRetries = 10
$retryCount = 0

while ($retryCount -lt $maxRetries) {
    if (-not $backendReady) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $backendReady = $true
                Write-Host "✅ Backend API: OK" -ForegroundColor Green
            }
        } catch { }
    }
    
    if (-not $frontendReady) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3001" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $frontendReady = $true
                Write-Host "✅ Frontend Web: OK" -ForegroundColor Green
            }
        } catch { }
    }
    
    if ($backendReady -and $frontendReady) {
        break
    }
    
    $retryCount++
    Start-Sleep -Seconds 1
}

if (-not $backendReady) {
    Write-Host "⚠️  Backend chưa sẵn sàng" -ForegroundColor Yellow
}
if (-not $frontendReady) {
    Write-Host "⚠️  Frontend chưa sẵn sàng" -ForegroundColor Yellow
}
Write-Host ""

# 3. Mở trình duyệt
Write-Host "[3/4] Mở trình duyệt..." -ForegroundColor Yellow
Start-Process "http://localhost:3001"
Start-Sleep -Seconds 1
Write-Host "✅ Đã mở Frontend Web Manager" -ForegroundColor Green
Write-Host ""

# 4. Hiển thị thông tin
Write-Host "[4/4] Thông tin kết nối:" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🌐 WEB PLATFORM" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Frontend Web:  http://localhost:3001" -ForegroundColor Yellow
Write-Host "  Backend API:   http://localhost:3000" -ForegroundColor Yellow
Write-Host "  Health Check:  http://localhost:3000/health" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  📱 MOBILE PLATFORM" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Android Emulator: http://10.0.2.2:3000" -ForegroundColor Yellow
Write-Host "  iOS Simulator:    http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Để chạy Mobile App:" -ForegroundColor White
Write-Host "  1. Mở terminal mới" -ForegroundColor Gray
Write-Host "  2. cd frontend-mobile/EcoCheck_Worker" -ForegroundColor Gray
Write-Host "  3. flutter run" -ForegroundColor Gray
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ HOÀN TẤT!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""



