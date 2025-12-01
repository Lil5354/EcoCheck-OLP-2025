# MIT License
# Copyright (c) 2025 Lil5354
# Script dọn dẹp Docker để tiết kiệm dung lượng

Write-Host "🧹 EcoCheck Docker Cleanup Script" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan

# Show current disk usage
Write-Host "`n📊 Dung lượng Docker hiện tại:" -ForegroundColor Yellow
docker system df

# Ask for confirmation
$confirm = Read-Host "`n⚠️  Bạn có muốn dọn dẹp? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "❌ Đã hủy" -ForegroundColor Red
    exit 0
}

Write-Host "`n🧹 Đang dọn dẹp..." -ForegroundColor Yellow

# Remove stopped containers
Write-Host "  - Xóa stopped containers..." -ForegroundColor Gray
docker container prune -f

# Remove unused images
Write-Host "  - Xóa unused images..." -ForegroundColor Gray
docker image prune -af

# Remove unused volumes (cẩn thận - có thể xóa data)
Write-Host "  - Xóa unused volumes..." -ForegroundColor Gray
docker volume prune -f

# Remove unused networks
Write-Host "  - Xóa unused networks..." -ForegroundColor Gray
docker network prune -f

# Build cache cleanup
Write-Host "  - Xóa build cache..." -ForegroundColor Gray
docker builder prune -af

# Final cleanup
Write-Host "  - Dọn dẹp toàn bộ..." -ForegroundColor Gray
docker system prune -af --volumes

Write-Host "`n✅ Hoàn tất!" -ForegroundColor Green
Write-Host "`n📊 Dung lượng sau khi dọn dẹp:" -ForegroundColor Yellow
docker system df

