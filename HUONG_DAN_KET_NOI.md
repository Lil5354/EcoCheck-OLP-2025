# 🚀 Hướng Dẫn Kết Nối EcoCheck Backend

## ✅ Trạng Thái Hệ Thống

Backend đã được khởi động thành công qua Docker! Tất cả services đang chạy tốt.

## 🔗 Thông Tin Kết Nối

### Backend API
- **URL**: `http://localhost:3000`
- **Health Check**: `http://localhost:3000/health`
- **API Base**: `http://localhost:3000/api`

### Databases
- **PostgreSQL**: `localhost:5432`
  - Database: `ecocheck`
  - User: `ecocheck_user`
  - Password: `ecocheck_pass`
  
- **MongoDB**: `localhost:27017`
  
- **Redis**: `localhost:6379`

### FIWARE Orion-LD
- **URL**: `http://localhost:1026`
- **Version**: `http://localhost:1026/version`

---

## 📡 API Endpoints Chính

### 1. Health & Status
```bash
# Kiểm tra backend health
curl http://localhost:3000/health

# Kiểm tra API status
curl http://localhost:3000/api/status

# Kiểm tra FIWARE version
curl http://localhost:3000/api/fiware/version
```

### 2. Alerts (Cảnh báo)
```bash
# Lấy danh sách alerts
curl http://localhost:3000/api/alerts

# Dispatch vehicle cho alert
curl -X POST http://localhost:3000/api/alerts/{alertId}/dispatch

# Assign vehicle cho alert
curl -X POST http://localhost:3000/api/alerts/{alertId}/assign \
  -H "Content-Type: application/json" \
  -d '{"vehicle_id": "V01"}'
```

### 3. Real-time Data
```bash
# Lấy check-ins (n = số lượng)
curl "http://localhost:3000/api/rt/checkins?n=10"

# Lấy points trong viewport
curl "http://localhost:3000/api/rt/points"

# Lấy vehicles
curl "http://localhost:3000/api/rt/vehicles"
```

### 4. Check-in
```bash
# Ghi nhận check-in
curl -X POST http://localhost:3000/api/rt/checkin \
  -H "Content-Type: application/json" \
  -d '{
    "route_id": "route-001",
    "point_id": "P1",
    "vehicle_id": "V01"
  }'
```

### 5. Master Data
```bash
# Lấy danh sách fleet (xe)
curl http://localhost:3000/api/master/fleet

# Tạo vehicle mới
curl -X POST http://localhost:3000/api/master/fleet \
  -H "Content-Type: application/json" \
  -d '{
    "plate": "51A-123.45",
    "type": "compactor",
    "capacity": 3000
  }'

# Lấy collection points
curl http://localhost:3000/api/points
```

### 6. VRP Optimization
```bash
# Optimize routes
curl -X POST http://localhost:3000/api/vrp/optimize \
  -H "Content-Type: application/json" \
  -d '{
    "vehicles": [...],
    "points": [...]
  }'
```

### 7. Analytics
```bash
# Summary analytics
curl http://localhost:3000/api/analytics/summary

# Time series data
curl http://localhost:3000/api/analytics/timeseries

# Predictions
curl "http://localhost:3000/api/analytics/predict?days=7"
```

---

## 🌐 Kết Nối Từ Frontend

### React/JavaScript
```javascript
const API_BASE_URL = 'http://localhost:3000/api';

// Ví dụ: Lấy alerts
fetch(`${API_BASE_URL}/alerts`)
  .then(res => res.json())
  .then(data => console.log(data));

// Ví dụ: Check-in
fetch(`${API_BASE_URL}/rt/checkin`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    route_id: 'route-001',
    point_id: 'P1',
    vehicle_id: 'V01'
  })
})
  .then(res => res.json())
  .then(data => console.log(data));
```

### Flutter/Dart
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

const String apiBaseUrl = 'http://localhost:3000/api';

// Lấy alerts
Future<void> getAlerts() async {
  final response = await http.get(Uri.parse('$apiBaseUrl/alerts'));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print(data);
  }
}

// Check-in
Future<void> checkIn() async {
  final response = await http.post(
    Uri.parse('$apiBaseUrl/rt/checkin'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'route_id': 'route-001',
      'point_id': 'P1',
      'vehicle_id': 'V01'
    }),
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print(data);
  }
}
```

---

## 🐳 Quản Lý Docker

### Xem trạng thái services
```bash
docker compose ps
```

### Xem logs
```bash
# Logs backend
docker compose logs -f backend

# Logs tất cả services
docker compose logs -f

# Logs với số dòng cụ thể
docker compose logs backend --tail=100
```

### Khởi động lại
```bash
# Restart backend
docker compose restart backend

# Restart tất cả
docker compose restart
```

### Dừng services
```bash
# Dừng tất cả
docker compose down

# Dừng và xóa volumes (reset database)
docker compose down --volumes
```

### Build lại
```bash
# Build lại backend
docker compose build backend

# Build và khởi động lại
docker compose up --build -d backend
```

---

## 🔍 Kiểm Tra Database

### PostgreSQL
```bash
# Kết nối vào database
docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck

# Trong psql shell:
\dt              # Liệt kê tables
\d points        # Xem cấu trúc table points
SELECT * FROM alerts LIMIT 5;
SELECT * FROM points LIMIT 5;
```

### MongoDB
```bash
# Kết nối vào MongoDB
docker exec -it ecocheck-mongodb mongosh

# Trong mongo shell:
use ecocheck
db.getCollectionNames()
```

---

## 🧪 Test với Postman

1. Mở Postman
2. Import collection từ: `docs/postman/ecocheck-orion-ld.postman_collection.json`
3. Hoặc tạo request mới với:
   - Base URL: `http://localhost:3000/api`
   - Không cần authentication
   - Headers: `Content-Type: application/json`

### Ví dụ Postman Requests

**GET Alerts**
- Method: GET
- URL: `http://localhost:3000/api/alerts`

**POST Check-in**
- Method: POST
- URL: `http://localhost:3000/api/rt/checkin`
- Body (JSON):
  ```json
  {
    "route_id": "route-001",
    "point_id": "P1",
    "vehicle_id": "V01"
  }
  ```

---

## 🌐 WebSocket (Real-time Updates)

Backend hỗ trợ Socket.IO cho fleet real-time updates:

```javascript
import io from 'socket.io-client';

const socket = io('http://localhost:3000');

// Lắng nghe fleet init
socket.on('fleet:init', (vehicles) => {
  console.log('Initial vehicles:', vehicles);
});

// Lắng nghe fleet updates (mỗi giây)
socket.on('fleet', (vehicles) => {
  console.log('Vehicle updates:', vehicles);
});
```

---

## 📱 Kết Nối Từ Mobile (Flutter)

### Lưu ý cho Android Emulator
Nếu chạy trên Android Emulator, sử dụng `10.0.2.2` thay vì `localhost`:
```dart
const String apiBaseUrl = 'http://10.0.2.2:3000/api';
```

### Lưu ý cho iOS Simulator
iOS Simulator có thể dùng `localhost` bình thường:
```dart
const String apiBaseUrl = 'http://localhost:3000/api';
```

### Thiết bị thật (Real Device)
Sử dụng IP address của máy Mac:
```bash
# Lấy IP address
ifconfig | grep "inet " | grep -v 127.0.0.1
```
Sau đó dùng IP (ví dụ: `192.168.1.100`):
```dart
const String apiBaseUrl = 'http://192.168.1.100:3000/api';
```

---

## 🛠️ Troubleshooting

### Backend không kết nối được
```bash
# Kiểm tra services có chạy không
docker compose ps

# Xem logs để debug
docker compose logs backend --tail=50

# Restart backend
docker compose restart backend
```

### Port bị chiếm
```bash
# Kiểm tra port 3000
lsof -i :3000

# Kill process nếu cần
kill -9 <PID>
```

### Database connection failed
```bash
# Kiểm tra postgres health
docker compose ps postgres

# Xem logs postgres
docker compose logs postgres

# Restart postgres
docker compose restart postgres
```

### Reset toàn bộ
```bash
# Dừng và xóa tất cả
docker compose down --volumes

# Khởi động lại từ đầu
docker compose up --build -d
```

---

## 📊 Database Schema

Backend sử dụng PostgreSQL với các tables chính:
- `points` - Điểm thu gom rác
- `vehicles` - Danh sách xe
- `routes` - Tuyến đường
- `route_stops` - Các điểm dừng trên tuyến
- `alerts` - Cảnh báo (missed point, late check-in)
- `checkins` - Lịch sử check-in
- `users` - Người dùng
- `badges` - Huy hiệu
- `incidents` - Sự cố

Xem chi tiết: `db/SCHEMA.md`

---

## 🎯 Quick Start

```bash
# 1. Khởi động Docker
docker compose up -d

# 2. Kiểm tra health
curl http://localhost:3000/health

# 3. Test API
curl http://localhost:3000/api/alerts

# 4. Xem logs
docker compose logs -f backend
```

---

## 📞 Liên Hệ & Hỗ Trợ

- Repository: https://github.com/Lil5354/EcoCheck-OLP-2025
- Issues: https://github.com/Lil5354/EcoCheck-OLP-2025/issues

Chúc bạn phát triển thành công! 🚀
