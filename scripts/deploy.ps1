# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Production Deployment Script - Tối ưu dung lượng (PowerShell)

$ErrorActionPreference = "Stop"

Write-Host "🚀 EcoCheck Production Deployment Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker is not installed" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker Compose is not installed" -ForegroundColor Red
    exit 1
}

# Get server IP or domain
$SERVER_URL = Read-Host "🌐 Nhập IP hoặc domain của server (ví dụ: 192.168.1.100 hoặc api.example.com)"

if ([string]::IsNullOrWhiteSpace($SERVER_URL)) {
    Write-Host "❌ Server URL không được để trống" -ForegroundColor Red
    exit 1
}

# Set API URL
if ($SERVER_URL -match "^https?://") {
    $API_URL = "$SERVER_URL"
} else {
    $API_URL = "http://$SERVER_URL:3000"
}

Write-Host "✅ Sử dụng API URL: $API_URL" -ForegroundColor Green

# Export environment variable
$env:VITE_API_URL = $API_URL

# Cleanup old images and containers
Write-Host "🧹 Dọn dẹp Docker cache và unused images..." -ForegroundColor Yellow
docker system prune -f
docker image prune -f

# Stop existing containers
Write-Host "🛑 Dừng containers cũ..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml down 2>$null

# Build and start services
Write-Host "🔨 Build và khởi động services..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml build --no-cache

Write-Host "🚀 Khởi động services..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d

# Wait for services
Write-Host "⏳ Đợi services khởi động..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

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

# Show status
Write-Host "📊 Trạng thái services:" -ForegroundColor Green
docker-compose -f docker-compose.prod.yml ps

# Show URLs
Write-Host ""
Write-Host "✅ Deployment hoàn tất!" -ForegroundColor Green
Write-Host ""
Write-Host "📱 URLs:" -ForegroundColor Cyan
Write-Host "  - Backend API: http://$SERVER_URL:3000"
Write-Host "  - Frontend Web: http://$SERVER_URL:3001"
Write-Host "  - Health Check: http://$SERVER_URL:3000/health"
Write-Host ""
Write-Host "📝 Cập nhật Mobile App:" -ForegroundColor Cyan
Write-Host "  - Base URL: http://$SERVER_URL:3000"
Write-Host ""
Write-Host "⚠️  Nhớ mở firewall ports: 3000, 3001" -ForegroundColor Yellow

