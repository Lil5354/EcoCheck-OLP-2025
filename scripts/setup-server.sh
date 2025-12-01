#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Server Setup Script - Tự động setup server từ đầu

set -e

echo "🚀 EcoCheck Server Setup Script"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo -e "${RED}❌ Không chạy script với quyền root. Sử dụng user thường.${NC}"
   exit 1
fi

echo -e "${BLUE}📋 Script này sẽ:${NC}"
echo "  1. Cài đặt Docker và Docker Compose"
echo "  2. Cài đặt các công cụ cần thiết"
echo "  3. Cấu hình firewall"
echo "  4. Clone repository (nếu chưa có)"
echo "  5. Deploy ứng dụng"
echo ""

read -p "⚠️  Bạn có muốn tiếp tục? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${RED}❌ Đã hủy${NC}"
    exit 0
fi

# Step 1: Install Docker
echo -e "${YELLOW}📦 Bước 1: Cài đặt Docker...${NC}"
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✅ Docker đã được cài đặt${NC}"
else
    echo "Đang cài Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo -e "${GREEN}✅ Docker đã được cài đặt${NC}"
    echo -e "${YELLOW}⚠️  Bạn cần logout và login lại để sử dụng Docker${NC}"
    echo -e "${YELLOW}   Hoặc chạy: newgrp docker${NC}"
    newgrp docker <<EOF
EOF
fi

# Step 2: Install Docker Compose
echo -e "${YELLOW}📦 Bước 2: Cài đặt Docker Compose...${NC}"
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose đã được cài đặt${NC}"
else
    echo "Đang cài Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ Docker Compose đã được cài đặt${NC}"
fi

# Step 3: Install utilities
echo -e "${YELLOW}📦 Bước 3: Cài đặt công cụ cần thiết...${NC}"
if command -v curl &> /dev/null; then
    echo -e "${GREEN}✅ curl đã có${NC}"
else
    sudo apt-get update && sudo apt-get install -y curl
fi

# Step 4: Configure firewall
echo -e "${YELLOW}🔥 Bước 4: Cấu hình firewall...${NC}"
if command -v ufw &> /dev/null; then
    echo "Đang mở ports..."
    sudo ufw allow 22/tcp  # SSH
    sudo ufw allow 3000/tcp  # Backend API
    sudo ufw allow 3001/tcp  # Frontend Web
    sudo ufw --force enable
    echo -e "${GREEN}✅ Firewall đã được cấu hình${NC}"
else
    echo -e "${YELLOW}⚠️  ufw không có, bỏ qua firewall${NC}"
fi

# Step 5: Get server IP
echo -e "${YELLOW}🌐 Bước 5: Lấy thông tin server...${NC}"
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')
echo -e "${GREEN}✅ Server IP: $SERVER_IP${NC}"

read -p "🌐 Nhập IP hoặc domain của server (Enter để dùng $SERVER_IP): " CUSTOM_IP
if [ -z "$CUSTOM_IP" ]; then
    CUSTOM_IP=$SERVER_IP
fi

# Step 6: Clone repository (if needed)
echo -e "${YELLOW}📥 Bước 6: Kiểm tra repository...${NC}"
if [ -d "EcoCheck-OLP-2025" ]; then
    echo -e "${GREEN}✅ Repository đã tồn tại${NC}"
    cd EcoCheck-OLP-2025
else
    echo "Đang clone repository..."
    git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
    cd EcoCheck-OLP-2025
    echo -e "${GREEN}✅ Repository đã được clone${NC}"
fi

# Step 7: Deploy
echo -e "${YELLOW}🚀 Bước 7: Deploy ứng dụng...${NC}"
export VITE_API_URL="http://$CUSTOM_IP:3000"
chmod +x scripts/deploy.sh
./scripts/deploy.sh <<EOF
$CUSTOM_IP
EOF

# Step 8: Cleanup
echo -e "${YELLOW}🧹 Bước 8: Dọn dẹp...${NC}"
chmod +x scripts/cleanup-docker.sh
read -p "Bạn có muốn chạy cleanup để tiết kiệm dung lượng? (y/n): " cleanup_confirm
if [ "$cleanup_confirm" = "y" ] || [ "$cleanup_confirm" = "Y" ]; then
    ./scripts/cleanup-docker.sh <<EOF
y
EOF
fi

# Final summary
echo ""
echo -e "${GREEN}✅✅✅ HOÀN TẤT! ✅✅✅${NC}"
echo ""
echo -e "${BLUE}📱 URLs của bạn:${NC}"
echo "  - Backend API: http://$CUSTOM_IP:3000"
echo "  - Frontend Web: http://$CUSTOM_IP:3001"
echo "  - Health Check: http://$CUSTOM_IP:3000/health"
echo ""
echo -e "${BLUE}📝 Cập nhật Mobile App:${NC}"
echo "  File: frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart"
echo "  Thay đổi: static const String baseUrl = 'http://$CUSTOM_IP:3000';"
echo ""
echo -e "${YELLOW}⚠️  Lưu ý:${NC}"
echo "  - Nếu không truy cập được, kiểm tra firewall"
echo "  - Đảm bảo server có public IP hoặc domain"
echo "  - Mobile app cần cập nhật baseUrl"
echo ""

