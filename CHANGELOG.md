# Changelog

Tất cả các thay đổi đáng chú ý trong dự án này sẽ được ghi lại trong file này.

Format dựa trên [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
và dự án này tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-28

### Added
- **Backend API** với Node.js/Express
  - Tích hợp FIWARE Orion-LD Context Broker
  - RESTful API endpoints cho tất cả các tính năng
  - Socket.IO cho real-time communication
  - Kết nối PostgreSQL với PostGIS và TimescaleDB
  - Route optimization với Hybrid CI-SA algorithm
  - Real-time tracking và analytics
  - Dynamic dispatch system

- **Frontend Web Manager** với React
  - Dashboard với real-time map
  - Quản lý fleet, personnel, schedules
  - Route optimization interface
  - Dynamic dispatch management
  - Analytics và reporting
  - Responsive design

- **Mobile Applications** với Flutter
  - **EcoCheck_Worker**: App cho nhân viên thu gom
    - Quản lý lịch trình và routes
    - Real-time location tracking
    - Check-in và image upload
    - Task management
  - **EcoCheck_User**: App cho người dân
    - Đặt lịch thu gom
    - Gamification system (badges, points, leaderboard)
    - Check-in và thống kê cá nhân
    - Report issues

- **Database Schema**
  - 27+ tables với đầy đủ relationships
  - Spatial indexing với PostGIS
  - Time-series optimization với TimescaleDB
  - Comprehensive gamification system
  - PAYT (Pay-As-You-Throw) billing support

- **Docker Setup**
  - docker-compose.yml với tất cả services
  - Dockerfile cho backend và frontend
  - Automated migrations
  - Health checks

- **Documentation**
  - README.md chi tiết
  - Setup scripts (setup.ps1, setup.sh)
  - API documentation
  - Architecture documentation

### Technical Details
- **Backend**: Node.js, Express, Socket.IO, PostgreSQL, MongoDB, Redis
- **Frontend Web**: React, Vite, React Router
- **Frontend Mobile**: Flutter, Dart
- **Database**: PostgreSQL 15, PostGIS, TimescaleDB
- **FIWARE**: Orion-LD Context Broker
- **License**: MIT License

### Known Issues
- Mobile app cần cấu hình đúng baseUrl theo platform (Android/iOS/Desktop)
- Real-time features yêu cầu WebSocket connection

### Future Enhancements
- Tích hợp AI cho phân loại rác (Computer Vision)
- Predictive Analytics cho dự đoán nhu cầu
- Anomaly Detection cho phát hiện bất thường
- API documentation với Swagger/OpenAPI
- Unit tests và integration tests
- CI/CD pipeline

---

[1.0.0]: https://github.com/Lil5354/EcoCheck-OLP-2025/releases/tag/v1.0.0

