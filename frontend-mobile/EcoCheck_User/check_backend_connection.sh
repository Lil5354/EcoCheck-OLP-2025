#!/bin/bash

# 🔍 Script Kiểm Tra Toàn Bộ Backend Connection
# Usage: ./check_backend_connection.sh

echo "🔍 KIỂM TRA KẾT NỐI BACKEND"
echo "================================"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Check Docker Containers
echo "1️⃣  Checking Docker Containers..."
if docker compose ps | grep -q "Up"; then
    echo -e "${GREEN}✅ Docker containers are running${NC}"
    docker compose ps
else
    echo -e "${RED}❌ Docker containers are NOT running${NC}"
    echo "Run: docker compose up -d"
    exit 1
fi
echo ""

# 2. Check Backend Health
echo "2️⃣  Checking Backend Health..."
HEALTH_RESPONSE=$(curl -s http://localhost:3000/health)
if echo "$HEALTH_RESPONSE" | grep -q '"status":"OK"'; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
    echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi
echo ""

# 3. Check API Status
echo "3️⃣  Checking API Status..."
STATUS_RESPONSE=$(curl -s http://localhost:3000/api/status)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ API Status endpoint working${NC}"
    echo "$STATUS_RESPONSE" | jq '.' 2>/dev/null || echo "$STATUS_RESPONSE"
else
    echo -e "${YELLOW}⚠️  API Status endpoint not available${NC}"
fi
echo ""

# 4. Test Alerts Endpoint
echo "4️⃣  Testing Alerts Endpoint..."
ALERTS_RESPONSE=$(curl -s http://localhost:3000/api/alerts)
if echo "$ALERTS_RESPONSE" | grep -q "success\|data\|alerts"; then
    echo -e "${GREEN}✅ Alerts endpoint working${NC}"
    ALERT_COUNT=$(echo "$ALERTS_RESPONSE" | jq '.data | length' 2>/dev/null || echo "unknown")
    echo "Alert count: $ALERT_COUNT"
else
    echo -e "${YELLOW}⚠️  Alerts endpoint response unexpected${NC}"
fi
echo ""

# 5. Test Check-ins Endpoint
echo "5️⃣  Testing Check-ins Endpoint..."
CHECKINS_RESPONSE=$(curl -s http://localhost:3000/api/checkins/recent?count=5)
if echo "$CHECKINS_RESPONSE" | grep -q "success\|data\|checkins"; then
    echo -e "${GREEN}✅ Check-ins endpoint working${NC}"
    CHECKIN_COUNT=$(echo "$CHECKINS_RESPONSE" | jq '.data | length' 2>/dev/null || echo "unknown")
    echo "Recent check-in count: $CHECKIN_COUNT"
else
    echo -e "${YELLOW}⚠️  Check-ins endpoint response unexpected${NC}"
fi
echo ""

# 6. Test Fleet Endpoint
echo "6️⃣  Testing Fleet Endpoint..."
FLEET_RESPONSE=$(curl -s http://localhost:3000/api/fleet)
if echo "$FLEET_RESPONSE" | grep -q "success\|data\|vehicles"; then
    echo -e "${GREEN}✅ Fleet endpoint working${NC}"
    VEHICLE_COUNT=$(echo "$FLEET_RESPONSE" | jq '.data | length' 2>/dev/null || echo "unknown")
    echo "Vehicle count: $VEHICLE_COUNT"
else
    echo -e "${YELLOW}⚠️  Fleet endpoint response unexpected${NC}"
fi
echo ""

# 7. Test Analytics Endpoint
echo "7️⃣  Testing Analytics Endpoint..."
ANALYTICS_RESPONSE=$(curl -s http://localhost:3000/api/analytics/summary)
if echo "$ANALYTICS_RESPONSE" | grep -q "success\|data\|summary"; then
    echo -e "${GREEN}✅ Analytics endpoint working${NC}"
else
    echo -e "${YELLOW}⚠️  Analytics endpoint response unexpected${NC}"
fi
echo ""

# 8. Test Gamification Endpoints
echo "8️⃣  Testing Gamification Endpoints..."

# Statistics
STATS_RESPONSE=$(curl -s "http://localhost:3000/api/citizen/statistics?user_id=user-123")
if echo "$STATS_RESPONSE" | grep -q "success\|data\|statistics"; then
    echo -e "${GREEN}✅ User statistics endpoint working${NC}"
else
    echo -e "${YELLOW}⚠️  User statistics endpoint response unexpected${NC}"
fi

# Leaderboard
LEADERBOARD_RESPONSE=$(curl -s "http://localhost:3000/api/citizen/leaderboard?period=monthly&limit=10")
if echo "$LEADERBOARD_RESPONSE" | grep -q "success\|data\|leaderboard"; then
    echo -e "${GREEN}✅ Leaderboard endpoint working${NC}"
else
    echo -e "${YELLOW}⚠️  Leaderboard endpoint response unexpected${NC}"
fi
echo ""

# 9. Check Android Emulator Access (10.0.2.2)
echo "9️⃣  Testing Android Emulator Access (10.0.2.2)..."
if command -v nc &> /dev/null; then
    if nc -z 10.0.2.2 3000 2>/dev/null; then
        echo -e "${GREEN}✅ Port 3000 accessible via 10.0.2.2${NC}"
    else
        echo -e "${YELLOW}⚠️  Cannot test 10.0.2.2 from host (this is normal)${NC}"
        echo "   This URL only works from Android emulator"
    fi
else
    echo -e "${YELLOW}⚠️  nc command not available, skipping${NC}"
fi
echo ""

# 10. Summary
echo "================================"
echo "📊 SUMMARY"
echo "================================"
echo ""
echo "Backend URL Configuration:"
echo "  - Android Emulator: http://10.0.2.2:3000"
echo "  - iOS Simulator:    http://localhost:3000"
echo "  - macOS:            http://localhost:3000"
echo "  - Real Device:      http://YOUR_IP:3000"
echo ""
echo "Demo Credentials:"
echo "  Phone:    0901234567"
echo "  Password: 123456"
echo ""
echo "Next Steps:"
echo "  1. Run Flutter app: flutter run"
echo "  2. Login with demo credentials"
echo "  3. Check logs for successful authentication"
echo "  4. Verify navigation to HomePage"
echo ""
echo -e "${GREEN}✅ Backend connection check completed!${NC}"
