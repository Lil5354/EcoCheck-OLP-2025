# Hướng dẫn Test và Kiểm tra Chức năng

Tài liệu này hướng dẫn cách test và kiểm tra các chức năng của EcoCheck, bao gồm Weather Integration, Air Quality, Smart Container Sensors, và POI.

## 📋 Mục lục

1. [Kiểm tra nhanh (30 giây)](#kiểm-tra-nhanh-30-giây)
2. [Weather Integration](#weather-integration)
3. [Air Quality Monitoring](#air-quality-monitoring)
4. [Smart Container Sensors](#smart-container-sensors)
5. [POI Integration](#poi-integration)
6. [Kiểm tra trên giao diện](#kiểm-tra-trên-giao-diện)
7. [Kiểm tra Backend Logs](#kiểm-tra-backend-logs)

---

## 🎯 Kiểm tra nhanh (30 giây)

### 1. Weather Integration ✅
**Kiểm tra Backend Console (Terminal):**
```
Tìm dòng: "[VRP] Vehicle ... (with weather)"
```
**→ Có dòng này = HOẠT ĐỘNG ✅**

### 2. Air Quality ✅
**Kiểm tra trên giao diện:**
- Mở: `http://localhost:5173/operations/air-quality`
- Thấy số AQI lớn (ví dụ: 85) với màu nền = HOẠT ĐỘNG ✅

### 3. Sensor Alerts ✅
**Kiểm tra trên giao diện:**
- Mở: `http://localhost:5173/operations/sensor-alerts`
- Thấy bảng danh sách (có thể rỗng) = HOẠT ĐỘNG ✅

### 4. POI Integration ✅
**Kiểm tra trên giao diện:**
- Mở: `http://localhost:5173/operations/poi`
- Thấy map và có thể tìm POI = HOẠT ĐỘNG ✅

---

## 🌤️ Weather Integration

### Test API Endpoints

#### 1.1. Lấy forecast cho một điểm
```bash
GET http://localhost:3000/api/weather/forecast?lat=10.78&lon=106.70

# Response:
{
  "ok": true,
  "data": {
    "temperature": 28.5,
    "feelsLike": 30.2,
    "humidity": 75,
    "pressure": 1013,
    "weather": "Clear",
    "description": "Trời quang",
    "icon": "01d",
    "windSpeed": 8.5,
    "windDirection": 180,
    "clouds": 20,
    "visibility": 10000,
    "rain": 0,
    "snow": 0,
    "timestamp": "2025-01-15T10:30:00.000Z"
  }
}
```

#### 1.2. Lấy weather cho route (batch)
```bash
POST http://localhost:3000/api/weather/route
Content-Type: application/json

{
  "points": [
    {"lat": 10.78, "lon": 106.70},
    {"lat": 10.79, "lon": 106.71},
    {"lat": 10.80, "lon": 106.72}
  ]
}

# Response:
{
  "ok": true,
  "data": [
    {
      "lat": 10.78,
      "lon": 106.70,
      "temperature": 28.5,
      "weather": "Clear",
      ...
    },
    ...
  ]
}
```

### Kiểm tra trên giao diện

#### Bước 1: Mở Route Optimization
- URL: `http://localhost:5173/operations/route-optimization`
- Chọn ngày và quận
- Chọn vehicles
- Click **"Tối ưu tuyến đường"**

#### Bước 2: Kiểm tra Backend Console (Terminal)
**Dấu hiệu thành công:**
```
[VRP] Vehicle {id}: Fetching weather for {n} stops...
[VRP] Vehicle {id}: Got weather data for {n} stops
[VRP] Vehicle {id}: Weather sample: { temp: ..., condition: ..., score: ... }
[VRP] Vehicle {id}: Optimized {n} stops using Hybrid CI-SA (with weather)
```

**Dấu hiệu thất bại:**
- Không có dòng "Fetching weather"
- Không có dòng "(with weather)"
- Có lỗi: "Weather fetch error"

### Checklist

- [ ] Backend console có: `(with weather)`
- [ ] Routes được tạo trên map
- [ ] Network tab: POST /api/vrp/optimize → 200 OK
- [ ] Weather data được fetch cho tất cả stops

---

## 🌬️ Air Quality Monitoring

### Test API Endpoints

#### 2.1. Lấy AQI cho một điểm
```bash
GET http://localhost:3000/api/air-quality?lat=10.78&lon=106.70&radius=5000

# Response:
{
  "ok": true,
  "data": {
    "aqi": 85,
    "pm25": 30.5,
    "pm10": 45.2,
    "category": "Moderate",
    "healthRecommendation": "Nhóm nhạy cảm nên hạn chế hoạt động ngoài trời",
    "location": "Hồ Chí Minh",
    "distance": 0
  }
}
```

#### 2.2. Lấy AQI cho route
```bash
POST http://localhost:3000/api/air-quality/route
Content-Type: application/json

{
  "points": [
    {"lat": 10.78, "lon": 106.70},
    {"lat": 10.79, "lon": 106.71}
  ]
}
```

### Kiểm tra trên giao diện

#### Cách truy cập:
1. Mở Web Manager: `http://localhost:5173`
2. Menu: **VẬN HÀNH** → **Chất lượng không khí**

#### Chức năng:
- ✅ Hiển thị AQI cho Hồ Chí Minh (mặc định)
- ✅ Tìm kiếm AQI theo tọa độ tùy chỉnh
- ✅ Hiển thị PM2.5, PM10
- ✅ Color coding theo mức độ (xanh/vàng/cam/đỏ)
- ✅ Khuyến nghị sức khỏe dựa trên AQI

#### Test:
1. Mở trang Air Quality
2. Kiểm tra AQI hiển thị (sẽ là mock data nếu không có API key)
3. Thử tìm kiếm với tọa độ khác
4. Kiểm tra color coding và khuyến nghị

### Checklist

- [ ] AQI số hiển thị
- [ ] Màu nền thay đổi theo AQI
- [ ] PM2.5/PM10 có giá trị
- [ ] Network tab: GET /api/air-quality → 200 OK
- [ ] Khuyến nghị sức khỏe hiển thị

---

## 📦 Smart Container Sensors

### Test API Endpoints

#### 3.1. Lấy fill level của container
```bash
GET http://localhost:3000/api/sensors/{containerId}/level

# Response:
{
  "ok": true,
  "data": {
    "containerId": "P001",
    "sensorId": "sensor-001",
    "fillLevel": 75.5,
    "unit": "percent",
    "timestamp": "2025-01-15T10:30:00.000Z"
  }
}
```

#### 3.2. Lấy containers cần thu gom
```bash
GET http://localhost:3000/api/sensors/alerts?threshold=80

# Response:
{
  "ok": true,
  "data": [
    {
      "containerId": "P001",
      "fillLevel": 85.5,
      "location": {...},
      "lastObservation": "2025-01-15T10:30:00.000Z"
    },
    ...
  ]
}
```

#### 3.3. Tạo observation từ sensor
```bash
POST http://localhost:3000/api/sensors/{sensorId}/observations
Content-Type: application/json

{
  "resultValue": 75.5,
  "resultTime": "2025-01-15T10:30:00.000Z",
  "unit": "percent"
}
```

### Kiểm tra trên giao diện

#### Cách truy cập:
1. Menu: **VẬN HÀNH** → **Cảnh báo thùng rác**

#### Chức năng:
- ✅ Hiển thị danh sách containers cần thu gom (>threshold%)
- ✅ Điều chỉnh ngưỡng cảnh báo (default: 80%)
- ✅ Xem chi tiết container (mức đầy, lịch sử observations)
- ✅ Color coding theo mức đầy (xanh/vàng/đỏ)

#### Test:
1. Mở trang Sensor Alerts
2. Kiểm tra danh sách containers (sẽ có sample data từ migration)
3. Thay đổi threshold và reload
4. Click vào container để xem chi tiết
5. Kiểm tra lịch sử observations

### Checklist

- [ ] Bảng hiển thị
- [ ] Progress bar màu
- [ ] Click được vào container
- [ ] Network tab: GET /api/sensors/alerts → 200 OK
- [ ] Chi tiết container hiển thị đúng

---

## 📍 POI Integration

### Test API Endpoints

#### 4.1. Tìm POI gần một điểm
```bash
GET http://localhost:3000/api/poi/nearby?lat=10.78&lon=106.70&radius=500&type=gas_station

# Response:
{
  "ok": true,
  "data": [
    {
      "id": "node_12345",
      "name": "Trạm xăng Petrolimex",
      "type": "gas_station",
      "lat": 10.7801,
      "lon": 106.7001,
      "distance": 150,
      "address": "123 Nguyễn Huệ, Quận 1"
    },
    ...
  ]
}
```

#### 4.2. Tìm nhiều loại POI
```bash
GET http://localhost:3000/api/poi/multiple?lat=10.78&lon=106.70&types=gas_station,restaurant,parking

# Response:
{
  "ok": true,
  "data": {
    "gas_station": [...],
    "restaurant": [...],
    "parking": [...]
  }
}
```

#### 4.3. Tìm POI dọc theo route
```bash
POST http://localhost:3000/api/poi/route
Content-Type: application/json

{
  "points": [
    {"lat": 10.78, "lon": 106.70},
    {"lat": 10.79, "lon": 106.71}
  ],
  "type": "gas_station",
  "radius": 300
}
```

### Kiểm tra trên giao diện

#### Cách truy cập:
1. Menu: **VẬN HÀNH** → **Điểm quan tâm (POI)**
2. Hoặc trong Route Optimization: Bật "Hiển thị POI dọc tuyến"

#### Chức năng:
- ✅ Tìm POI theo tọa độ hoặc click trên map
- ✅ Chọn loại POI (trạm xăng, nhà hàng, bãi đỗ xe, ...)
- ✅ Hiển thị POI trên map với markers màu cam
- ✅ Xem chi tiết POI (tên, khoảng cách, địa chỉ)
- ✅ Tìm POI dọc theo route khi optimize

#### Test:
1. Mở trang POI
2. Nhập tọa độ hoặc click trên map
3. Chọn loại POI
4. Kiểm tra kết quả hiển thị trên map
5. Click vào POI để xem chi tiết
6. Test trong Route Optimization: Bật POI và kiểm tra markers

### Checklist

- [ ] Map hiển thị
- [ ] POI markers màu cam hiển thị
- [ ] Click được vào POI
- [ ] Network tab: GET /api/poi/nearby → 200 OK
- [ ] POI không bị lệch khi zoom
- [ ] Trạm xăng hiển thị đúng

---

## 🔍 Kiểm tra trên giao diện

### Weather Integration trong Route Optimization

1. Mở **Tối ưu tuyến đường**
2. Chọn ngày và quận
3. Chọn vehicles
4. Click **"Tối ưu tuyến đường"**
5. **Kiểm tra Backend Console** (Terminal) - KHÔNG phải Browser Console
6. Tìm dòng: `[VRP] Vehicle ... (with weather)`

### Air Quality

1. Mở: `http://localhost:5173/operations/air-quality`
2. Kiểm tra AQI hiển thị với màu nền
3. Thử tìm kiếm với tọa độ khác
4. Kiểm tra color coding

### Sensor Alerts

1. Mở: `http://localhost:5173/operations/sensor-alerts`
2. Kiểm tra danh sách containers
3. Thay đổi threshold
4. Click vào container để xem chi tiết

### POI

1. Mở: `http://localhost:5173/operations/poi`
2. Tìm POI theo tọa độ
3. Kiểm tra markers trên map
4. Test trong Route Optimization: Bật POI overlay

---

## 📊 Kiểm tra Backend Logs

### Nơi kiểm tra logs

| Chức năng | Nơi kiểm tra logs |
|-----------|-------------------|
| **Weather Integration** | **Backend Console (Terminal)** ⚠️ KHÔNG phải Browser Console |
| **Air Quality** | Browser DevTools → Network tab |
| **Sensor Alerts** | Browser DevTools → Network tab + Backend Console |
| **POI** | Browser DevTools → Network tab |

### Dấu hiệu thành công

#### Weather Integration:
```
[VRP] Vehicle V01: Fetching weather for 15 stops...
[VRP] Vehicle V01: Got weather data for 15 stops
[VRP] Vehicle V01: Weather sample: { temp: 32.47, condition: 'Clear', score: 0.17 }
[VRP] Vehicle V01: Optimized 15 stops using Hybrid CI-SA (with weather)
```

#### Smart Container Sensors:
```
[Sensors] Found 1 containers needing collection
[Sensors] Container P001: fillLevel=85.5%
```

#### POI:
```
[POI] Fetching POIs along route: 17 points
[POI] Found 52 POIs
```

### Dấu hiệu thất bại

- Không có logs tương ứng
- Có lỗi: `Error fetching...`
- Status code: 429 (rate limit) hoặc 504 (timeout)
- Response: `{ ok: false, error: "..." }`

---

## ✅ Kết quả mong đợi

**TẤT CẢ ĐÃ HOẠT ĐỘNG:**
- ✅ Weather: Có logs `(with weather)` cho tất cả vehicles
- ✅ Sensors: Có log `[Sensors] Found ... containers...`
- ✅ VRP: Routes được tạo thành công
- ✅ POI: Markers hiển thị trên map

**Trên giao diện bạn sẽ thấy:**
- Routes trên map
- AQI với màu
- Danh sách containers (nếu có data)
- POI markers màu cam

---

## 🐛 Troubleshooting

### Weather không hoạt động
- Kiểm tra OpenWeatherMap API key trong `.env`
- Kiểm tra backend console có logs không
- Kiểm tra network tab có request không

### POI không hiển thị
- Kiểm tra rate limiting (429 errors)
- Kiểm tra network tab có request không
- Kiểm tra console có lỗi không

### Sensor Alerts rỗng
- Kiểm tra database có data không
- Kiểm tra migration đã chạy chưa
- Kiểm tra threshold có đúng không

---

**Chúc bạn test thành công! 🚀**
