# LUỒNG HOẠT ĐỘNG TỐI ƯU TUYẾN ĐƯỜNG - GHI NHỚ

## TỔNG QUAN
Hệ thống tối ưu tuyến đường theo quận, tự động filter depots, vehicles, schedules, và tự động chọn dump phù hợp nhất.

---

## LUỒNG HOẠT ĐỘNG CHI TIẾT

### 1. FRONTEND - RouteOptimization.jsx

#### State Management:
- `selectedDistrict`: Quận đã chọn
- `districts`: Danh sách quận có schedules
- `schedules`: Lịch thu gom (đã filter theo quận)
- `depots`: Trạm thu gom (đã filter theo quận)
- `dumps`: Bãi rác (tất cả, backend sẽ auto-select)
- `fleet`: Đội xe (đã filter theo depot_id)
- `personnel`: Nhân sự (đã filter theo depot_id)
- `selectedVehicles`: Vehicles đã chọn
- `routes`: Kết quả tối ưu

#### Flow:
```
1. User chọn ngày thu gom
   ↓
2. loadDistricts() → GET /api/vrp/districts?date=YYYY-MM-DD
   ↓
3. Auto-select quận đầu tiên (nếu có)
   ↓
4. autoFilterByDistrict() được trigger:
   - Load tất cả: fleet, schedules, depots, dumps, personnel
   - Filter schedules theo district từ location_address
   - Filter depots theo district từ address/name
   - Filter vehicles theo depot_id (vehicles thuộc depots trong quận)
   - Filter personnel theo depot_id
   - Auto-select depot đầu tiên
   ↓
5. User chọn vehicles
   ↓
6. User click "Tối ưu tuyến đường"
   ↓
7. handleOptimize():
   - Validate: selectedDistrict, selectedVehicles, schedules
   - Build payload: vehicles, points, depot, dump (optional), dumps (all)
   - POST /api/vrp/optimize
   ↓
8. Display routes:
   - Hiển thị danh sách routes với title "Danh sách tuyến đường [Quận X]"
   - Mỗi route: Hành trình A/B/C, Depot, Dump, số điểm, khoảng cách, ETA
   - Button "Gán nhân viên" cho mỗi route
   ↓
9. User click "Gán nhân viên":
   - handleAssignEmployee() → Mở modal
   - User chọn nhân viên
   - handleSaveAssignment():
     - Nếu route chưa save → POST /api/vrp/save-routes
     - POST /api/vrp/assign-route với route_id và driver_id
```

#### Key Functions:
- `loadDistricts()`: Load danh sách quận từ API
- `autoFilterByDistrict()`: Auto-filter tất cả data theo quận
- `extractDistrictFromAddress()`: Extract quận từ address string
- `handleOptimize()`: Gọi API optimize và hiển thị kết quả
- `displayRouteOnMap()`: Hiển thị route trên map với markers
- `handleAssignEmployee()`: Mở modal gán nhân viên
- `handleSaveAssignment()`: Save route và assign employee

---

### 2. BACKEND - /api/vrp/* Endpoints

#### A. GET /api/vrp/districts
**Purpose**: Lấy danh sách quận có schedules cho một ngày

**Query Params**: `date` (YYYY-MM-DD)

**Logic**:
- Query schedules JOIN points JOIN user_addresses
- Extract district từ `user_addresses.address_text` bằng regex
- Group by district, count schedules và points
- Return: `{ ok: true, data: [{ district, schedule_count, point_count }] }`

**SQL Pattern**:
```sql
SELECT DISTINCT 
  CASE 
    WHEN ua.address_text ~ 'Quận\s*\d+' THEN 'Quận ' || (regexp_match(...))[1]
    WHEN ua.address_text ~ 'Bình Thạnh' THEN 'Bình Thạnh'
    ...
  END as district,
  COUNT(DISTINCT s.id) as schedule_count,
  COUNT(DISTINCT p.id) as point_count
FROM schedules s
JOIN points p ON s.point_id = p.id
LEFT JOIN user_addresses ua ON p.address_id = ua.id
WHERE s.scheduled_date = $1 AND s.status = 'scheduled'
GROUP BY district
HAVING district != 'Không xác định'
```

---

#### B. POST /api/vrp/optimize
**Purpose**: Tối ưu tuyến đường cho vehicles và points

**Request Body**:
```json
{
  "vehicles": [{ id, plate, type, capacity, ... }],
  "points": [{ id, lat, lon, demand, type }],
  "depot": { id, name, lat, lon },
  "dump": { id, name, lat, lon } | null,
  "dumps": [{ id, name, lat, lon, ... }], // All dumps for auto-selection
  "timeWindow": { start: "19:00", end: "05:00" }
}
```

**Logic**:
1. Validate: vehicles.length > 0, points.length > 0
2. Auto-select dump nếu không có:
   - `findBestDumpForDistrict(depot, points, dumps)`
   - Filter active dumps
   - Find nearest dump từ điểm cuối của route
3. VRP Algorithm (Simple):
   - Distribute points evenly: `pointsPerVehicle = Math.ceil(points.length / vehicles.length)`
   - For each vehicle:
     - Build waypoints: `[depot] → [points] → [dump]`
     - Get route from OSRM: `getOSRMRoute(waypoints)`
     - If OSRM fails → Fallback to Haversine distance
     - Calculate ETA from duration
4. Return routes với GeoJSON geometry

**Response**:
```json
{
  "ok": true,
  "data": {
    "routes": [
      {
        "vehicleId": "VH001",
        "vehiclePlate": "51A-12345",
        "distance": 12500, // meters
        "eta": "0:25", // H:MM
        "geojson": { "type": "FeatureCollection", "features": [...] },
        "stops": [{ id, seq, lat, lon }],
        "depot": { id, name, lat, lon },
        "dump": { id, name, lat, lon },
        "depot_id": "...",
        "dump_id": "..."
      }
    ]
  }
}
```

---

#### C. POST /api/vrp/save-routes
**Purpose**: Lưu routes vào database

**Request Body**:
```json
{
  "routes": [
    {
      "vehicleId": "...",
      "depot_id": "...",
      "dump_id": "...",
      "driver_id": "..." | null,
      "distance": 12500,
      "stops": [{ id, seq }],
      ...
    }
  ]
}
```

**Logic**:
- For each route:
  - INSERT INTO routes: id, vehicle_id, driver_id, depot_id, dump_id, start_at, status, planned_distance_km, meta
  - Status = "assigned" nếu có driver_id, else "planned"
  - planned_distance_km = distance / 1000
  - INSERT INTO route_stops: id, route_id, point_id, seq, status, planned_eta

**Response**:
```json
{
  "ok": true,
  "data": {
    "routes": [
      { "route_id": "...", "vehicle_id": "...", "driver_id": "...", ... }
    ]
  }
}
```

---

#### D. POST /api/vrp/assign-route
**Purpose**: Gán nhân viên cho một route đã tồn tại

**Request Body**:
```json
{
  "route_id": "...",
  "driver_id": "...",
  "collector_id": "..." | null
}
```

**Logic**:
- UPDATE routes SET driver_id = ..., status = 'assigned' WHERE id = route_id
- Return updated route

---

### 3. HELPER FUNCTIONS

#### Backend:
- `extractDistrict(address)`: Extract quận từ address
- `extractWard(address)`: Extract huyện từ address
- `getHaversineDistance(coords1, coords2)`: Tính khoảng cách Haversine
- `getOSRMRoute(waypoints)`: Lấy route từ OSRM API
- `findBestDumpForDistrict(depot, points, dumps)`: Tự động chọn dump phù hợp nhất

#### Frontend:
- `extractDistrictFromAddress(address)`: Extract quận từ address
- `extractWardFromAddress(address)`: Extract huyện từ address

---

### 4. API METHODS (frontend-web-manager/src/lib/api.js)

- `getDistricts(date)`: GET /api/vrp/districts?date=...
- `optimizeVRP(payload)`: POST /api/vrp/optimize
- `saveRoutes(payload)`: POST /api/vrp/save-routes
- `assignRoute(routeId, driverId, collectorId)`: POST /api/vrp/assign-route

---

### 5. DATABASE SCHEMA

#### routes table:
- id (uuid)
- vehicle_id (text)
- driver_id (uuid) | null
- depot_id (uuid)
- dump_id (uuid)
- start_at (timestamptz)
- status: 'planned' | 'assigned' | 'in_progress' | 'completed'
- planned_distance_km (numeric)
- meta (jsonb)

#### route_stops table:
- id (uuid)
- route_id (uuid)
- point_id (uuid)
- seq (int)
- status: 'pending' | 'completed' | 'skipped'
- planned_eta (timestamptz)
- actual_at (timestamptz)

---

### 6. KEY FEATURES

1. **District-based filtering**: Tất cả data được filter theo quận
2. **Auto dump selection**: Backend tự động chọn dump gần nhất
3. **OSRM integration**: Sử dụng OSRM cho realistic road routing
4. **Haversine fallback**: Nếu OSRM fail, dùng Haversine distance
5. **Route visualization**: Hiển thị route trên map với markers (depot, stops, dump)
6. **Employee assignment**: Gán nhân viên cho từng route riêng biệt

---

## FILES LIÊN QUAN

### Frontend:
- `frontend-web-manager/src/pages/operations/RouteOptimization.jsx` - Main component
- `frontend-web-manager/src/lib/api.js` - API methods

### Backend:
- `backend/src/index.js`:
  - Lines 56-75: extractDistrict()
  - Lines 77-115: findBestDumpForDistrict()
  - Lines 1443-1503: getOSRMRoute()
  - Lines 1507-1552: GET /api/vrp/districts
  - Lines 1554-1725: POST /api/vrp/optimize
  - Lines 1727-1808: POST /api/vrp/save-routes
  - Lines 1809-1840: POST /api/vrp/assign-route

---

## NOTES

- District extraction: Regex pattern `Quận\s*(\d+)` hoặc check common districts
- Ward extraction: Regex pattern `Huyện\s+([^,]+)` hoặc check common wards
- OSRM API: `https://router.project-osrm.org/route/v1/driving/...`
- Distance unit: meters (backend) → km (frontend display)
- Duration unit: seconds (backend) → H:MM format (frontend display)



