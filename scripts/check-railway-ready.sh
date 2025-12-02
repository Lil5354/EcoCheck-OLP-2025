#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# Script kiểm tra xem dự án đã sẵn sàng deploy Railway chưa

echo "🔍 Kiểm tra sẵn sàng deploy Railway..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0

# Check files
echo "📁 Kiểm tra files cần thiết..."

if [ -f "Dockerfile.railway" ]; then
    echo -e "${GREEN}✅ Dockerfile.railway${NC}"
else
    echo -e "${RED}❌ Thiếu Dockerfile.railway${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "railway.toml" ]; then
    echo -e "${GREEN}✅ railway.toml${NC}"
else
    echo -e "${RED}❌ Thiếu railway.toml${NC}"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "backend/entrypoint.sh" ]; then
    echo -e "${GREEN}✅ backend/entrypoint.sh${NC}"
else
    echo -e "${RED}❌ Thiếu backend/entrypoint.sh${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check git
echo ""
echo "🔗 Kiểm tra Git..."

if command -v git &> /dev/null; then
    echo -e "${GREEN}✅ Git đã cài${NC}"
    
    if git remote -v | grep -q "github.com"; then
        echo -e "${GREEN}✅ Đã có GitHub remote${NC}"
    else
        echo -e "${YELLOW}⚠️  Chưa có GitHub remote${NC}"
        echo "   Chạy: git remote add origin https://github.com/Lil5354/EcoCheck-OLP-2025.git"
    fi
else
    echo -e "${RED}❌ Git chưa cài${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Check Dockerfile content
echo ""
echo "🐳 Kiểm tra Dockerfile.railway..."

if grep -q "FROM node" Dockerfile.railway 2>/dev/null; then
    echo -e "${GREEN}✅ Dockerfile hợp lệ${NC}"
else
    echo -e "${RED}❌ Dockerfile không hợp lệ${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅✅✅ SẴN SÀNG DEPLOY RAILWAY! ✅✅✅${NC}"
    echo ""
    echo "📝 Bước tiếp theo:"
    echo "  1. Truy cập: https://railway.app"
    echo "  2. Login với GitHub"
    echo "  3. New Project → Deploy from GitHub repo"
    echo "  4. Chọn: Lil5354/EcoCheck-OLP-2025"
    echo ""
    echo "📚 Xem hướng dẫn chi tiết: DEPLOY_RAILWAY.md"
else
    echo -e "${RED}❌ Có $ERRORS lỗi. Vui lòng sửa trước khi deploy.${NC}"
    exit 1
fi



