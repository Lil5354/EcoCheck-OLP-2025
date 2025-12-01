# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Complete Deployment Script - Deploy từ đầu đến cuối (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "🚀 EcoCheck Complete Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we're in the project directory
if (-not (Test-Path "docker-compose.prod.yml")) {
    Write-Host "❌ Không tìm thấy docker-compose.prod.yml" -ForegroundColor Red
    Write-Host "Vui lòng chạy script từ thư mục gốc của dự án" -ForegroundColor Red
    exit 1
}

# Get server IP
Write-Host "🌐 Lấy thông tin server..." -ForegroundColor Blue
try {
    $SERVER_IP = (Invoke-WebRequest -Uri "http://ifconfig.me" -UseBasicParsing -TimeoutSec 5).Content.Trim()
} catch {
    try {
        $SERVER_IP = (Invoke-WebRequest -Uri "http://icanhazip.com" -UseBasicParsing -TimeoutSec 5).Content.Trim()
    } catch {
        $SERVER_IP = ""
    }
}

if ([string]::IsNullOrWhiteSpace($SERVER_IP)) {
    $SERVER_IP = Read-Host "🌐 Nhập IP hoặc domain của server"
} else {
    $CUSTOM_IP = Read-Host "🌐 Nhập IP hoặc domain của server (Enter để dùng $SERVER_IP)"
    if (-not [string]::IsNullOrWhiteSpace($CUSTOM_IP)) {
        $SERVER_IP = $CUSTOM_IP
    }
}

if ([string]::IsNullOrWhiteSpace($SERVER_IP)) {
    Write-Host "❌ Server IP không được để trống" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Sử dụng server: $SERVER_IP" -ForegroundColor Green

# Set environment
$env:VITE_API_URL = "http://$SERVER_IP:3000"

# Cleanup old resources
Write-Host "🧹 Dọn dẹp Docker cache..." -ForegroundColor Yellow
docker system prune -f 2>$null
docker image prune -f 2>$null

# Stop existing containers
Write-Host "🛑 Dừng containers cũ..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml down 2>$null

# Build images
Write-Host "🔨 Build images..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml build --no-cache

# Start services
Write-Host "🚀 Khởi động services..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d

# Wait for services
Write-Host "⏳ Đợi services khởi động (30 giây)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check health
Write-Host "🏥 Kiểm tra health..." -ForegroundColor Yellow
$maxRetries = 30
$retryCount = 0
$healthy = $false

while ($retryCount -lt $maxRetries) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Backend is healthy!" -ForegroundColor Green
            $healthy = $true
            break
        }
    } catch {
        # Continue retrying
    }
    $retryCount++
    Write-Host "Đợi backend... ($retryCount/$maxRetries)" -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

if (-not $healthy) {
    Write-Host "⚠️  Backend chưa healthy sau $maxRetries lần thử" -ForegroundColor Yellow
    Write-Host "Kiểm tra logs: docker-compose -f docker-compose.prod.yml logs backend" -ForegroundColor Yellow
}

# Show status
Write-Host ""
Write-Host "📊 Trạng thái services:" -ForegroundColor Blue
docker-compose -f docker-compose.prod.yml ps

# Test endpoints
Write-Host ""
Write-Host "🧪 Kiểm tra endpoints:" -ForegroundColor Blue
Write-Host -NoNewline "  - Health: "
try {
    $health = Invoke-WebRequest -Uri "http://localhost:3000/health" -UseBasicParsing -TimeoutSec 2
    if ($health.Content -match "ok") {
        Write-Host "✅ OK" -ForegroundColor Green
    } else {
        Write-Host "❌ FAIL" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ FAIL" -ForegroundColor Red
}

Write-Host -NoNewline "  - API Status: "
try {
    $status = Invoke-WebRequest -Uri "http://localhost:3000/api/status" -UseBasicParsing -TimeoutSec 2
    Write-Host "✅ OK" -ForegroundColor Green
} catch {
    Write-Host "❌ FAIL" -ForegroundColor Red
}

# Final summary
Write-Host ""
Write-Host "✅✅✅ DEPLOYMENT HOÀN TẤT! ✅✅✅" -ForegroundColor Green
Write-Host ""
Write-Host "📱 URLs của bạn:" -ForegroundColor Blue
Write-Host "  - Backend API: http://$SERVER_IP:3000"
Write-Host "  - Frontend Web: http://$SERVER_IP:3001"
Write-Host "  - Health Check: http://$SERVER_IP:3000/health"
Write-Host ""
Write-Host "📝 Cập nhật Mobile App:" -ForegroundColor Blue
Write-Host "  File: frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart"
Write-Host "  Thay đổi:"
Write-Host "    static const String baseUrl = 'http://$SERVER_IP:3000';"
Write-Host ""
Write-Host "💡 Lệnh hữu ích:" -ForegroundColor Yellow
Write-Host "  - Xem logs: docker-compose -f docker-compose.prod.yml logs -f"
Write-Host "  - Restart: docker-compose -f docker-compose.prod.yml restart"
Write-Host "  - Stop: docker-compose -f docker-compose.prod.yml down"
Write-Host "  - Cleanup: .\scripts\cleanup-docker.ps1"
Write-Host ""

