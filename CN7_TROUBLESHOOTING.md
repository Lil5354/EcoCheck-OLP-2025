# CN7 Troubleshooting: No Alerts Displaying

## Problem
The Dynamic Dispatch page shows "Không có cảnh báo" (No alerts) even though the API is working.

## Root Cause
**No alerts exist in the database yet.** The alerts table is empty because:
1. No routes have been started
2. The cron job hasn't detected any missed points
3. No late check-ins have occurred

## Solution: Generate Test Alerts

### Method 1: Using the Test Route Endpoint (Recommended)

#### Step 1: Start a Test Route
```bash
curl -X POST http://localhost:3000/api/test/start-route \
  -H "Content-Type: application/json" \
  -d '{"route_id": "test-route-001", "vehicle_id": "V01"}'
```

**Expected Response:**
```json
{
  "ok": true,
  "message": "Test route test-route-001 started for vehicle V01",
  "points": ["P1", "P2", "P3", "P4", "P5"]
}
```

#### Step 2: Wait for Missed Point Detection
The cron job runs every 15 seconds. Wait **15-30 seconds** and check the backend logs:

```bash
# Docker
docker logs ecocheck-backend --tail 50

# Or if running locally
# Check the terminal where backend is running
```

**Expected Log:**
```
🛰️  Running Missed Point Detection...
🚨 MISSED POINT DETECTED! Route: test-route-001, Point: P1
```

#### Step 3: Verify Alerts Created
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
      "point_id": "P1",
      "vehicle_id": "V01",
      "route_id": "test-route-001",
      "license_plate": null,
      "created_at": "2025-11-23T..."
    }
  ]
}
```

#### Step 4: Refresh Frontend
Go back to http://localhost:3001/operations/dynamic-dispatch and the alert should now appear!

---

### Method 2: Insert Alerts Directly into Database

If the test route endpoint doesn't work, insert alerts manually:

```sql
-- Connect to database
psql -h localhost -U ecocheck_user -d ecocheck

-- Insert a test alert
INSERT INTO alerts (alert_type, point_id, vehicle_id, route_id, severity, status, details)
VALUES (
  'missed_point',
  (SELECT id FROM points LIMIT 1),  -- Use first available point
  'V01',
  gen_random_uuid(),
  'critical',
  'open',
  '{"detected_at": "2025-11-23T10:00:00Z", "test": true}'::jsonb
);

-- Verify insertion
SELECT * FROM alerts;
```

Then refresh the frontend page.

---

### Method 3: Create Late Check-in Alert

```bash
# First, start a route
curl -X POST http://localhost:3000/api/test/start-route \
  -H "Content-Type: application/json" \
  -d '{"route_id": "test-route-002", "vehicle_id": "V02"}'

# Complete the route (you'd need to add this endpoint or do it manually in DB)
# Then try to check in after completion:
curl -X POST http://localhost:3000/api/rt/checkin \
  -H "Content-Type: application/json" \
  -d '{"route_id": "completed-route-id", "point_id": "P1", "vehicle_id": "V02"}'
```

---

## Diagnostic Checklist

### ✅ 1. Check Database Connection
```bash
# Test if backend can connect to database
curl http://localhost:3000/health

# Connect to database directly
psql -h localhost -U ecocheck_user -d ecocheck
```

### ✅ 2. Verify Alerts Table Exists
```sql
-- In psql
\dt alerts

-- Check table structure
\d alerts

-- Count alerts
SELECT COUNT(*) FROM alerts;
```

### ✅ 3. Check API Endpoint
```bash
# Test alerts endpoint
curl http://localhost:3000/api/alerts

# Should return:
# {"ok":true,"data":[]}  (if no alerts)
# or
# {"ok":true,"data":[{...}]}  (if alerts exist)
```

### ✅ 4. Check Frontend Network Tab
1. Open browser DevTools (F12)
2. Go to Network tab
3. Refresh the Dynamic Dispatch page
4. Look for request to `/api/alerts`
5. Check the response:
   - Status should be 200
   - Response should be `{"ok":true,"data":[...]}`

### ✅ 5. Check Browser Console
1. Open browser DevTools (F12)
2. Go to Console tab
3. Look for any JavaScript errors
4. Should see no errors

### ✅ 6. Verify Frontend Code
The frontend expects this structure:
```javascript
{
  ok: true,
  data: {
    data: [...]  // Array of alerts
  }
}
```

But the backend returns:
```javascript
{
  ok: true,
  data: [...]  // Array of alerts directly
}
```

**This is the issue!** The frontend is looking for `res.data.data` but should look for `res.data`.

---

## Fix: Update Frontend Code

The issue is in the `loadAlerts()` function. It should be:

```javascript
async function loadAlerts() {
  const res = await api.getAlerts();
  console.log('Alerts response:', res); // Debug log
  if (res.ok && Array.isArray(res.data)) {  // Changed from res.data.data
    setAlerts(res.data);  // Changed from res.data.data
  }
}
```

Let me fix this now...

---

## Quick Test Commands

```bash
# 1. Check if backend is running
curl http://localhost:3000/health

# 2. Check if alerts endpoint works
curl http://localhost:3000/api/alerts

# 3. Create test route
curl -X POST http://localhost:3000/api/test/start-route \
  -H "Content-Type: application/json" \
  -d '{"route_id": "test-1", "vehicle_id": "V01"}'

# 4. Wait 20 seconds, then check alerts again
sleep 20
curl http://localhost:3000/api/alerts

# 5. Check backend logs
docker logs ecocheck-backend --tail 20
```

---

## Expected Behavior

1. **Empty State:** "Không có cảnh báo" when no alerts exist ✅ (This is correct!)
2. **With Alerts:** Table showing alert rows with "Tạo tuyến mới" button
3. **Auto-refresh:** Alerts update every 5 seconds

---

## Next Steps

I'll now fix the frontend code to handle the response correctly.

