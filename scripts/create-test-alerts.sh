#!/bin/bash

# CN7 Test Alert Generator
# This script creates test alerts for the Dynamic Dispatch feature

echo "🚀 CN7 Test Alert Generator"
echo "=============================="
echo ""

# Configuration
BACKEND_URL="http://localhost:3000"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if backend is running
echo "1️⃣  Checking if backend is running..."
if curl -s "$BACKEND_URL/health" > /dev/null; then
    print_success "Backend is running"
else
    print_error "Backend is not running at $BACKEND_URL"
    echo "   Please start the backend first:"
    echo "   docker compose up -d backend"
    exit 1
fi

echo ""

# Start test route
echo "2️⃣  Starting test route..."
RESPONSE=$(curl -s -X POST "$BACKEND_URL/api/test/start-route" \
  -H "Content-Type: application/json" \
  -d '{"route_id": "test-route-001", "vehicle_id": "V01"}')

if echo "$RESPONSE" | grep -q '"ok":true'; then
    print_success "Test route started successfully"
    echo "   Route ID: test-route-001"
    echo "   Vehicle: V01"
    POINTS=$(echo "$RESPONSE" | grep -o '"points":\[[^]]*\]' | head -1)
    echo "   Points: $POINTS"
else
    print_error "Failed to start test route"
    echo "   Response: $RESPONSE"
    exit 1
fi

echo ""

# Wait for cron job to detect missed points
echo "3️⃣  Waiting for missed point detection..."
echo "   The cron job runs every 15 seconds..."
for i in {1..20}; do
    echo -n "."
    sleep 1
done
echo ""

# Check if alerts were created
echo ""
echo "4️⃣  Checking for alerts..."
ALERTS=$(curl -s "$BACKEND_URL/api/alerts")

if echo "$ALERTS" | grep -q '"alert_id"'; then
    print_success "Alerts created successfully!"
    echo ""
    echo "📊 Alert Details:"
    echo "$ALERTS" | python3 -m json.tool 2>/dev/null || echo "$ALERTS"
else
    print_warning "No alerts detected yet"
    echo "   This might mean:"
    echo "   - The cron job hasn't run yet (wait a bit longer)"
    echo "   - The vehicle is not far enough from the points"
    echo "   - There's an issue with the detection logic"
    echo ""
    echo "   Raw response:"
    echo "   $ALERTS"
fi

echo ""
echo "=============================="
echo "🎯 Next Steps:"
echo ""
echo "1. Open the Dynamic Dispatch page:"
echo "   http://localhost:3001/operations/dynamic-dispatch"
echo ""
echo "2. If no alerts appear, wait another 15 seconds and refresh"
echo ""
echo "3. Check backend logs:"
echo "   docker logs ecocheck-backend --tail 50"
echo ""
echo "4. Manually check database:"
echo "   psql -h localhost -U ecocheck_user -d ecocheck -c 'SELECT * FROM alerts;'"
echo ""

