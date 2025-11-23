# CN7 Quick Reference Card

## [object Object]CN7: Incident Management & Dynamic Dispatch**
- Detects late check-ins and missed collection points
- Automatically finds nearest available vehicle
- Creates re-routing assignments
- Updates alert and point statuses

---

## 📡 API Endpoints

### 1. Get All Alerts
```http
GET /api/alerts
```
**Response:**
```json
{
  "ok": true,
  "data": [
    {
      "alert_id": 1,
      "alert_type": "missed_point" | "late_checkin",
      "severity": "warning" | "critical",
      "status": "open" | "acknowledged" | "resolved",
      "point_id": "uuid",
      "vehicle_id": "V01",
      "route_id": "uuid",
      "license_plate": "51A-123.45",
      "created_at": "2025-11-23T..."
    }
  ]
}
```

### 2. Get Nearest Vehicles for Alert
```http
POST /api/alerts/:alertId/dispatch
```
**Response:**
```json
{
  "ok": true,
  "data": [
    {
      "id": "V02",
      "lat": 10.78,
      "lon": 106.70,
      "speed": 25.5,
      "heading": 180,
      "distance": 1234.56
    }
  ]
}
```

### 3. Assign Vehicle to Alert ⭐ NEW
```http
POST /api/alerts/:alertId/assign
Content-Type: application/json

{
  "vehicle_id": "V02"
}
```
**Response:**
```json
{
  "ok": true,
  "data": {
    "message": "Vehicle assigned successfully",
    "route_id": "uuid",
    "vehicle_id": "V02",
    "alert_id": 1
  }
}
```

### 4. Check-in (with Alert Resolution)
```http
POST /api/rt/checkin
Content-Type: application/json

{
  "route_id": "uuid",
  "point_id": "uuid",
  "vehicle_id": "V02"
}
```
**Response:**
```json
{
  "ok": true,
  "status": "ok" | "late_checkin" | "duplicate"
}
```

---

## 🗄️ Database Schema

### alerts Table
```sql
CREATE TABLE alerts (
    alert_id SERIAL PRIMARY KEY,
    alert_type alert_type NOT NULL,  -- 'missed_point' | 'late_checkin'
    point_id uuid REFERENCES points(id),
    vehicle_id text REFERENCES vehicles(id),
    route_id uuid REFERENCES routes(id),
    severity alert_severity NOT NULL,  -- 'warning' | 'critical'
    status alert_status NOT NULL DEFAULT 'open',  -- 'open' | 'acknowledged' | 'resolved'
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details JSONB
);
```

### Key Queries

**Get open alerts:**
```sql
SELECT * FROM alerts WHERE status = 'open' ORDER BY created_at DESC;
```

**Get alerts for a point:**
```sql
SELECT * FROM alerts WHERE point_id = 'uuid' AND status IN ('open', 'acknowledged');
```

**Get incident response routes:**
```sql
SELECT * FROM routes WHERE meta->>'type' = 'incident_response';
```

---

## 🔄 Workflow

### Alert Creation
1. **Missed Point:** Cron job (every 15s) detects vehicle >500m past unchecked point
2. **Late Check-in:** Check-in endpoint detects check-in after route completion
3. Alert created with status `open`

### Vehicle Assignment
1. Manager clicks "Tạo tuyến mới" on alert
2. System finds 3 nearest vehicles
3. Manager selects vehicle and clicks "Giao việc"
4. System:
   - Creates new route with `type: 'incident_response'`
   - Creates route_stop for incident point
   - Updates alert status to `acknowledged`
   - Starts route in memory

### Alert Resolution
1. Assigned vehicle arrives at incident point
2. Worker performs check-in via mobile app
3. System:
   - Updates alert status to `resolved`
   - Updates route_stop status to `completed`
   - Logs resolution details

---

## 🧪 Quick Test Commands

### Start Test Route
```bash
curl -X POST http://localhost:3000/api/test/start-route \
  -H "Content-Type: application/json" \
  -d '{"route_id": "test-1", "vehicle_id": "V01"}'
```

### Get Alerts
```bash
curl http://localhost:3000/api/alerts
```

### Assign Vehicle
```bash
curl -X POST http://localhost:3000/api/alerts/1/assign \
  -H "Content-Type: application/json" \
  -d '{"vehicle_id": "V02"}'
```

### Simulate Check-in
```bash
curl -X POST http://localhost:3000/api/rt/checkin \
  -H "Content-Type: application/json" \
  -d '{"route_id": "uuid", "point_id": "uuid", "vehicle_id": "V02"}'
```

---

## [object Object]

| Issue | Solution |
|-------|----------|
| No alerts appearing | Check if routes are active, verify cron job is running |
| Assignment fails | Verify uuid package installed: `npm install uuid` |
| Query error on dispatch | Check PostGIS extension: `CREATE EXTENSION postgis;` |
| Frontend not updating | Clear cache, check Network tab for API errors |

---

## 📝 Code Locations

| Component | File | Lines |
|-----------|------|-------|
| Alert Detection | `backend/src/index.js` | 141-214, 550-604 |
| Vehicle Assignment | `backend/src/index.js` | 374-480 |
| Alert Resolution | `backend/src/index.js` | 150-191 |
| Frontend UI | `frontend-web-manager/src/pages/operations/DynamicDispatch.jsx` | All |
| API Client | `frontend-web-manager/src/lib/api.js` | 102-119 |
| Database Schema | `db/migrations/008_create_alerts_table.sql` | All |

---

## 🔗 Related Documents

- **Full Assessment:** `CN7_ASSESSMENT_AND_IMPLEMENTATION.md`
- **Implementation Details:** `CN7_IMPLEMENTATION_SUMMARY.md`
- **Testing Guide:** `CN7_TESTING_GUIDE.md`

---

**Last Updated:** 2025-11-23  
**Status:** ✅ Production Ready

