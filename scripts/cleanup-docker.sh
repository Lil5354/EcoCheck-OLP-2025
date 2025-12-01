#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# Script dọn dẹp Docker để tiết kiệm dung lượng

echo "🧹 EcoCheck Docker Cleanup Script"
echo "==================================="

# Show current disk usage
echo ""
echo "📊 Dung lượng Docker hiện tại:"
docker system df

# Ask for confirmation
read -p "⚠️  Bạn có muốn dọn dẹp? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "❌ Đã hủy"
    exit 0
fi

echo ""
echo "🧹 Đang dọn dẹp..."

# Remove stopped containers
echo "  - Xóa stopped containers..."
docker container prune -f

# Remove unused images
echo "  - Xóa unused images..."
docker image prune -af

# Remove unused volumes (cẩn thận - có thể xóa data)
echo "  - Xóa unused volumes..."
docker volume prune -f

# Remove unused networks
echo "  - Xóa unused networks..."
docker network prune -f

# Build cache cleanup
echo "  - Xóa build cache..."
docker builder prune -af

# Final cleanup
echo "  - Dọn dẹp toàn bộ..."
docker system prune -af --volumes

echo ""
echo "✅ Hoàn tất!"
echo ""
echo "📊 Dung lượng sau khi dọn dẹp:"
docker system df

