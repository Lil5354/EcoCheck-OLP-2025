#!/bin/bash
# EcoCheck - Reset and Seed TPHCM Data Script
# Script để reset và seed lại dữ liệu đa dạng chỉ trong TPHCM
# MIT License - Copyright (c) 2025 Lil5354

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Database connection parameters
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ecocheck}"
DB_USER="${DB_USER:-ecocheck_user}"
DB_PASSWORD="${DB_PASSWORD:-ecocheck_pass}"

# Export password for psql
export PGPASSWORD="$DB_PASSWORD"

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}  RESET AND SEED TPHCM DATA${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

echo -e "${YELLOW}Database: $DB_NAME${NC}"
echo -e "${YELLOW}Host: $DB_HOST:$DB_PORT${NC}"
echo -e "${YELLOW}User: $DB_USER${NC}"
echo ""

# Kiểm tra kết nối
echo -e "${YELLOW}Checking database connection...${NC}"
if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Database connection successful${NC}"
else
    echo -e "${RED}❌ Cannot connect to database!${NC}"
    exit 1
fi

echo ""

# Xác nhận reset
echo -e "${RED}⚠️  WARNING: This will DELETE all existing data!${NC}"
echo -e "${YELLOW}   Press Ctrl+C to cancel, or Enter to continue...${NC}"
read -r

echo ""
echo -e "${YELLOW}Running reset and seed script...${NC}"
echo ""

# Chạy script SQL
SCRIPT_PATH="$(dirname "$0")/reset_and_seed_tphcm_data.sql"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}❌ Script file not found: $SCRIPT_PATH${NC}"
    exit 1
fi

if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$SCRIPT_PATH"; then
    echo ""
    echo -e "${GREEN}✅ Reset and seed completed successfully!${NC}"
else
    echo -e "${RED}❌ Error running script${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}  ✅ DONE!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

