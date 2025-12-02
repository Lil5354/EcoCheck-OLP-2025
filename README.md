# EcoCheck-OLP-2025 - Dynamic Waste Collection System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

EcoCheck is a comprehensive, FIWARE-based platform for dynamic waste collection management, designed for the OLP 2025 competition. It includes a backend API, a frontend web manager, mobile apps (Flutter), a complete database stack (PostgreSQL, PostGIS, TimescaleDB), and the FIWARE Orion-LD Context Broker.

## 🚀 Quick Start (One-Command Setup)

### ⚡ Cách Nhanh Nhất (Khuyến nghị)

Chỉ cần **1 lệnh** để setup toàn bộ server cho cả Web và Mobile:

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

**Linux/Mac (Bash):**
```bash
chmod +x setup.sh
./setup.sh
```

**Lưu ý:** Các script khác đã được di chuyển vào folder `scripts/`. Để chạy các script khác:
```powershell
.\scripts\start-dev.ps1
.\scripts\run-all-frontend.ps1
# ... các script khác
```

Script này sẽ tự động:
- ✅ Kiểm tra Docker
- ✅ Khởi động tất cả services (PostgreSQL, MongoDB, Redis, Orion-LD, Backend, Frontend)
- ✅ Chạy database migrations tự động
- ✅ Đợi services sẵn sàng
- ✅ Hiển thị thông tin kết nối cho Web và Mobile

### 📋 Cách Thủ Công (Nếu cần)

Nếu bạn muốn setup thủ công hoặc script không hoạt động:

**Step 1: Clone the Repository**

```bash
git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
cd EcoCheck-OLP-2025
```

**Step 2: Launch All Services**

```bash
docker compose up -d --build
```

**Step 3: Run Database Migrations**

Migrations sẽ tự động chạy khi backend container khởi động. Nếu cần chạy thủ công:

```bash
docker compose exec postgres bash -c "cd /app/db && bash ./run_migrations.sh"
```

## 🌐 Verification & Access

Your environment is now ready! You can verify that all services are running correctly:

### Web Platform
- **Frontend Web Manager**: `http://localhost:5173` - The EcoCheck web manager (Vite dev server)
- **Backend API**: `http://localhost:3000` - Backend API server
- **Health Check**: `http://localhost:3000/health` - JSON response `{"status":"ok"}`

### Mobile Platform
- **Backend API**: `http://localhost:3000`
- **Android Emulator**: `http://10.0.2.2:3000`
- **iOS Simulator**: `http://localhost:3000`
- **Real Device**: `http://<YOUR_LOCAL_IP>:3000`

**Cấu hình Mobile App:**

File: `frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart`

```dart
static String get devBaseUrl {
  if (kDebugMode) {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';  // Android Emulator
    }
    return 'http://localhost:3000';  // iOS Simulator / Windows Desktop
  }
  return baseUrl;
}
```

### Other Services
- **FIWARE Orion-LD**: `http://localhost:1026/version` - JSON response with Orion-LD version info
- **PostgreSQL**: `localhost:5432` (Database: `ecocheck`, User: `ecocheck_user`, Password: `ecocheck_pass`)
- **MongoDB**: `localhost:27017`
- **Redis**: `localhost:6379`

## 🧪 Test Cả 2 Nền Tảng Cùng Lúc

Để test liên kết dữ liệu giữa Web và Mobile:

**Windows:**
```powershell
.\scripts\test-web-mobile-integration.ps1
```

**Linux/Mac:**
```bash
chmod +x scripts/test-web-mobile-integration.sh
./scripts/test-web-mobile-integration.sh
```

Script này sẽ:
- ✅ Khởi động Backend server
- ✅ Khởi động Frontend Web
- ✅ Khởi động Mobile App
- ✅ Hiển thị hướng dẫn test liên kết dữ liệu

### Hướng Dẫn Test Liên Kết Dữ Liệu

1. **TEST ĐĂNG NHẬP:**
   - Đăng nhập trên Web: http://localhost:5173
   - Đăng nhập trên Mobile App
   - Kiểm tra: Cả 2 nền tảng đều kết nối cùng Backend

2. **TEST ĐỒNG BỘ DỮ LIỆU:**
   - Tạo/Chỉnh sửa dữ liệu trên Web
   - Kiểm tra: Mobile App có nhận được dữ liệu mới không
   - Tạo/Chỉnh sửa dữ liệu trên Mobile
   - Kiểm tra: Web có cập nhật dữ liệu mới không

3. **TEST REALTIME:**
   - Thực hiện action trên Mobile (check-in, update location)
   - Kiểm tra: Web có hiển thị realtime update không
   - Xem Realtime Map trên Web
   - Kiểm tra: Location từ Mobile có hiển thị trên Map không

4. **TEST API ENDPOINTS:**
   - Health: http://localhost:3000/health
   - Status: http://localhost:3000/api/status
   - Schedules: http://localhost:3000/api/v1/schedules

## 📁 Project Structure

- `/backend`: Node.js backend API
  - Express.js server với Socket.IO cho real-time
  - Kết nối PostgreSQL, MongoDB, Redis
  - Tích hợp FIWARE Orion-LD Context Broker
- `/frontend-web-manager`: React-based web application for managers
  - Vite + React
  - Quản lý fleet, personnel, schedules, routes
  - Real-time map và analytics dashboard
- `/frontend-mobile`: Flutter mobile applications
  - `/EcoCheck_Worker`: Mobile app cho nhân viên thu gom
    - Quản lý lịch trình, routes, check-ins
    - Real-time location tracking
    - Image upload cho tasks
  - `/EcoCheck_User`: Mobile app cho người dân
    - Đặt lịch thu gom
    - Gamification (badges, points, leaderboard)
    - Check-in và thống kê cá nhân
- `/db`: Contains all database-related files:
  - `/init`: SQL scripts for initial database setup (e.g., creating extensions)
  - `/migrations`: SQL scripts for creating schema and seeding data
  - `run_migrations.sh` / `.ps1`: Scripts to run migrations
- `docker-compose.yml`: Defines all the services, networks, and volumes for the project
- `setup.ps1` / `setup.sh`: One-command setup scripts (ở root)
- `scripts/test-web-mobile-integration.ps1` / `.sh`: Scripts to test Web + Mobile together
- `scripts/`: Folder chứa tất cả các script khác (start-dev.ps1, run-*.ps1, etc.)

## 🗄️ Database

### Technology Stack
- **PostgreSQL 15**: Core relational database
- **PostGIS**: Spatial and geographic data support
- **TimescaleDB**: Time-series data optimization

### Key Features
- ✅ 27+ tables covering all project features
- ✅ Spatial indexing for geographic queries
- ✅ Time-series optimization for high-volume data
- ✅ Automatic triggers for data integrity
- ✅ Comprehensive gamification system
- ✅ PAYT (Pay-As-You-Throw) billing support
- ✅ Real-time vehicle tracking
- ✅ Multi-role user management

### Database Connection

**Credentials:**
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `ecocheck`
- **User**: `ecocheck_user`
- **Password**: `ecocheck_pass`

**Connect via psql:**
```bash
docker compose exec postgres psql -U ecocheck_user -d ecocheck
```

## 🔧 Troubleshooting

### Docker Issues

**Q: I get an error like `Cannot connect to the Docker daemon`.**

**A:** This means Docker Desktop is not running. Open the Docker Desktop application and wait for the engine to start (the whale icon should be steady).

**Q: A service (e.g., `backend`) is not starting or is unhealthy.**

**A:** Check the logs for that specific container to find the error message:

```bash
docker compose logs --tail=100 backend
```

### Database Issues

**Q: I want to reset my database and start over.**

**A:** To completely remove all data (including database volumes) and stop all containers:

```bash
docker compose down -v
```

After this, run `.\setup.ps1` or `./setup.sh` again to start fresh.

**Lưu ý:** Các script khác đã được tổ chức trong folder `scripts/` để dễ quản lý.

### Mobile Connection Issues

**Q: Mobile app cannot connect to backend.**

**A:** 
1. **Android Emulator**: Ensure using `http://10.0.2.2:3000` (not `localhost`)
2. **iOS Simulator**: Use `http://localhost:3000`
3. **Real Device**: 
   - Get your local IP: `ipconfig | findstr IPv4` (Windows) or `ifconfig` (Linux/Mac)
   - Use `http://<YOUR_LOCAL_IP>:3000`
   - Ensure device and computer are on same WiFi network
   - Check firewall allows port 3000

### Port Conflicts

**Q: Port already in use error.**

**A:** Ensure these ports are not in use:
- `3000` - Backend API
- `3001` - Frontend Web
- `5432` - PostgreSQL
- `27017` - MongoDB
- `6379` - Redis
- `1026` - Orion-LD

Check and kill processes if needed:
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :3000
kill -9 <PID>
```

## 📡 API Endpoints

### Health & Status
- `GET /health` - Backend health check
- `GET /api/status` - API status
- `GET /api/fiware/version` - FIWARE Orion-LD version

### Alerts
- `GET /api/alerts` - Get all alerts
- `POST /api/alerts/:id/dispatch` - Dispatch vehicle to alert
- `POST /api/alerts/:id/assign` - Assign vehicle to alert

### Real-time Data
- `GET /api/rt/checkins?n=10` - Recent check-ins
- `GET /api/rt/points` - Real-time collection points
- `GET /api/rt/vehicles` - Real-time vehicles
- `POST /api/rt/checkin` - Post check-in

### Schedules & Routes
- `GET /api/v1/schedules` - Get schedules
- `GET /api/v1/schedules/assigned` - Get assigned schedules
- `GET /api/routes/active` - Get active routes

### Analytics
- `GET /api/analytics/summary` - Analytics summary
- `GET /api/analytics/timeseries` - Time series data
- `GET /api/analytics/predict?days=7` - Predictions

## 📋 Lưu Ý Quan Trọng

1. **Lần đầu tiên**: Có thể mất 5-10 phút để download images và build
2. **Migrations**: Tự động chạy khi backend container khởi động
3. **Docker Desktop**: Phải đang chạy trước khi chạy script
4. **Mobile App**: Cần cấu hình đúng baseUrl trong `api_constants.dart` theo platform

## 🛠️ Development

### Running Services Individually

**Backend:**
```bash
cd backend
npm install
npm run dev
```

**Frontend Web:**
```bash
cd frontend-web-manager
npm install
npm run dev
```

**Mobile App:**

**Prerequisites - Cài đặt Flutter:**

1. **Tải Flutter SDK:**
   - Truy cập: https://flutter.dev/docs/get-started/install/windows
   - Tải file ZIP Flutter SDK (khoảng 1.5GB)

2. **Giải nén và Setup:**
   ```powershell
   # Giải nén vào thư mục (ví dụ: C:\flutter hoặc E:\flutter)
   # Thêm vào PATH:
   $env:Path += ";C:\flutter\bin"  # Tạm thời
   # Hoặc thêm vĩnh viễn qua Environment Variables
   ```

3. **Kiểm tra cài đặt:**
   ```bash
   flutter --version
   flutter doctor
   ```

4. **Chạy Mobile App:**
   ```bash
   cd frontend-mobile/EcoCheck_Worker  # hoặc EcoCheck_User
   flutter pub get
   flutter devices
   flutter run
   ```

**Lưu ý cho Windows:**
- Cần bật **Developer Mode** trong Windows Settings để Flutter có thể tạo symlinks
- Có thể chạy trên Windows Desktop, Android Emulator, hoặc iOS Simulator
- Android Emulator: Sử dụng `http://10.0.2.2:3000` cho backend URL
- iOS Simulator/Windows Desktop: Sử dụng `http://localhost:3000`

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f frontend-web
docker compose logs -f postgres
```

### Restart Services

```bash
docker compose restart backend frontend-web
```

Or rebuild:
```bash
docker compose up -d --build
```

## 📞 Support

- **Health Check**: http://localhost:3000/health
- **View Logs**: `docker compose logs -f <service-name>`
- **Database Access**: `docker compose exec postgres psql -U ecocheck_user -d ecocheck`
- **Service Status**: `docker compose ps`

## 📚 Documentation

- [CHANGELOG.md](CHANGELOG.md) - Lịch sử thay đổi của dự án
- [CONTRIBUTING.md](CONTRIBUTING.md) - Hướng dẫn đóng góp cho dự án
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Tài liệu kiến trúc hệ thống
- [docs/postman/](docs/postman/) - Postman collection cho API testing

## 🚀 Future Development & Roadmap

### AI/ML Capabilities

Dự án hiện tại đã tích hợp **Predictive Analytics** với Linear Regression cho dự đoán nhu cầu thu gom. Để nâng cao độ chính xác và tính năng, có thể mở rộng với các giải pháp sau:

#### Option 1: Python Microservice với Prophet (Khuyến nghị cho Production)

**Mô tả:**
- Tạo Python microservice riêng (FastAPI) với Facebook Prophet cho time series forecasting
- Độ chính xác cao hơn (90-95% vs 60-70% của simple regression)
- Xử lý seasonality (tuần, tháng, năm), trends, và changepoints tự động
- Cung cấp confidence intervals (upper/lower bounds)

**Kiến trúc đề xuất:**
```
backend/
  ├── src/index.js (Node.js - main API)
  └── ai-service/ (Python microservice)
      ├── app.py (FastAPI)
      ├── models/
      │   ├── prophet_model.py
      │   └── demand_predictor.py
      ├── requirements.txt
      └── Dockerfile
```

**Tính năng:**
- Multi-variate forecasting (weather, events, holidays)
- Point-level prediction (dự đoán theo từng điểm thu gom)
- Anomaly detection tích hợp
- Model retraining tự động
- Model versioning và A/B testing

**Triển khai:**
1. Tạo Python service với FastAPI
2. Sử dụng Prophet library cho time series forecasting
3. Kết nối với PostgreSQL để lấy dữ liệu lịch sử
4. Node.js backend gọi Python service qua HTTP
5. Fallback về simple regression nếu Python service không khả dụng

**Lợi ích:**
- ✅ Độ chính xác cao (MAPE 10-20% vs 30-50%)
- ✅ Xử lý seasonality và trends tự động
- ✅ Confidence intervals cho uncertainty
- ✅ Dễ mở rộng với LSTM, ARIMA, XGBoost
- ✅ Tách biệt logic ML khỏi API chính
- ✅ Có thể scale độc lập

**Nhược điểm:**
- ⚠️ Cần setup Python environment
- ⚠️ Tăng độ phức tạp (2 services)
- ⚠️ Latency cao hơn (2-5s training time)
- ⚠️ Cần thêm server/container

**Khi nào nên triển khai:**
- Khi có đủ dữ liệu lịch sử (60+ ngày)
- Khi cần độ chính xác cao cho production
- Khi cần mở rộng với các tính năng AI khác
- Khi có team biết Python hoặc sẵn sàng học

**Tài liệu tham khảo:**
- [Prophet Documentation](https://facebook.github.io/prophet/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- Time Series Forecasting best practices

#### Các tính năng AI khác có thể mở rộng:

1. **Computer Vision**: Tự động phân loại rác từ ảnh check-in
   - Sử dụng MobileNet/EfficientNet
   - Tự động nhận diện `waste_type` và `filling_level`
   - Phát hiện ảnh không hợp lệ

2. **Anomaly Detection**: Phát hiện bất thường trong hoạt động
   - Isolation Forest hoặc Autoencoder
   - Phát hiện xe đi lệch route, dừng quá lâu
   - Phát hiện check-in bất thường

3. **Smart Scheduling**: Đề xuất lịch thu gom tối ưu
   - Recommendation System
   - Dựa trên lịch sử, pattern, thời tiết

4. **Route Anomaly Detection**: Phát hiện xe đi lệch route real-time
   - Geospatial Anomaly Detection
   - So sánh vị trí thực tế với route đã lên kế hoạch

5. **Fraud Detection**: Phát hiện check-in gian lận
   - Image similarity detection
   - Pattern analysis

6. **NLP**: Xử lý feedback tự động
   - Sentiment Analysis
   - Text Classification

### Performance Optimization

- [ ] Redis caching cho các queries thường dùng
- [ ] Database query optimization với indexes
- [ ] CDN cho static assets
- [ ] Load balancing cho high traffic

### Mobile App Enhancements

- [ ] Offline mode với local database
- [ ] Push notifications
- [ ] Background location tracking
- [ ] Image compression trước khi upload

### Integration

- [ ] Weather API integration cho route optimization
- [ ] Payment gateway integration
- [ ] SMS/Email notification service
- [ ] Third-party mapping services (Google Maps, Mapbox)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**Happy Coding! 🚀**
