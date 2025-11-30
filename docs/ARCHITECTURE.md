# EcoCheck Architecture

Tài liệu này mô tả kiến trúc tổng thể của hệ thống EcoCheck - Dynamic Waste Collection System.

## System Overview

EcoCheck là một hệ thống quản lý thu gom rác thải động, được xây dựng dựa trên FIWARE platform và sử dụng NGSI-LD standard. Hệ thống bao gồm:

- **Backend API**: Node.js/Express server với Socket.IO
- **Frontend Web Manager**: React-based web application
- **Mobile Applications**: Flutter apps cho Worker và User
- **Database Stack**: PostgreSQL với PostGIS và TimescaleDB
- **FIWARE Integration**: Orion-LD Context Broker
- **Caching**: Redis cho performance optimization

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Client Layer                              │
├──────────────────┬──────────────────┬───────────────────────┤
│  Web Manager    │  Mobile Worker   │  Mobile User          │
│  (React)        │  (Flutter)        │  (Flutter)            │
│  Port: 3001     │                   │                       │
└────────┬────────┴──────────┬────────┴───────────┬───────────┘
         │                   │                    │
         │  HTTP/REST        │  HTTP/REST         │  HTTP/REST
         │  WebSocket        │  WebSocket         │  WebSocket
         └───────────────────┼────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│                    Backend API Layer                         │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Express.js Server (Port: 3000)                       │  │
│  │  - RESTful API Endpoints                              │  │
│  │  - Socket.IO for Real-time Communication              │  │
│  │  - Route Optimization (Hybrid CI-SA Algorithm)       │  │
│  │  - Dynamic Dispatch System                            │  │
│  └────────────────────────────────────────────────────────┘  │
└────────┬──────────────┬──────────────┬──────────────┬────────┘
         │              │              │              │
    ┌────▼────┐   ┌────▼────┐   ┌────▼────┐   ┌────▼────┐
    │PostgreSQL│   │  Redis  │   │ MongoDB │   │Orion-LD │
    │PostGIS   │   │ (Cache) │   │(Orion)  │   │(NGSI-LD)│
    │Timescale │   │         │   │         │   │Port:1026│
    │Port:5432 │   │Port:6379│   │Port:27017│   │         │
    └──────────┘   └─────────┘   └─────────┘   └─────────┘
```

## Components

### 1. Backend API (`backend/`)

**Technology Stack:**
- Node.js 18+
- Express.js
- Socket.IO
- PostgreSQL client (pg)
- Axios (for FIWARE integration)

**Key Features:**
- RESTful API endpoints
- Real-time communication với Socket.IO
- Route optimization với Hybrid CI-SA algorithm
- Dynamic dispatch system
- Analytics và reporting
- FIWARE Orion-LD integration

**Main Files:**
- `backend/src/index.js`: Main application entry point
- `backend/src/orionld.js`: FIWARE Orion-LD client utilities
- `backend/src/realtime.js`: Real-time store và route management

**API Endpoints:**
- `/health`: Health check
- `/api/status`: System status
- `/api/v1/schedules`: Schedule management
- `/api/routes/active`: Active routes
- `/api/rt/*`: Real-time endpoints
- `/api/analytics/*`: Analytics endpoints

### 2. Frontend Web Manager (`frontend-web-manager/`)

**Technology Stack:**
- React 18+
- Vite
- React Router
- Socket.IO client

**Key Features:**
- Dashboard với real-time map
- Fleet management
- Personnel management
- Schedule management
- Route optimization interface
- Dynamic dispatch management
- Analytics và reporting

**Main Files:**
- `src/App.jsx`: Main application component
- `src/AppRouter.jsx`: Router configuration
- `src/pages/`: Page components
- `src/components/`: Reusable components

### 3. Mobile Applications (`frontend-mobile/`)

#### 3.1 EcoCheck_Worker

**Technology Stack:**
- Flutter/Dart
- BLoC pattern
- HTTP client

**Key Features:**
- Schedule management
- Route tracking
- Check-in functionality
- Image upload
- Real-time location tracking

#### 3.2 EcoCheck_User

**Technology Stack:**
- Flutter/Dart
- BLoC pattern
- HTTP client

**Key Features:**
- Schedule booking
- Gamification (badges, points, leaderboard)
- Check-in và statistics
- Issue reporting

### 4. Database (`db/`)

**Technology Stack:**
- PostgreSQL 15
- PostGIS (spatial extension)
- TimescaleDB (time-series extension)

**Key Features:**
- 27+ tables với comprehensive schema
- Spatial indexing với PostGIS
- Time-series optimization với TimescaleDB
- Automatic triggers cho data integrity
- Gamification system
- PAYT (Pay-As-You-Throw) billing support

**Main Tables:**
- `users`: User accounts
- `vehicles`: Fleet management
- `routes`: Route definitions
- `schedules`: Collection schedules
- `checkins`: Check-in records
- `points`: Collection points (spatial)
- `alerts`: Alert system
- `badges`, `user_badges`: Gamification
- `billing`: PAYT billing

**Migrations:**
- `db/migrations/`: SQL migration scripts
- Tự động chạy khi backend container khởi động

### 5. FIWARE Integration

**Orion-LD Context Broker:**
- NGSI-LD standard
- Port: 1026
- MongoDB backend
- Context files: `backend/public/contexts/ecocheck.jsonld`

**Integration:**
- Backend tích hợp với Orion-LD qua HTTP API
- Context entities cho waste collection
- Real-time updates qua subscriptions

### 6. Caching (Redis)

**Usage:**
- Session management
- API response caching
- Real-time data caching
- Performance optimization

## Data Flow

### 1. Real-time Tracking Flow

```
Mobile App (Worker)
    │
    ├─> Check-in Event
    │   └─> POST /api/rt/checkin
    │       └─> Backend API
    │           ├─> Update Database (PostgreSQL)
    │           ├─> Update Real-time Store
    │           ├─> Emit Socket.IO Event
    │           └─> Update FIWARE Orion-LD
    │
    └─> Location Update
        └─> WebSocket Message
            └─> Backend API
                └─> Broadcast to Web Manager
```

### 2. Route Optimization Flow

```
Web Manager
    │
    └─> Request Route Optimization
        └─> POST /api/routes/optimize
            └─> Backend API
                ├─> Fetch Collection Points
                ├─> Calculate Distance Matrix (OSRM/Haversine)
                ├─> Run Hybrid CI-SA Algorithm
                ├─> Save Optimized Route
                └─> Return Route Data
```

### 3. Dynamic Dispatch Flow

```
Alert System
    │
    └─> Alert Created
        └─> Backend API
            ├─> Find Available Vehicles
            ├─> Calculate Optimal Assignment
            ├─> Create Dispatch
            ├─> Notify via Socket.IO
            └─> Update FIWARE Context
```

## Security

- **Authentication**: JWT tokens (planned)
- **Authorization**: Role-based access control
- **Data Validation**: Input validation trên backend
- **CORS**: Configured cho cross-origin requests
- **Environment Variables**: Sensitive data trong .env files

## Performance Optimization

- **Database Indexing**: Spatial indexes với PostGIS
- **Caching**: Redis cho frequently accessed data
- **Compression**: Gzip compression cho HTTP responses
- **Connection Pooling**: PostgreSQL connection pooling
- **Time-series Optimization**: TimescaleDB cho time-series data

## Scalability

- **Horizontal Scaling**: Stateless backend có thể scale horizontally
- **Database Scaling**: PostgreSQL với read replicas (planned)
- **Caching Layer**: Redis cluster (planned)
- **Load Balancing**: Nginx reverse proxy (planned)

## Deployment

### Docker Compose

Tất cả services được containerized với Docker:
- `docker-compose.yml`: Service definitions
- Health checks cho tất cả services
- Volume mounts cho persistent data
- Network isolation

### Services:
1. `orion-ld`: FIWARE Orion-LD Context Broker
2. `mongo-db`: MongoDB cho Orion-LD
3. `postgres`: PostgreSQL với PostGIS và TimescaleDB
4. `redis`: Redis cache
5. `backend`: Node.js backend API
6. `frontend-web`: React web application

## Development Workflow

1. **Local Development**:
   - `setup.ps1` / `setup.sh`: One-command setup
   - Hot reload cho backend và frontend
   - Docker Compose cho services

2. **Testing**:
   - Manual testing với Postman collection
   - Integration testing scripts

3. **Deployment**:
   - Docker images cho production
   - Environment-specific configurations

## Future Enhancements

- **AI Integration**:
  - Computer Vision cho phân loại rác
  - Predictive Analytics cho dự đoán nhu cầu
  - Anomaly Detection cho phát hiện bất thường

- **API Documentation**:
  - Swagger/OpenAPI documentation
  - Interactive API explorer

- **Testing**:
  - Unit tests
  - Integration tests
  - E2E tests

- **CI/CD**:
  - GitHub Actions
  - Automated testing
  - Automated deployment

## References

- [FIWARE Orion-LD Documentation](https://github.com/FIWARE/context.Orion-LD)
- [PostGIS Documentation](https://postgis.net/documentation/)
- [TimescaleDB Documentation](https://docs.timescale.com/)
- [React Documentation](https://react.dev/)
- [Flutter Documentation](https://flutter.dev/docs)

---

**Last Updated**: 2025-01-28
**Version**: 1.0.0

