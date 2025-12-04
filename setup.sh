#!/bin/bash
# EcoCheck Server Setup Script (Bash)
# MIT License - Copyright (c) 2025 Lil5354
# One-command setup để khởi động server cho cả Web và Mobile

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  ECOCHECK SERVER SETUP${NC}"
echo -e "${CYAN}  Setup tự động cho Web + Mobile${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# 1. Kiểm tra Docker
echo -e "${YELLOW}[1/6] Kiểm tra Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker chưa được cài đặt!${NC}"
    echo ""
    echo "Vui lòng cài đặt Docker từ:"
    echo "   https://www.docker.com/products/docker-desktop"
    exit 1
fi

DOCKER_VERSION=$(docker --version)
echo -e "${GREEN}✅ Docker: $DOCKER_VERSION${NC}"

# Kiểm tra Docker đang chạy
if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker daemon chưa chạy!${NC}"
    echo "   Vui lòng khởi động Docker và thử lại."
    exit 1
fi
echo -e "${GREEN}✅ Docker daemon đang chạy${NC}"
echo ""

# 2. Kiểm tra Docker Compose
echo -e "${YELLOW}[2/6] Kiểm tra Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose không tìm thấy!${NC}"
    exit 1
fi

if docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version)
    echo -e "${GREEN}✅ Docker Compose: $COMPOSE_VERSION${NC}"
else
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "${GREEN}✅ Docker Compose: $COMPOSE_VERSION${NC}"
    # Use docker-compose instead of docker compose
    alias docker='docker-compose'
fi
echo ""

# 3. Dừng containers cũ nếu có
echo -e "${YELLOW}[3/6] Dọn dẹp containers cũ...${NC}"
docker compose down 2>&1 | grep -v "No such file" || true
echo -e "${GREEN}✅ Đã dọn dẹp containers cũ${NC}"
echo ""

# 4. Khởi động Docker Services
echo -e "${YELLOW}[4/6] Khởi động Docker Services...${NC}"
echo "   (Quá trình này có thể mất 5-10 phút lần đầu tiên)"
echo ""

docker compose up -d --build

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Lỗi khi khởi động Docker services!${NC}"
    echo "   Vui lòng kiểm tra logs: docker compose logs"
    exit 1
fi

echo -e "${GREEN}✅ Docker services đã khởi động${NC}"
echo ""

# 5. Đợi services sẵn sàng
echo -e "${YELLOW}[5/6] Đợi services sẵn sàng...${NC}"
MAX_WAIT=60
WAIT_COUNT=0
BACKEND_READY=false
POSTGRES_READY=false

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    # Kiểm tra PostgreSQL
    if [ "$POSTGRES_READY" = false ]; then
        if docker compose exec -T postgres pg_isready -U ecocheck_user -d ecocheck &> /dev/null; then
            POSTGRES_READY=true
            echo -e "   ${GREEN}✅ PostgreSQL sẵn sàng${NC}"
        fi
    fi
    
    # Kiểm tra Backend
    if [ "$BACKEND_READY" = false ]; then
        if curl -sf http://localhost:3000/health &> /dev/null; then
            BACKEND_READY=true
            echo -e "   ${GREEN}✅ Backend API sẵn sàng${NC}"
        fi
    fi
    
    if [ "$POSTGRES_READY" = true ] && [ "$BACKEND_READY" = true ]; then
        break
    fi
    
    WAIT_COUNT=$((WAIT_COUNT + 2))
    echo "   Đang đợi... ($WAIT_COUNT/$MAX_WAIT giây)"
    sleep 2
done

if [ "$POSTGRES_READY" = false ]; then
    echo -e "${YELLOW}⚠️  PostgreSQL chưa sẵn sàng sau $MAX_WAIT giây${NC}"
    echo "   Migrations có thể chưa chạy xong, vui lòng đợi thêm..."
fi

if [ "$BACKEND_READY" = false ]; then
    echo -e "${YELLOW}⚠️  Backend chưa sẵn sàng sau $MAX_WAIT giây${NC}"
    echo "   Vui lòng kiểm tra logs: docker compose logs backend"
fi
echo ""

# 6. Kiểm tra trạng thái cuối cùng
echo -e "${YELLOW}[6/6] Kiểm tra trạng thái services...${NC}"
echo ""

# Lấy Local IP cho mobile
LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || ipconfig getifaddr en0 2>/dev/null || echo "localhost")

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  ✅ SETUP HOÀN TẤT!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  🌐 WEB PLATFORM${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${YELLOW}  Frontend Web:  http://localhost:3001${NC}"
echo -e "${YELLOW}  Backend API:   http://localhost:3000${NC}"
echo -e "${YELLOW}  Health Check:  http://localhost:3000/health${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  📱 MOBILE PLATFORM${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${YELLOW}  Backend API:   http://localhost:3000${NC}"
echo ""
echo -e "${CYAN}  Kết nối từ Mobile App:${NC}"
echo -e "${NC}    - Android Emulator: http://10.0.2.2:3000"
echo -e "${NC}    - iOS Simulator:    http://localhost:3000"
echo -e "${NC}    - Real Device:      http://$LOCAL_IP:3000"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  🔧 DOCKER SERVICES${NC}"
echo -e "${CYAN}========================================${NC}"
docker compose ps
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  📋 NEXT STEPS${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}1. Test Web Platform:${NC}"
echo "   Mở trình duyệt: http://localhost:3001"
echo ""
echo -e "${YELLOW}2. Test Mobile Platform:${NC}"
echo "   - Chạy Flutter app (Worker hoặc User)"
echo "   - Đảm bảo baseUrl trong api_constants.dart đúng với platform"
echo ""
echo -e "${YELLOW}3. Test cả 2 nền tảng cùng lúc:${NC}"
echo "   Chạy: ./test-web-mobile-integration.sh"
echo ""
echo -e "${YELLOW}4. Xem logs:${NC}"
echo "   docker compose logs -f backend"
echo "   docker compose logs -f frontend-web"
echo ""
echo -e "${YELLOW}5. Dừng services:${NC}"
echo "   docker compose down"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  🎉 SẴN SÀNG TEST!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""











