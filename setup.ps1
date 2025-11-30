# EcoCheck Server Setup Script (PowerShell)
# MIT License - Copyright (c) 2025 Lil5354
# One-command setup để khởi động server cho cả Web và Mobile

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ECOCHECK SERVER SETUP" -ForegroundColor Cyan
Write-Host "  Setup tự động cho Web + Mobile" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Kiểm tra Docker
Write-Host "[1/6] Kiểm tra Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker not found"
    }
    Write-Host "✅ Docker: $dockerVersion" -ForegroundColor Green
    
    # Kiểm tra Docker đang chạy
    docker ps | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker Desktop chưa chạy!" -ForegroundColor Red
        Write-Host "   Vui lòng khởi động Docker Desktop và thử lại." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Docker Desktop đang chạy" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker chưa được cài đặt!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Vui lòng cài đặt Docker Desktop từ:" -ForegroundColor Yellow
    Write-Host "   https://www.docker.com/products/docker-desktop" -ForegroundColor White
    exit 1
}
Write-Host ""

# 2. Kiểm tra Docker Compose
Write-Host "[2/6] Kiểm tra Docker Compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker compose version 2>&1
    Write-Host "✅ Docker Compose: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose không tìm thấy!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 3. Dừng containers cũ nếu có
Write-Host "[3/6] Dọn dẹp containers cũ..." -ForegroundColor Yellow
docker compose down 2>&1 | Out-Null
Write-Host "✅ Đã dọn dẹp containers cũ" -ForegroundColor Green
Write-Host ""

# 4. Khởi động Docker Services
Write-Host "[4/6] Khởi động Docker Services..." -ForegroundColor Yellow
Write-Host "   (Quá trình này có thể mất 5-10 phút lần đầu tiên)" -ForegroundColor Gray
Write-Host ""

docker compose up -d --build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Lỗi khi khởi động Docker services!" -ForegroundColor Red
    Write-Host "   Vui lòng kiểm tra logs: docker compose logs" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Docker services đã khởi động" -ForegroundColor Green
Write-Host ""

# 5. Đợi services sẵn sàng
Write-Host "[5/6] Đợi services sẵn sàng..." -ForegroundColor Yellow
$maxWait = 60  # Tối đa 60 giây
$waitCount = 0
$backendReady = $false
$postgresReady = $false

while ($waitCount -lt $maxWait) {
    # Kiểm tra PostgreSQL
    if (-not $postgresReady) {
        try {
            $pgCheck = docker compose exec -T postgres pg_isready -U ecocheck_user -d ecocheck 2>&1
            if ($LASTEXITCODE -eq 0) {
                $postgresReady = $true
                Write-Host "   ✅ PostgreSQL sẵn sàng" -ForegroundColor Green
            }
        } catch { }
    }
    
    # Kiểm tra Backend
    if (-not $backendReady) {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                $backendReady = $true
                Write-Host "   ✅ Backend API sẵn sàng" -ForegroundColor Green
            }
        } catch { }
    }
    
    if ($postgresReady -and $backendReady) {
        break
    }
    
    $waitCount++
    Write-Host "   Đang đợi... ($waitCount/$maxWait giây)" -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

if (-not $postgresReady) {
    Write-Host "⚠️  PostgreSQL chưa sẵn sàng sau $maxWait giây" -ForegroundColor Yellow
    Write-Host "   Migrations có thể chưa chạy xong, vui lòng đợi thêm..." -ForegroundColor Yellow
}

if (-not $backendReady) {
    Write-Host "⚠️  Backend chưa sẵn sàng sau $maxWait giây" -ForegroundColor Yellow
    Write-Host "   Vui lòng kiểm tra logs: docker compose logs backend" -ForegroundColor Yellow
}
Write-Host ""

# 6. Kiểm tra trạng thái cuối cùng
Write-Host "[6/6] Kiểm tra trạng thái services..." -ForegroundColor Yellow
Write-Host ""

# Lấy Local IP cho mobile
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.IPAddress -notlike "127.*" -and 
    $_.IPAddress -notlike "169.254.*" -and
    $_.InterfaceAlias -notlike "*Loopback*"
} | Select-Object -First 1).IPAddress

if (-not $localIP) { $localIP = "localhost" }

# Hiển thị thông tin
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ✅ SETUP HOÀN TẤT!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
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
Write-Host "  Backend API:   http://localhost:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Kết nối từ Mobile App:" -ForegroundColor Cyan
Write-Host "    - Windows Desktop: http://localhost:3000" -ForegroundColor White
Write-Host "    - Android Emulator: http://10.0.2.2:3000" -ForegroundColor White
Write-Host "    - iOS Simulator:    http://localhost:3000" -ForegroundColor White
Write-Host "    - Real Device:      http://$localIP:3000" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🔧 DOCKER SERVICES" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  📋 NEXT STEPS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Test Web Platform:" -ForegroundColor Yellow
Write-Host "   Mở trình duyệt: http://localhost:3001" -ForegroundColor White
Write-Host ""
Write-Host "2. Test Mobile Platform:" -ForegroundColor Yellow
Write-Host "   - Chạy Flutter app (Worker hoặc User)" -ForegroundColor White
Write-Host "   - Đảm bảo baseUrl trong api_constants.dart đúng với platform" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Test cả 2 nền tảng cùng lúc:" -ForegroundColor Yellow
Write-Host "   Chạy: .\test-web-mobile-integration.ps1" -ForegroundColor White
Write-Host ""
Write-Host "4. Xem logs:" -ForegroundColor Yellow
Write-Host "   docker compose logs -f backend" -ForegroundColor White
Write-Host "   docker compose logs -f frontend-web" -ForegroundColor White
Write-Host ""
Write-Host "5. Dừng services:" -ForegroundColor Yellow
Write-Host "   docker compose down" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  🎉 SẴN SÀNG TEST!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""











