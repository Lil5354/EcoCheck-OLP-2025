#!/bin/bash
# Script test liên kết dữ liệu giữa Web và Mobile (Bash)
# EcoCheck OLP 2025
# Chạy cả Web và Mobile cùng lúc để test tính liên kết dữ liệu

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  TEST LIÊN KẾT DỮ LIỆU WEB + MOBILE${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Kiểm tra Docker và Database
echo -e "${YELLOW}[1/5] Kiểm tra Database Services...${NC}"
if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker daemon chưa chạy!${NC}"
    echo "   Vui lòng chạy: ./setup.sh"
    exit 1
fi

# Kiểm tra backend có đang chạy không
if curl -sf http://localhost:3000/health &> /dev/null; then
    echo -e "${GREEN}✅ Backend đang chạy${NC}"
else
    echo -e "${YELLOW}⚠️  Backend chưa chạy, đang khởi động...${NC}"
    echo "   Đang khởi động Docker services..."
    docker compose up -d postgres redis orion-ld backend 2>&1 | grep -v "No such file" || true
    sleep 5
    
    # Đợi backend sẵn sàng
    MAX_RETRIES=15
    RETRY_COUNT=0
    BACKEND_READY=false
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$BACKEND_READY" = false ]; do
        if curl -sf http://localhost:3000/health &> /dev/null; then
            BACKEND_READY=true
            echo -e "${GREEN}✅ Backend đã sẵn sàng!${NC}"
        else
            RETRY_COUNT=$((RETRY_COUNT + 1))
            echo "   Đang đợi backend... ($RETRY_COUNT/$MAX_RETRIES)"
            sleep 2
        fi
    done
    
    if [ "$BACKEND_READY" = false ]; then
        echo -e "${RED}❌ Backend chưa sẵn sàng sau $MAX_RETRIES lần thử${NC}"
        echo "   Vui lòng chạy: ./setup.sh"
        exit 1
    fi
fi
echo ""

# 2. Kiểm tra Backend API Server
echo -e "${YELLOW}[2/5] Kiểm tra Backend API Server...${NC}"
if curl -sf http://localhost:3000/health &> /dev/null; then
    echo -e "${GREEN}✅ Backend API đang chạy tại http://localhost:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Backend API chưa sẵn sàng${NC}"
    echo "   Đảm bảo Docker services đang chạy: docker compose ps"
fi
echo ""

# 3. Đợi Backend sẵn sàng
echo -e "${YELLOW}[3/5] Đợi Backend sẵn sàng...${NC}"
MAX_RETRIES=15
RETRY_COUNT=0
BACKEND_READY=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$BACKEND_READY" = false ]; do
    if curl -sf http://localhost:3000/health &> /dev/null; then
        BACKEND_READY=true
        echo -e "${GREEN}✅ Backend API đã sẵn sàng!${NC}"
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "   Đang đợi... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
    fi
done

if [ "$BACKEND_READY" = false ]; then
    echo -e "${YELLOW}⚠️  Backend chưa sẵn sàng sau $MAX_RETRIES lần thử${NC}"
    echo "   Vui lòng kiểm tra logs: docker compose logs backend"
else
    echo -e "${GREEN}✅ Backend đã sẵn sàng để nhận kết nối!${NC}"
fi
echo ""

# 4. Khởi động Frontend Web
echo -e "${YELLOW}[4/5] Khởi động Frontend Web...${NC}"
WEB_SCRIPT="$SCRIPT_DIR/run-frontend-web.sh"
if [ -f "$WEB_SCRIPT" ]; then
    # Chạy trong background
    bash "$WEB_SCRIPT" &
    echo -e "${GREEN}✅ Frontend Web đang khởi động${NC}"
    sleep 3
else
    echo -e "${YELLOW}⚠️  Không tìm thấy script run-frontend-web.sh${NC}"
    echo "   Bạn có thể chạy thủ công:"
    echo "   cd frontend-web-manager && npm run dev"
fi
echo ""

# 5. Khởi động Mobile App
echo -e "${YELLOW}[5/5] Khởi động Mobile App...${NC}"
MOBILE_SCRIPT="$SCRIPT_DIR/run-mobile-worker.sh"
if [ -f "$MOBILE_SCRIPT" ]; then
    bash "$MOBILE_SCRIPT" &
    echo -e "${GREEN}✅ Mobile App đang khởi động${NC}"
else
    echo -e "${YELLOW}⚠️  Không tìm thấy script run-mobile-worker.sh${NC}"
    echo "   Bạn có thể chạy mobile app thủ công:"
    echo "   cd frontend-mobile/EcoCheck_Worker"
    echo "   flutter run"
fi
echo ""

# Hiển thị thông tin kết nối
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  ✅ TẤT CẢ SERVICES ĐÃ KHỞI ĐỘNG!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Lấy Local IP cho mobile
LOCAL_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || ipconfig getifaddr en0 2>/dev/null || echo "localhost")

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  🌐 WEB PLATFORM${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${YELLOW}  Frontend Web:  http://localhost:5173${NC}"
echo -e "${YELLOW}  Backend API:   http://localhost:3000${NC}"
echo -e "${YELLOW}  Health Check:  http://localhost:3000/health${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  📱 MOBILE PLATFORM${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${YELLOW}  Backend API:   http://localhost:3000${NC}"
echo ""
echo -e "${CYAN}  Kết nối từ Mobile:${NC}"
echo "    - Android Emulator: http://10.0.2.2:3000"
echo "    - iOS Simulator:    http://localhost:3000"
echo "    - Real Device:      http://$LOCAL_IP:3000"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  🧪 HƯỚNG DẪN TEST LIÊN KẾT DỮ LIỆU${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}1. TEST ĐĂNG NHẬP:${NC}"
echo "   - Đăng nhập trên Web: http://localhost:5173"
echo "   - Đăng nhập trên Mobile App"
echo "   - Kiểm tra: Cả 2 nền tảng đều kết nối cùng Backend"
echo ""
echo -e "${YELLOW}2. TEST ĐỒNG BỘ DỮ LIỆU:${NC}"
echo "   - Tạo/Chỉnh sửa dữ liệu trên Web"
echo "   - Kiểm tra: Mobile App có nhận được dữ liệu mới không"
echo "   - Tạo/Chỉnh sửa dữ liệu trên Mobile"
echo "   - Kiểm tra: Web có cập nhật dữ liệu mới không"
echo ""
echo -e "${YELLOW}3. TEST REALTIME:${NC}"
echo "   - Thực hiện action trên Mobile (check-in, update location)"
echo "   - Kiểm tra: Web có hiển thị realtime update không"
echo "   - Xem Realtime Map trên Web"
echo "   - Kiểm tra: Location từ Mobile có hiển thị trên Map không"
echo ""
echo -e "${YELLOW}4. TEST API ENDPOINTS:${NC}"
echo "   - Health: http://localhost:3000/health"
echo "   - Status: http://localhost:3000/api/status"
echo "   - Schedules: http://localhost:3000/api/v1/schedules"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  📋 LƯU Ý${NC}"
echo -e "${CYAN}========================================${NC}"
echo "  - Tất cả services chạy trong background"
echo "  - Để dừng: Sử dụng Ctrl+C hoặc kill processes"
echo "  - Mobile app có thể mất 2-5 phút để build lần đầu tiên"
echo "  - Kiểm tra console logs để debug"
echo "  - Đảm bảo Mobile app cấu hình đúng baseUrl trong api_constants.dart"
echo ""

# Kiểm tra trạng thái cuối cùng
echo "Đang kiểm tra trạng thái services..."
sleep 3

if curl -sf http://localhost:3000/health &> /dev/null; then
    echo -e "${GREEN}✅ Backend API: Đang chạy${NC}"
else
    echo -e "${YELLOW}⚠️  Backend: Đang khởi động...${NC}"
fi

if curl -sf http://localhost:5173 &> /dev/null; then
    echo -e "${GREEN}✅ Frontend Web: Đang chạy${NC}"
else
    echo -e "${YELLOW}⚠️  Frontend Web: Đang khởi động...${NC}"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  🚀 SẴN SÀNG TEST!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

