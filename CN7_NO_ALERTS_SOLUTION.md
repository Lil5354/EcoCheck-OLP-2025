# Solution: No Alerts Displaying in Dynamic Dispatch

## Problem Analysis

Based on your screenshot, the Dynamic Dispatch page shows "Không có cảnh báo" (No alerts). The Network tab shows successful API calls (status 200), which means:

✅ Backend is running  
✅ API endpoint is working  
✅ Database connection is working  
❌ **No alerts exist in the database**

## Root Cause

The alerts table is empty because:
1. No routes have been started yet
2. No missed points have been detected
3. No late check-ins have occurred

This is **expected behavior** for a fresh installation!

---

## Solution: Generate Test Alerts

Choose one of the following methods:

### 🎯 Method 1: Automated Script (Recommended)

#### For Windows (PowerShell):
```powershell
cd e:\EcoCheck-OLP-2025
.\scripts\create-test-alerts.ps1
```

#### For Linux/Mac:
```bash
cd /path/to/EcoCheck-OLP-2025
chmod +x scripts/create-test-alerts.sh
./scripts/create-test-alerts.sh
```

This script will:
1. Check if backend is running
2. Start a test route
3. Wait for the cron job to detect missed points
4. Display the created alerts

---

### [object Object] Calls

#### Step 1: Start Test Route
```powershell
# PowerShell
$body = @{
    route_id = "test-route-001"
    vehicle_id = "V01"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/test/start-route" `
    -Method Post `
    -ContentType "application/json" `
    -Body $body
```

Or using curl:
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

#### Step 2: Wait for Detection
Wait **20-30 seconds** for the cron job to run and detect missed points.

#### Step 3: Check Alerts
```powershell
# PowerShell
Invoke-RestMethod -Uri "http://localhost:3000/api/alerts"
```

Or:
```bash
curl http://localhost:3000/api/alerts
```

#### Step 4: Refresh Frontend
Go to http://localhost:3001/operations/dynamic-dispatch and refresh the page.

---

### 🎯 Method 3: Direct Database Insertion

If the above methods don't work, insert alerts directly:

```powershell
# PowerShell
docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck -f /app/db/../scripts/insert-test-alerts.sql
```

Or:
```bash
psql -h localhost -U ecocheck_user -d ecocheck -f scripts/insert-test-alerts.sql
```

---

## Verification Steps

### 1. Check Backend Logs
```powershell
docker logs ecocheck-backend --tail 50
```

Look for:
- `🛰️  Running Missed Point Detection...` (every 15 seconds)
- `🚨 MISSED POINT DETECTED! Route: test-route-001, Point: P1`

### 2. Check Database
```powershell
docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck -c "SELECT alert_id, alert_type, status, created_at FROM alerts ORDER BY created_at DESC LIMIT 5;"
```

### 3. Check API Response
```powershell
Invoke-RestMethod -Uri "http://localhost:3000/api/alerts" | ConvertTo-Json -Depth 5
```

Should return:
```json
{
  "ok": true,
  "data": [
    {
      "alert_id": 1,
      "alert_type": "missed_point",
      "severity": "critical",
      "status": "open",
      ...
    }
  ]
}
```

### 4. Check Frontend
1. Open http://localhost:3001/operations/dynamic-dispatch
2. Press F12 to open DevTools
3. Go to Network tab
4. Refresh the page
5. Click on the `/api/alerts` request
6. Check the Response tab - should show alerts array

---

## Troubleshooting

### Issue: "Test route endpoint returns 404"
**Solution:** Make sure backend is running:
```powershell
docker ps | Select-String ecocheck-backend
```

If not running:
```powershell
docker compose up -d backend
```

### Issue: "Cron job not running"
**Solution:** Check backend logs for cron messages:
```powershell
docker logs ecocheck-backend -f
```

You should see "[object Object]d Point Detection..." every 15 seconds.

### Issue: "No points in database"
**Solution:** Run database migrations and seed data:
```powershell
cd db
.\run_migrations.ps1
```

### Issue: "PostGIS functions not found"
**Solution:** Enable PostGIS extension:
```sql
docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

---

## Expected Result

After following any of the methods above, you should see:

1. **Dynamic Dispatch Page:**
   - Table with alert rows
   - Columns: Thời gian, Điểm, Phương tiện gốc, Loại sự cố, Mức độ, Trạng thái, Hành động
   - "Tạo tuyến mới" button for open alerts

2. **Example Alert:**
   ```
   Thời gian: 23/11/2025, 10:30:45
   Điểm: ID: P1
   Phương tiện gốc: V01
   Loại sự cố: Bỏ sót điểm
   Mức độ: Nghiêm trọng (red)
   Trạng thái: open
   Hành động: [Tạo tuyến mới] button
   ```

---

## Quick Commands Reference

```powershell
# Check backend health
Invoke-RestMethod http://localhost:3000/health

# Create test route
$body = '{"route_id":"test-1","vehicle_id":"V01"}' | ConvertFrom-Json | ConvertTo-Json
Invoke-RestMethod -Uri http://localhost:3000/api/test/start-route -Method Post -ContentType "application/json" -Body $body

# Check alerts
Invoke-RestMethod http://localhost:3000/api/alerts

# Check database
docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck -c "SELECT COUNT(*) FROM alerts;"

# Watch backend logs
docker logs ecocheck-backend -f
```

---

## Summary

The "Không có cảnh báo" message is **correct behavior** when no alerts exist. To test the CN7 feature:

1. ✅ Run the automated script: `.\scripts\create-test-alerts.ps1`
2. ✅ Wait 20-30 seconds
3. ✅ Refresh the Dynamic Dispatch page
4. ✅ Alerts should now appear!

If you still don't see alerts after following these steps, please share:
- Backend logs: `docker logs ecocheck-backend --tail 100`
- Database query result: `SELECT * FROM alerts;`
- API response: `curl http://localhost:3000/api/alerts`

