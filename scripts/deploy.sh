#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Production Deployment Script - Tối ưu dung lượng

set -e

echo "🚀 EcoCheck Production Deployment Script"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}❌ Please do not run as root${NC}"
   exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed${NC}"
    exit 1
fi

# Get server IP or domain
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}' || echo "")

if [ -z "$SERVER_IP" ]; then
    read -p "🌐 Nhập IP hoặc domain của server (ví dụ: 192.168.1.100 hoặc api.example.com): " SERVER_URL
else
    read -p "🌐 Nhập IP hoặc domain của server (Enter để dùng $SERVER_IP): " SERVER_URL
    if [ -z "$SERVER_URL" ]; then
        SERVER_URL=$SERVER_IP
    fi
fi

if [ -z "$SERVER_URL" ]; then
    echo -e "${RED}❌ Server URL không được để trống${NC}"
    exit 1
fi

# Set API URL
if [[ $SERVER_URL == *"http"* ]]; then
    API_URL="$SERVER_URL"
else
    API_URL="http://$SERVER_URL:3000"
fi

echo -e "${GREEN}✅ Sử dụng API URL: $API_URL${NC}"

# Export environment variable
export VITE_API_URL=$API_URL

# Cleanup old images and containers
echo -e "${YELLOW}🧹 Dọn dẹp Docker cache và unused images...${NC}"
docker system prune -f
docker image prune -f

# Stop existing containers
echo -e "${YELLOW}🛑 Dừng containers cũ...${NC}"
docker-compose -f docker-compose.prod.yml down 2>/dev/null || true

# Build and start services
echo -e "${YELLOW}🔨 Build và khởi động services...${NC}"
docker-compose -f docker-compose.prod.yml build --no-cache

echo -e "${YELLOW}🚀 Khởi động services...${NC}"
docker-compose -f docker-compose.prod.yml up -d

# Wait for services
echo -e "${YELLOW}⏳ Đợi services khởi động...${NC}"
sleep 10

# Check health
echo -e "${YELLOW}🏥 Kiểm tra health...${NC}"
for i in {1..30}; do
    if curl -f http://localhost:3000/health &>/dev/null; then
        echo -e "${GREEN}✅ Backend is healthy!${NC}"
        break
    fi
    echo "Đợi backend... ($i/30)"
    sleep 2
done

# Show status
echo -e "${GREEN}📊 Trạng thái services:${NC}"
docker-compose -f docker-compose.prod.yml ps

# Show URLs
echo ""
echo -e "${GREEN}✅ Deployment hoàn tất!${NC}"
echo ""
echo "📱 URLs:"
echo "  - Backend API: http://$SERVER_URL:3000"
echo "  - Frontend Web: http://$SERVER_URL:3001"
echo "  - Health Check: http://$SERVER_URL:3000/health"
echo ""
echo "📝 Cập nhật Mobile App:"
echo "  - Base URL: http://$SERVER_URL:3000"
echo ""
echo -e "${YELLOW}⚠️  Nhớ mở firewall ports: 3000, 3001${NC}"

