#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Complete Deployment Script - Deploy từ đầu đến cuối

set -e

echo "🚀 EcoCheck Complete Deployment Script"
echo "========================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're in the project directory
if [ ! -f "docker-compose.prod.yml" ]; then
    echo -e "${RED}❌ Không tìm thấy docker-compose.prod.yml${NC}"
    echo "Vui lòng chạy script từ thư mục gốc của dự án"
    exit 1
fi

# Get server IP
echo -e "${BLUE}🌐 Lấy thông tin server...${NC}"
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}' || echo "")

if [ -z "$SERVER_IP" ]; then
    read -p "🌐 Nhập IP hoặc domain của server: " SERVER_IP
else
    read -p "🌐 Nhập IP hoặc domain của server (Enter để dùng $SERVER_IP): " CUSTOM_IP
    if [ ! -z "$CUSTOM_IP" ]; then
        SERVER_IP=$CUSTOM_IP
    fi
fi

if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}❌ Server IP không được để trống${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Sử dụng server: $SERVER_IP${NC}"

# Set environment
export VITE_API_URL="http://$SERVER_IP:3000"

# Cleanup old resources
echo -e "${YELLOW}🧹 Dọn dẹp Docker cache...${NC}"
docker system prune -f 2>/dev/null || true
docker image prune -f 2>/dev/null || true

# Stop existing containers
echo -e "${YELLOW}🛑 Dừng containers cũ...${NC}"
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# Build images
echo -e "${YELLOW}🔨 Build images...${NC}"
docker-compose -f docker-compose.prod.yml build --no-cache

# Start services
echo -e "${YELLOW}🚀 Khởi động services...${NC}"
docker-compose -f docker-compose.prod.yml up -d

# Wait for services
echo -e "${YELLOW}⏳ Đợi services khởi động (30 giây)...${NC}"
sleep 30

# Check health
echo -e "${YELLOW}🏥 Kiểm tra health...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0
HEALTHY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:3000/health &>/dev/null; then
        echo -e "${GREEN}✅ Backend is healthy!${NC}"
        HEALTHY=true
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "Đợi backend... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ "$HEALTHY" = false ]; then
    echo -e "${RED}⚠️  Backend chưa healthy sau $MAX_RETRIES lần thử${NC}"
    echo "Kiểm tra logs: docker-compose -f docker-compose.prod.yml logs backend"
fi

# Show status
echo ""
echo -e "${BLUE}📊 Trạng thái services:${NC}"
docker-compose -f docker-compose.prod.yml ps

# Test endpoints
echo ""
echo -e "${BLUE}🧪 Kiểm tra endpoints:${NC}"
echo -n "  - Health: "
if curl -s http://localhost:3000/health | grep -q "ok"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

echo -n "  - API Status: "
if curl -s http://localhost:3000/api/status &>/dev/null; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAIL${NC}"
fi

# Final summary
echo ""
echo -e "${GREEN}✅✅✅ DEPLOYMENT HOÀN TẤT! ✅✅✅${NC}"
echo ""
echo -e "${BLUE}📱 URLs của bạn:${NC}"
echo "  - Backend API: http://$SERVER_IP:3000"
echo "  - Frontend Web: http://$SERVER_IP:3001"
echo "  - Health Check: http://$SERVER_IP:3000/health"
echo ""
echo -e "${BLUE}📝 Cập nhật Mobile App:${NC}"
echo "  File: frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart"
echo "  Thay đổi:"
echo "    static const String baseUrl = 'http://$SERVER_IP:3000';"
echo ""
echo -e "${YELLOW}💡 Lệnh hữu ích:${NC}"
echo "  - Xem logs: docker-compose -f docker-compose.prod.yml logs -f"
echo "  - Restart: docker-compose -f docker-compose.prod.yml restart"
echo "  - Stop: docker-compose -f docker-compose.prod.yml down"
echo "  - Cleanup: ./scripts/cleanup-docker.sh"
echo ""

