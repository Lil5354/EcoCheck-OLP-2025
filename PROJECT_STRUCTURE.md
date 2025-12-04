# Cấu Trúc Dự Án EcoCheck

Tài liệu này mô tả chi tiết cấu trúc của dự án EcoCheck, một hệ thống quản lý thu gom rác thải động với 3 thành phần chính: Backend, Frontend Web, và Frontend Mobile.

## 📋 Tổng Quan

Dự án EcoCheck được tổ chức theo mô hình **Monorepo** (một repository chứa nhiều dự án con), bao gồm:

1. **Backend API** (Node.js/Express) - Xử lý logic nghiệp vụ và tích hợp FIWARE
2. **Frontend Web Manager** (React) - Ứng dụng web cho nhà quản lý
3. **Frontend Mobile** (Flutter) - 2 ứng dụng di động (Worker & User)
4. **Database** (PostgreSQL/PostGIS) - Cơ sở dữ liệu và migrations
5. **Infrastructure** (Docker) - Containerization và deployment

---

## 🗂️ Cấu Trúc Thư Mục

```
EcoCheck-OLP-2025/
├── backend/                    # Backend API Server
│   ├── src/                   # Mã nguồn chính
│   │   ├── index.js          # Entry point, Express server
│   │   ├── orionld.js        # FIWARE Orion-LD integration
│   │   ├── realtime.js        # Real-time store và Socket.IO
│   │   └── services/         # Business logic services
│   ├── public/               # Static files
│   │   ├── contexts/         # NGSI-LD context files
│   │   └── uploads/          # Uploaded images
│   ├── package.json          # Node.js dependencies
│   ├── Dockerfile            # Docker image cho backend
│   └── entrypoint.sh         # Container startup script
│
├── frontend-web-manager/      # Web Application (React)
│   ├── src/                  # Mã nguồn React
│   │   ├── App.jsx           # Main component
│   │   ├── pages/            # Page components
│   │   ├── components/       # Reusable components
│   │   ├── lib/              # Utilities và API client
│   │   └── navigation/       # Navigation components
│   ├── public/               # Static assets
│   ├── dist/                 # Build output
│   ├── package.json          # Dependencies
│   ├── vite.config.js        # Vite configuration
│   └── Dockerfile            # Docker image cho frontend
│
├── frontend-mobile/           # Mobile Applications (Flutter)
│   ├── EcoCheck_Worker/      # App cho nhân viên thu gom
│   │   ├── lib/              # Dart source code
│   │   │   ├── main.dart     # Entry point
│   │   │   ├── core/         # Core functionality
│   │   │   │   ├── constants/ # API constants
│   │   │   │   └── di/       # Dependency injection
│   │   │   ├── data/         # Data layer
│   │   │   ├── domain/       # Business logic
│   │   │   └── presentation/ # UI layer
│   │   ├── pubspec.yaml      # Flutter dependencies
│   │   └── android/          # Android-specific code
│   │   └── ios/              # iOS-specific code
│   │
│   └── EcoCheck_User/        # App cho người dân
│       ├── lib/              # Dart source code (tương tự Worker)
│       ├── pubspec.yaml      # Flutter dependencies
│       └── android/          # Android-specific code
│       └── ios/              # iOS-specific code
│
├── db/                        # Database Scripts
│   ├── init/                  # Initialization scripts
│   │   └── 01_init_extensions.sql
│   ├── migrations/            # Migration scripts (31 files)
│   │   ├── 001_create_users.sql
│   │   ├── 002_create_vehicles.sql
│   │   └── ...
│   ├── run_migrations.sh      # Migration runner (Linux/Mac)
│   ├── run_migrations.ps1     # Migration runner (Windows)
│   └── seed_*.sql             # Seed data scripts
│
├── docs/                      # Documentation
│   ├── ARCHITECTURE.md        # Kiến trúc hệ thống
│   ├── TESTING_GUIDE.md       # Hướng dẫn testing
│   ├── contexts/              # NGSI-LD context files
│   └── postman/               # Postman collections
│
├── scripts/                   # Utility Scripts
│   ├── setup.ps1              # One-command setup (Windows)
│   ├── setup.sh               # One-command setup (Linux/Mac)
│   ├── start-dev.ps1          # Start development mode
│   ├── run-*.ps1              # Various run scripts
│   └── test-*.ps1             # Test scripts
│
├── seeds/                     # Seed Data
│   └── ngsi-ld/               # NGSI-LD formatted data
│       └── cn14/              # Context files
│
├── docker-compose.yml         # Docker Compose configuration
├── Dockerfile.render          # Production Dockerfile
├── LICENSE                    # MIT License
├── README.md                  # Main documentation
├── CHANGELOG.md               # Version history
├── CONTRIBUTING.md            # Contribution guidelines
├── DATA_SOURCES.md            # Open data sources
├── LICENSES.md                # License compatibility
└── PROJECT_STRUCTURE.md       # This file
```

---

## 🏗️ Kiến Trúc Từng Thành Phần

### 1. Backend (`/backend`)

**Công nghệ:**
- Node.js 18+
- Express.js
- Socket.IO
- PostgreSQL client (pg)

**Cấu trúc:**
```
backend/
├── src/
│   ├── index.js              # Main server file
│   │   ├── Express app setup
│   │   ├── Socket.IO setup
│   │   ├── API routes
│   │   ├── Route optimization (VRP)
│   │   ├── Real-time tracking
│   │   └── FIWARE integration
│   ├── orionld.js            # Orion-LD client utilities
│   ├── realtime.js            # Real-time data store
│   └── services/             # Business logic
│       ├── routeOptimizer.js
│       ├── dispatchService.js
│       └── analyticsService.js
├── public/
│   ├── contexts/             # NGSI-LD context files
│   └── uploads/              # User-uploaded images
└── package.json
```

**Cách Build:**
```bash
cd backend
npm install
npm run dev        # Development mode
npm start          # Production mode
```

**Environment Variables:**
- `DATABASE_URL` - PostgreSQL connection string
- `ORION_LD_URL` - FIWARE Orion-LD endpoint
- `PORT` - Server port (default: 3000)
- `OPENWEATHER_API_KEY` - OpenWeatherMap API key (optional)
- `AIRQUALITY_API_KEY` - OpenAQ API key (optional)

---

### 2. Frontend Web Manager (`/frontend-web-manager`)

**Công nghệ:**
- React 19+
- Vite
- React Router
- Socket.IO client
- MapLibre GL

**Cấu trúc:**
```
frontend-web-manager/
├── src/
│   ├── App.jsx                # Main app component
│   ├── AppRouter.jsx          # Route configuration
│   ├── pages/                 # Page components
│   │   ├── operations/        # Operations pages
│   │   │   ├── RouteOptimization.jsx
│   │   │   ├── Schedules.jsx
│   │   │   └── ...
│   │   └── dashboard/        # Dashboard pages
│   ├── components/            # Reusable components
│   │   ├── RealtimeMap.jsx
│   │   ├── Charts.jsx
│   │   └── ...
│   ├── lib/                   # Utilities
│   │   └── api.js             # API client
│   └── navigation/            # Navigation components
├── public/                    # Static assets
└── package.json
```

**Cách Build:**
```bash
cd frontend-web-manager
npm install
npm run dev        # Development mode (http://localhost:5173)
npm run build      # Production build
npm run preview    # Preview production build
```

**Environment Variables:**
- `VITE_API_URL` - Backend API URL (default: http://localhost:3000)

---

### 3. Frontend Mobile (`/frontend-mobile`)

#### 3.1 EcoCheck_Worker

**Công nghệ:**
- Flutter/Dart
- BLoC pattern
- Dio (HTTP client)
- Socket.IO client
- Geolocator

**Cấu trúc:**
```
EcoCheck_Worker/
├── lib/
│   ├── main.dart              # Entry point
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_constants.dart  # API configuration
│   │   └── di/
│   │       └── injection_container.dart
│   ├── data/
│   │   ├── models/            # Data models
│   │   ├── repositories/      # Data repositories
│   │   └── data_sources/      # API data sources
│   ├── domain/
│   │   ├── entities/          # Business entities
│   │   └── usecases/          # Business logic
│   └── presentation/
│       ├── blocs/             # BLoC state management
│       ├── screens/           # Screen components
│       └── widgets/           # Reusable widgets
├── pubspec.yaml
└── android/                   # Android-specific
└── ios/                       # iOS-specific
```

**Cách Build:**
```bash
cd frontend-mobile/EcoCheck_Worker
flutter pub get
flutter run                    # Development mode
flutter build apk             # Android build
flutter build ios             # iOS build
```

#### 3.2 EcoCheck_User

**Cấu trúc tương tự EcoCheck_Worker**, nhưng tập trung vào:
- Gamification (badges, points, leaderboard)
- Schedule booking
- Check-in functionality
- User statistics

**Cách Build:**
```bash
cd frontend-mobile/EcoCheck_User
flutter pub get
flutter run
```

---

### 4. Database (`/db`)

**Cấu trúc:**
```
db/
├── init/
│   └── 01_init_extensions.sql    # PostGIS, TimescaleDB setup
├── migrations/
│   ├── 001_create_users.sql
│   ├── 002_create_vehicles.sql
│   ├── 003_create_routes.sql
│   └── ... (31 files total)
├── run_migrations.sh              # Migration runner
├── seed_data.sql                  # Seed collection points
├── seed_worker_schedules.sql     # Seed worker data
└── seed_groups_data.sql           # Seed gamification data
```

**Cách Chạy Migrations:**
```bash
# Linux/Mac
cd db
bash run_migrations.sh

# Windows
cd db
.\run_migrations.ps1

# Hoặc qua Docker
docker compose exec postgres bash -c "cd /app/db && bash ./run_migrations.sh"
```

---

## 🔄 Luồng Tương Tác Giữa Các Thành Phần

### Luồng Dữ Liệu Cơ Bản

```
┌─────────────────┐
│  Mobile Apps    │
│  (Flutter)      │
└────────┬────────┘
         │ HTTP/REST
         │ WebSocket
         ▼
┌─────────────────┐
│  Backend API    │
│  (Node.js)      │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│PostgreSQL│ │Orion-LD  │
│PostGIS  │ │(NGSI-LD) │
└────────┘ └──────────┘
```

### Luồng Real-time

```
Mobile App (Worker)
    │
    ├─> Check-in Event
    │   └─> POST /api/rt/checkin
    │       └─> Backend
    │           ├─> Update PostgreSQL
    │           ├─> Update Orion-LD
    │           └─> Emit Socket.IO Event
    │               └─> Web Dashboard (Real-time update)
    │
    └─> Location Update
        └─> WebSocket Message
            └─> Backend
                └─> Broadcast to Web Dashboard
```

---

## 🚀 Cách Khởi Động Toàn Bộ Hệ Thống

### Option 1: One-Command Setup (Khuyến nghị)

```bash
# Windows
.\setup.ps1

# Linux/Mac
chmod +x setup.sh
./setup.sh
```

### Option 2: Docker Compose

```bash
docker compose up -d --build
```

### Option 3: Development Mode (Từng Component)

```bash
# Terminal 1: Backend
cd backend
npm install
npm run dev

# Terminal 2: Frontend Web
cd frontend-web-manager
npm install
npm run dev

# Terminal 3: Mobile (Flutter)
cd frontend-mobile/EcoCheck_Worker
flutter run
```

---

## 📦 Dependencies Chính

### Backend
- **express**: Web framework
- **socket.io**: Real-time communication
- **pg**: PostgreSQL client
- **axios**: HTTP client

### Frontend Web
- **react**: UI library
- **vite**: Build tool
- **maplibre-gl**: Map library
- **socket.io-client**: WebSocket client

### Frontend Mobile
- **flutter_bloc**: State management
- **dio**: HTTP client
- **geolocator**: Location services
- **flutter_map**: Map library

---

## 🔧 Cấu Hình Môi Trường

### Backend (.env)
```env
DATABASE_URL=postgresql://user:pass@localhost:5432/ecocheck
ORION_LD_URL=http://localhost:1026
PORT=3000
OPENWEATHER_API_KEY=your_key_here
```

### Frontend Web (.env)
```env
VITE_API_URL=http://localhost:3000
```

### Mobile (api_constants.dart)
```dart
static const String baseUrl = 'https://your-api.com';
```

---

## 📚 Tài Liệu Liên Quan

- [README.md](README.md) - Hướng dẫn tổng quan
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Kiến trúc chi tiết
- [CONTRIBUTING.md](CONTRIBUTING.md) - Hướng dẫn đóng góp
- [DATA_SOURCES.md](DATA_SOURCES.md) - Nguồn dữ liệu mở
- [LICENSES.md](LICENSES.md) - Tương thích giấy phép

---

**Last Updated**: 2025-01-28  
**Version**: 1.0.0

