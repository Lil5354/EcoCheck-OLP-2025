#!/bin/bash

echo "=== Testing Personnel API ==="
echo ""

# Test 1: GET all personnel
echo "1. GET /api/manager/personnel"
curl -s http://localhost:3000/api/manager/personnel | jq '.ok, (.data | length)'
echo ""

# Test 2: CREATE new personnel
echo "2. POST /api/manager/personnel (create worker)"
RESPONSE=$(curl -s -X POST http://localhost:3000/api/manager/personnel \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Test Worker",
    "role":"driver",
    "phone":"0999999999",
    "email":"test.worker@ecocheck.vn",
    "password":"test123",
    "address":"123 Test Street",
    "status":"active"
  }')

echo "$RESPONSE" | jq '.'
PERSONNEL_ID=$(echo "$RESPONSE" | jq -r '.data.id')
echo "Created Personnel ID: $PERSONNEL_ID"
echo ""

# Test 3: GET specific personnel
if [ "$PERSONNEL_ID" != "null" ]; then
  echo "3. GET /api/manager/personnel/$PERSONNEL_ID"
  curl -s http://localhost:3000/api/manager/personnel/$PERSONNEL_ID | jq '.'
  echo ""
fi

# Test 4: UPDATE personnel
if [ "$PERSONNEL_ID" != "null" ]; then
  echo "4. PUT /api/manager/personnel/$PERSONNEL_ID"
  curl -s -X PUT http://localhost:3000/api/manager/personnel/$PERSONNEL_ID \
    -H "Content-Type: application/json" \
    -d '{"status":"inactive"}' | jq '.ok, .message'
  echo ""
fi

# Test 5: DELETE personnel
if [ "$PERSONNEL_ID" != "null" ]; then
  echo "5. DELETE /api/manager/personnel/$PERSONNEL_ID"
  curl -s -X DELETE http://localhost:3000/api/manager/personnel/$PERSONNEL_ID | jq '.ok, .message'
  echo ""
fi

echo "=== Test Complete ==="
