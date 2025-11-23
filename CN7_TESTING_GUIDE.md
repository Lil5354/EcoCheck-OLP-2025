# CN7 Testing Guide: Incident Management & Dynamic Dispatch

**Feature:** CN7 - Incident Management & Dynamic Dispatch  
**Status:** ✅ FULLY IMPLEMENTED  
**Date:** 2025-11-23

---

## Overview

This guide provides step-by-step instructions to test the complete CN7 feature, including:
1. Alert detection (late check-ins and missed points)
2. Nearest vehicle identification
3. Vehicle assignment and re-routing
4. Alert resolution and status updates

---

## Prerequisites

### 1. Start the Application
```bash
# Start all services
docker compose up -d

# Or start individually
docker compose up -d postgres
docker compose up -d backend
docker compose up -d frontend-web
```

### 2. Verify Services are Running
- Backend: http://localhost:3000/health
- Frontend: http://localhost:3001
- Database: `psql -h localhost -U ecocheck_user -d ecocheck`

### 3. Run Database Migrations
```bash
cd db
./run_migrations.sh  # Linux/Mac
# or
.\run_migrations.ps1  # Windows
```

---

## Test Scenario 1: Missed Point Detection

### Step 1: Start a Test Route
```bash
curl -X POST http://localhost:3000/api/test/start-route \
  -H "Content-Type: application/json" \
  -d '{"route_id": "test-route-1", "vehicle_id": "V01"}'
```

**Expected Response:**
```json
{
  "ok": true,
  "message": "Test route test-route-1 started for vehicle V01",
  "points": ["P1", "P2", "P3", "P4", "P5"]
}
```

### Step 2: Wait for Missed Point Detection
The cron job runs every 15 seconds. After ~15-30 seconds, check the backend logs:

```bash
docker logs ecocheck-backend -f
```

**Expected Log:**
```
🛰️  Running Missed Point Detection...
🚨 MISSED POINT DETECTED! Route: test-route-1, Point: P1
```

### Step 3: Verify Alert Created
```bash
curl http://localhost:3000/api/alerts
```

**Expected Response:**
```json
{
  "ok": true,
  "data": [
    {
      "alert_id": 1,
      "alert_type": "missed_point",
      "severity": "critical",
      "status": "open",
      "point_id": "...",
      "vehicle_id": "V01",
      "route_id": "test-route-1",
      "created_at": "2025-11-23T..."
    }
  ]
}
```

---

## Test Scenario 2: Dynamic Dispatch via UI

### Step 1: Open Dynamic Dispatch Page
1. Navigate to http://localhost:3001
2. Click "Điều phối động" in the sidebar
3. You should see the alert from Scenario 1 in the table

### Step 2: Find Nearest Vehicles
1. Click the "Tạo tuyến mới" button on the alert row
2. A modal will appear showing the 3 nearest vehicles with distances

**Expected:**
- Modal title: "Điều phối lại cho sự cố tại điểm ID: P1"
- List of 3 vehicles sorted by distance
- Each vehicle shows: ID, license plate, distance in meters

### Step 3: Assign Vehicle
1. Click "Giao việc" on the nearest vehicle
2. Wait for the success toast message

**Expected:**
- Toast: "Đã giao việc cho xe V02 để xử lý sự cố. Tuyến mới: [UUID]"
- Modal closes
- Alert table refreshes
- Alert status changes from "open" to "acknowledged"

### Step 4: Verify in Database
```sql
-- Check alert status
SELECT alert_id, alert_type, status, details 
FROM alerts 
WHERE alert_id = 1;

-- Check new route created
SELECT id, vehicle_id, status, meta 
FROM routes 
WHERE meta->>'type' = 'incident_response';

-- Check route stop created
SELECT rs.id, rs.route_id, rs.point_id, rs.status
FROM route_stops rs
JOIN routes r ON rs.route_id = r.id
WHERE r.meta->>'type' = 'incident_response';
```

---

## Test Scenario 3: Alert Resolution via Check-in

### Step 1: Simulate Check-in
Use the route_id from the assignment response:

```bash
curl -X POST http://localhost:3000/api/rt/checkin \
  -H "Content-Type: application/json" \
  -d '{
    "route_id": "[NEW_ROUTE_UUID]",
    "point_id": "P1",
    "vehicle_id": "V02"
  }'
```

**Expected Response:**
```json
{
  "ok": true,
  "status": "ok"
}
```

**Expected Log:**
```
✅ Resolved 1 alert(s) for point P1
```

### Step 2: Verify Alert Resolved
```bash
curl http://localhost:3000/api/alerts
```

**Expected:**
- Alert status changed to "resolved"
- `details` field contains:
  - `resolved_at`: timestamp
  - `resolved_by_vehicle`: "V02"
  - `resolved_by_route`: [NEW_ROUTE_UUID]

### Step 3: Verify Route Stop Completed
```sql
SELECT status, actual_at 
FROM route_stops 
WHERE route_id = '[NEW_ROUTE_UUID]' AND point_id = 'P1';
```

**Expected:**
- `status`: "completed"
- `actual_at`: timestamp

---

## Test Scenario 4: Late Check-in Detection

### Step 1: Complete a Route
```bash
# Assuming test-route-1 is still active, complete it
# (In production, this would happen automatically)
```

### Step 2: Attempt Check-in After Completion
```bash
curl -X POST http://localhost:3000/api/rt/checkin \
  -H "Content-Type: application/json" \
  -d '{
    "route_id": "test-route-1",
    "point_id": "P2",
    "vehicle_id": "V01"
  }'
```

**Expected Response:**
```json
{
  "ok": true,
  "status": "late_checkin_recorded"
}
```

**Expected Log:**
```
🚨 LATE CHECK-IN DETECTED! Route: test-route-1, Point: P2
```

### Step 3: Verify Late Check-in Alert
```bash
curl http://localhost:3000/api/alerts
```

**Expected:**
- New alert with `alert_type`: "late_checkin"
- `severity`: "warning"
- `status`: "open"

---

## API Endpoints Reference

### GET /api/alerts
Retrieve all alerts (latest 50)

### POST /api/alerts/:alertId/dispatch
Get 3 nearest vehicles for an alert

**Request:** None  
**Response:** `{ ok: true, data: [{ id, distance, ... }] }`

### POST /api/alerts/:alertId/assign
Assign a vehicle to an alert and create re-route

**Request:** `{ vehicle_id: "V02" }`  
**Response:** `{ ok: true, data: { route_id, vehicle_id, alert_id } }`

### POST /api/rt/checkin
Record a check-in (also resolves alerts)

**Request:** `{ route_id, point_id, vehicle_id }`  
**Response:** `{ ok: true, status: "ok" | "late_checkin" }`

---

## Troubleshooting

### No Alerts Appearing
- Check if routes are active: `SELECT * FROM routes WHERE status = 'in_progress';`
- Check if cron job is running: Look for "Running Missed Point Detection" in logs
- Verify vehicles are in the in-memory store: `curl http://localhost:3000/api/rt/vehicles`

### Assignment Fails
- Check database connection
- Verify `uuid-ossp` extension is enabled: `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`
- Check backend logs for detailed error messages

### Frontend Not Updating
- Clear browser cache
- Check browser console for errors
- Verify API calls in Network tab

---

**Prepared by:** Cascade AI Assistant  
**Last Updated:** 2025-11-23

