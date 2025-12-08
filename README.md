# EcoCheck-OLP-2025 - Dynamic Waste Collection System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

EcoCheck is a comprehensive, FIWARE-based platform for dynamic waste collection management, designed for the OLP 2025 competition. It includes a backend API, a frontend web manager, mobile apps (Flutter), a complete database stack (PostgreSQL, PostGIS, TimescaleDB), and the FIWARE Orion-LD Context Broker.

> **📋 Compliance Checklist**: Xem [COMPLIANCE_CHECKLIST.md](COMPLIANCE_CHECKLIST.md) để đảm bảo đáp ứng đầy đủ tiêu chí chấm điểm OLP 2025.
> Public server: https://ecocheck-olp-2025.onrender.com

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

Dự án EcoCheck được tổ chức theo mô hình **Monorepo**, bao gồm 3 thành phần chính:

### 1. Backend (`/backend`)
**Vị trí**: `/backend`  
**Công nghệ**: Node.js 18+, Express.js, Socket.IO  
**Mục đích**: API server xử lý logic nghiệp vụ, tích hợp FIWARE Orion-LD Context Broker

**Cấu trúc:**
- `src/index.js` - Main server file, API endpoints
- `src/orionld.js` - FIWARE Orion-LD integration
- `src/realtime.js` - Real-time data store và Socket.IO
- `src/services/` - Business logic services (route optimization, analytics)
- `public/contexts/` - NGSI-LD context files
- `public/uploads/` - User-uploaded images

**Cách build**: `cd backend && npm install && npm start`

### 2. Frontend Web Manager (`/frontend-web-manager`)
**Vị trí**: `/frontend-web-manager`  
**Công nghệ**: React 19+, Vite, MapLibre GL  
**Mục đích**: Web application cho nhà quản lý, dashboard với real-time map

**Cấu trúc:**
- `src/App.jsx` - Main application component
- `src/pages/` - Page components (operations, dashboard)
- `src/components/` - Reusable components (RealtimeMap, Charts)
- `src/lib/api.js` - API client

**Cách build**: `cd frontend-web-manager && npm install && npm run build`

### 3. Frontend Mobile (`/frontend-mobile`)
**Vị trí**: `/frontend-mobile`  
**Công nghệ**: Flutter/Dart, BLoC pattern

#### 3.1 EcoCheck_Worker (`/EcoCheck_Worker`)
**Mục đích**: Mobile app cho nhân viên thu gom rác

**Tính năng:**
- Quản lý lịch trình và routes
- Real-time location tracking
- Check-in và image upload
- Smart checklist (không phải GPS navigation liên tục)

**Cách build**: `cd frontend-mobile/EcoCheck_Worker && flutter pub get && flutter build apk`

#### 3.2 EcoCheck_User (`/EcoCheck_User`)
**Mục đích**: Mobile app cho người dân

**Tính năng:**
- Đặt lịch thu gom
- Gamification (badges, points, leaderboard)
- Check-in rác thải và thống kê cá nhân
- Family Account (quản lý hộ gia đình)
- **AI Waste Analysis với Google Gemini 2.5 Flash**
  - Tự động phân loại rác từ ảnh (household, recyclable, bulky, hazardous)
  - Ước tính trọng lượng (kg) từ ảnh
  - Confidence score và mô tả chi tiết
  - Checkpoint system với khả năng rollback về Hugging Face

**Cách build**: `cd frontend-mobile/EcoCheck_User && flutter pub get && flutter build apk`

### 4. Database (`/db`)
**Vị trí**: `/db`  
**Mục đích**: Database migrations, seed data, và initialization scripts

**Cấu trúc:**
- `init/` - SQL scripts cho PostGIS, TimescaleDB setup
- `migrations/` - 31 migration files tạo schema
- `seed_*.sql` - Seed data scripts
- `run_migrations.sh/.ps1` - Migration runners

**Cách chạy**: `cd db && bash run_migrations.sh` (hoặc `.ps1` trên Windows)

### 5. Infrastructure
- `docker-compose.yml` - Docker Compose configuration
- `setup.ps1` / `setup.sh` - One-command setup scripts
- `scripts/` - Utility scripts (start-dev, test, deploy)

**📖 Xem thêm**: [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) để biết chi tiết đầy đủ về cấu trúc dự án, cách build từng component, và luồng tương tác giữa các thành phần.

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

### AI Services
- `POST /api/ai/analyze-waste` - AI waste analysis (proxy endpoint for mobile apps)

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

## 🔨 Building from Source

Hướng dẫn chi tiết để build và cài đặt dự án từ mã nguồn.

### Yêu Cầu Hệ Thống

**Backend:**
- Node.js 18+ và npm
- PostgreSQL 15+ (hoặc sử dụng Docker)
- Docker và Docker Compose (khuyến nghị)

**Frontend Web:**
- Node.js 18+ và npm

**Frontend Mobile:**
- Flutter SDK 3.8+ (cho mobile apps)
- Android Studio (cho Android development)
- Xcode (cho iOS development, chỉ trên macOS)

### Cấu Hình Trước Khi Build

#### 1. Backend Configuration

Tạo file `.env` trong thư mục `backend/`:

```bash
cd backend
# Nếu có file .env.example, copy nó
if [ -f .env.example ]; then
  cp .env.example .env
else
  # Tạo file .env mới từ template
  cat > .env << 'EOF'
DATABASE_URL=postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck
ORION_LD_URL=http://localhost:1026
PORT=3000
NODE_ENV=development
OPENWEATHER_API_KEY=your_openweather_api_key_here
AIRQUALITY_API_KEY=your_openaq_api_key_here
EOF
fi
# Chỉnh sửa .env với các giá trị thực tế
```

**Lưu ý**: File `env.example` (không có dấu chấm) đã được tạo sẵn trong `backend/` với tất cả các biến môi trường cần thiết. Để sử dụng:

```bash
# Copy env.example thành .env
cp env.example .env
# Sau đó chỉnh sửa .env với các giá trị thực tế
```

**Các biến môi trường cần thiết:**
- `DATABASE_URL` - PostgreSQL connection string
- `ORION_LD_URL` - FIWARE Orion-LD endpoint (default: http://localhost:1026)
- `PORT` - Backend port (default: 3000)
- `OPENWEATHER_API_KEY` - OpenWeatherMap API key (optional, cho weather integration)
- `AIRQUALITY_API_KEY` - OpenAQ API key (optional, cho air quality)

**Ví dụ `.env`:**
```env
DATABASE_URL=postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck
ORION_LD_URL=http://localhost:1026
PORT=3000
NODE_ENV=development
OPENWEATHER_API_KEY=your_openweather_api_key_here
AIRQUALITY_API_KEY=your_openaq_api_key_here
```

#### 2. Frontend Web Configuration

Tạo file `.env` trong thư mục `frontend-web-manager/`:

```bash
cd frontend-web-manager
# Nếu có file .env.example, copy nó
if [ -f .env.example ]; then
  cp .env.example .env
else
  # Tạo file .env mới
  echo "VITE_API_URL=http://localhost:3000" > .env
fi
```

**Lưu ý**: File `env.example` (không có dấu chấm) đã được tạo sẵn trong `frontend-web-manager/` với các biến môi trường cần thiết. Để sử dụng:

```bash
# Copy env.example thành .env
cp env.example .env
```

**Các biến môi trường:**
- `VITE_API_URL` - Backend API URL (default: http://localhost:3000)

**Ví dụ `.env`:**
```env
VITE_API_URL=http://localhost:3000
```

#### 3. Mobile App Configuration

Cấu hình trong `frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://localhost:3000';  // Development
// Hoặc
static const String baseUrl = 'https://your-production-api.com';  // Production
```

### Build Từng Component

#### Build Backend

```bash
cd backend
npm install
npm run build  # Nếu có build script
npm start      # Production mode
# hoặc
npm run dev    # Development mode với hot reload
```

**Lưu ý**: Backend không cần build step riêng (JavaScript runtime), chỉ cần `npm install` và `npm start`.

#### Build Frontend Web

```bash
cd frontend-web-manager
npm install
npm run build        # Production build (tạo thư mục dist/)
npm run preview      # Preview production build
# hoặc
npm run dev          # Development mode (http://localhost:5173)
```

**Output**: Thư mục `dist/` chứa các file tĩnh đã được build, có thể deploy lên web server.

#### Build Mobile Apps

**Android:**
```bash
cd frontend-mobile/EcoCheck_Worker  # hoặc EcoCheck_User
flutter pub get
flutter build apk --release          # APK file
# hoặc
flutter build appbundle --release     # AAB file (cho Google Play)
```

**iOS (chỉ trên macOS):**
```bash
cd frontend-mobile/EcoCheck_Worker
flutter pub get
flutter build ios --release
```

**Output**: 
- Android: `build/app/outputs/flutter-apk/app-release.apk`
- iOS: `build/ios/iphoneos/Runner.app`

### Build Toàn Bộ Hệ Thống (Docker)

Cách đơn giản nhất để build toàn bộ hệ thống:

```bash
# Build tất cả services
docker compose build

# Hoặc build và chạy
docker compose up -d --build
```

### Troubleshooting Build

**Lỗi thường gặp:**

1. **Node.js version không đúng:**
   ```bash
   node --version  # Kiểm tra version
   # Cần Node.js 18+
   ```

2. **Flutter không tìm thấy:**
   ```bash
   flutter doctor  # Kiểm tra cài đặt Flutter
   # Đảm bảo Flutter đã được thêm vào PATH
   ```

3. **Database connection failed:**
   - Kiểm tra PostgreSQL đang chạy
   - Kiểm tra `DATABASE_URL` trong `.env`
   - Kiểm tra firewall cho port 5432

4. **Port đã được sử dụng:**
   ```bash
   # Windows
   netstat -ano | findstr :3000
   taskkill /PID <PID> /F
   
   # Linux/Mac
   lsof -i :3000
   kill -9 <PID>
   ```

### Cài Đặt Hệ Thống (System Install)

Dự án được thiết kế để chạy trong Docker containers, không yêu cầu cài đặt trực tiếp vào hệ thống (`/opt` hoặc `/usr/local`).

**Khuyến nghị**: Sử dụng Docker Compose để quản lý tất cả services.

**Nếu muốn cài đặt trực tiếp:**
- Backend: Chạy `npm install` trong thư mục `backend/`, không cần `make install`
- Frontend Web: Build output trong `dist/` có thể copy lên web server
- Mobile: APK/AAB files có thể cài đặt trực tiếp trên thiết bị

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
- **Report Bugs**: [GitHub Issues](https://github.com/Lil5354/EcoCheck-OLP-2025/issues)
- **Ask Questions**: [GitHub Discussions](https://github.com/Lil5354/EcoCheck-OLP-2025/discussions) (nếu được bật)

## 📚 Documentation

### Tài Liệu Chính
- [CHANGELOG.md](CHANGELOG.md) - Lịch sử thay đổi của dự án
- [CONTRIBUTING.md](CONTRIBUTING.md) - Hướng dẫn đóng góp cho dự án
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - **Cấu trúc chi tiết dự án (Web + Mobile)**
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Tài liệu kiến trúc hệ thống
- [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) - Hướng dẫn testing

### Tài Liệu Về Giấy Phép và Dữ Liệu
- [LICENSE](LICENSE) - Toàn văn giấy phép MIT
- [LICENSES.md](LICENSES.md) - **Tương thích giấy phép của dependencies**
- [DATA_SOURCES.md](DATA_SOURCES.md) - **Nguồn dữ liệu mở và giấy phép**

### Release
- [RELEASE_NOTES.md](RELEASE_NOTES.md) - Release notes cho v1.0.0

### License và Compliance
- [COMPLIANCE_CHECKLIST.md](COMPLIANCE_CHECKLIST.md) - **Checklist tuân thủ OLP 2025**

### API và Testing
- [docs/postman/](docs/postman/) - Postman collection cho API testing

### Bug Tracker và Support
- **GitHub Issues**: [Report bugs and request features](https://github.com/Lil5354/EcoCheck-OLP-2025/issues)
  - Đảm bảo Issues đã được bật trong Repository Settings → General → Features
  - Sử dụng Issues để báo cáo lỗi, đề xuất tính năng, và đặt câu hỏi

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

1. **Computer Vision**: Tự động phân loại rác từ ảnh check-in -
   - Sử dụng Google Gemini 2.5 Flash (multimodal AI)
   - Tự động nhận diện `waste_type` (household, recyclable, bulky, hazardous)
   - Ước tính trọng lượng từ ảnh
   - Confidence score và mô tả chi tiết
   - Checkpoint system cho khả năng rollback

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

## 📝 Thêm License Headers vào Code

Để đáp ứng yêu cầu của cuộc thi OLP 2025, tất cả file nguồn cần có license header MIT.

### Sử Dụng Script Tự Động

**Thêm license headers vào Mobile apps (Dart files):**
```powershell
# Windows
.\scripts\add-license-headers.ps1

# Linux/Mac
chmod +x scripts/add-license-headers.sh
./scripts/add-license-headers.sh
```

**Thêm license headers vào Frontend Web (JSX/JS files):**
```powershell
# Windows
.\scripts\add-license-headers-web.ps1

# Linux/Mac
chmod +x scripts/add-license-headers-web.sh
./scripts/add-license-headers-web.sh
```

**📖 Xem thêm**: [LICENSE_HEADERS_GUIDE.md](LICENSE_HEADERS_GUIDE.md) để biết chi tiết.

## 📜 License

### Giấy Phép Dự Án

Dự án EcoCheck được cấp phép dưới **MIT License**.

Xem file [LICENSE](LICENSE) để biết toàn văn giấy phép.

### Mục Đích Giấy Phép MIT

Dự án chọn MIT License vì:

1. **Tính Tương Thích Cao**: MIT License tương thích với hầu hết các giấy phép mã nguồn mở khác, cho phép dự án sử dụng nhiều thư viện và công cụ khác nhau mà không gặp xung đột giấy phép.

2. **Đơn Giản và Rõ Ràng**: Giấy phép ngắn gọn, dễ hiểu, không có điều khoản phức tạp, giúp người dùng và nhà phát triển dễ dàng hiểu và tuân thủ.

3. **Phù Hợp với Mục Tiêu Smart City**: Cho phép sử dụng thương mại và chỉnh sửa tự do, phù hợp với mục tiêu phát triển các giải pháp Smart City có thể được triển khai rộng rãi.

4. **Khuyến Khích Đóng Góp**: Giấy phép permissive khuyến khích cộng đồng đóng góp, tái sử dụng mã nguồn, và phát triển các dự án dựa trên EcoCheck.

5. **Tuân Thủ Yêu Cầu Cuộc Thi**: MIT License là giấy phép OSI-approved, đáp ứng yêu cầu của cuộc thi OLP 2025.

### Tương Thích Giấy Phép

Tất cả dependencies và thư viện được sử dụng trong dự án đều có giấy phép tương thích với MIT License.

**📖 Xem thêm**: [LICENSES.md](LICENSES.md) để biết chi tiết về tương thích giấy phép của tất cả dependencies.

### Nguồn Dữ Liệu Mở

Dự án sử dụng các nguồn dữ liệu mở với giấy phép tương thích:

- **OpenWeatherMap**: CC BY-SA 4.0
- **OpenAQ**: CC0 1.0 (Public Domain)
- **OpenStreetMap**: ODbL 1.0 (chỉ đọc, không sửa đổi)

**📖 Xem thêm**: [DATA_SOURCES.md](DATA_SOURCES.md) để biết chi tiết về nguồn dữ liệu và giấy phép.

### Yêu Cầu Attribution

Khi sử dụng dự án, bạn cần:

1. **Giữ nguyên copyright notice** trong file LICENSE
2. **Ghi công OpenStreetMap** khi hiển thị bản đồ: "© OpenStreetMap contributors"
3. **Ghi công các nguồn dữ liệu** theo yêu cầu của từng nguồn (xem DATA_SOURCES.md)

### Quyền và Nghĩa Vụ

**Quyền:**
- ✅ Sử dụng thương mại
- ✅ Sửa đổi mã nguồn
- ✅ Phân phối
- ✅ Sử dụng riêng tư

**Nghĩa vụ:**
- ⚠️ Giữ nguyên copyright notice và license
- ⚠️ Ghi công các nguồn dữ liệu mở (theo yêu cầu)

**Không có warranty**: Phần mềm được cung cấp "AS IS", không có bảo hành.

---

**Happy Coding! 🚀**
