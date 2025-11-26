# EcoCheck-OLP-2025 - Dynamic Waste Collection System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

EcoCheck is a comprehensive, FIWARE-based platform for dynamic waste collection management, designed for the OLP 2025 competition. It includes a backend API, a frontend web manager, mobile applications (Flutter), a complete database stack (PostgreSQL, PostGIS, TimescaleDB), and the FIWARE Orion-LD Context Broker.

## 🚀 Quick Start (5-10 Minutes)

This guide will walk you through setting up the entire EcoCheck platform on your local machine using Docker.

### 1. Prerequisites

Make sure you have the following software installed and running:

- **Git**: For cloning the repository.
- **Docker Desktop**: To run the containerized application stack. Ensure the Docker engine is running before you start.

### 2. Installation & Setup

**Step 1: Clone the Repository**

Open your terminal and clone the project:

```bash
git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
cd EcoCheck-OLP-2025
```

**Step 2: Launch All Services**

This single command will build the necessary Docker images and start all services (Backend, Frontend, Databases, FIWARE Broker) in the background.

```bash
docker compose up -d --build
```

The first time you run this, it may take several minutes to download and build everything.

**Step 3: Run Database Migrations (Crucial Step)**

After the containers are up and running, the PostgreSQL database is still empty. You **must** run the migration scripts to create the tables and seed initial data. 

Execute the following command in your terminal:

```bash
docker compose exec postgres bash -c "cd /app/db && bash ./run_migrations.sh"
```

This command runs the migration script *inside* the running `postgres` container. You should see a success message with a summary of the created tables and records.

### 3. Verification

Your environment is now ready! You can verify that all services are running correctly by accessing these URLs in your browser:

| Service | URL | Expected Result |
| :--- | :--- | :--- |
| **Frontend Web Manager** | `http://localhost:3001` | The EcoCheck login page. |
| **Backend Health Check** | `http://localhost:3000/health` | A JSON response like `{"status":"ok"}`. |
| **FIWARE Orion-LD** | `http://localhost:1026/version` | A JSON response with Orion-LD version info. |

### 4. Project Structure

- `/backend`: Node.js backend API.
- `/frontend-web-manager`: React-based web application for managers.
- `/frontend-mobile`: Flutter mobile applications (User App & Worker App).
- `/db`: Contains all database-related files:
  - `/init`: SQL scripts for initial database setup (e.g., creating extensions).
  - `/migrations`: SQL scripts for creating schema and seeding data.
  - `run_migrations.sh` / `.ps1`: Scripts to run migrations.
- `docker-compose.yml`: Defines all the services, networks, and volumes for the project.

## 🗄️ Database Architecture

The EcoCheck database is built on **PostgreSQL 15** with **PostGIS** for spatial data and **TimescaleDB** for time-series optimization. It follows FIWARE NGSI-LD standards and implements a comprehensive schema for dynamic waste collection management.

### Technology Stack
- **PostgreSQL 15**: Core relational database
- **PostGIS**: Spatial and geographic data support
- **TimescaleDB**: Time-series data optimization
- **Extensions**: uuid-ossp, pg_trgm, btree_gist

### Key Features
- ✅ Spatial indexing for geographic queries
- ✅ Time-series optimization for tracking and analytics
- ✅ Automatic triggers for data integrity
- ✅ Comprehensive gamification system
- ✅ Pay-As-You-Throw (PAYT) billing support
- ✅ Real-time vehicle tracking
- ✅ Multi-role user management

### Core Tables

#### Master Data
- **depots**: Collection stations/depots
- **dumps**: Waste disposal sites and transfer stations
- **vehicles**: Collection vehicles (trucks, trikes, etc.)
- **personnel**: Staff members (drivers, collectors, managers)

#### User Management
- **users**: All system users (citizens, workers, managers, admins)
- **user_addresses**: User registered addresses
- **points**: Collection points (linked to addresses or ghost points)
- **collection_schedules**: Citizen waste collection requests

#### Operations
- **checkins**: Waste check-ins from citizens
- **routes**: Collection routes
- **route_stops**: Stops within routes
- **alerts**: Real-time alerts (missed points, late check-ins)
- **incidents**: Reported issues
- **exceptions**: Collection exceptions

#### Gamification
- **user_points**: User point balances and levels
- **point_transactions**: Point transaction history
- **badges**: Available badges
- **user_badges**: Badges earned by users

#### Billing (PAYT)
- **billing_cycles**: Monthly billing periods
- **user_bills**: User bills per cycle

#### Analytics
- **vehicle_tracking**: Real-time vehicle GPS tracking (hypertable)
- **system_logs**: System activity logs (hypertable)

### Connection Details

#### Docker Environment
- **Host**: localhost
- **Port**: 5432
- **Database**: ecocheck
- **User**: ecocheck_user
- **Password**: ecocheck_pass

#### Connection String
```
postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck
```

### Database Features

#### 1. Spatial Queries
All geographic data uses PostGIS `geography(Point,4326)` type with GIST indexes for efficient spatial queries.

```sql
-- Find points within 1km radius
SELECT * FROM points 
WHERE ST_DWithin(geom, ST_GeogFromText('POINT(106.6958 10.7769)'), 1000);
```

#### 2. Time-Series Optimization
TimescaleDB hypertables for high-volume time-series data:
- `checkins`: Partitioned by `created_at`
- `point_transactions`: Partitioned by `created_at`
- `vehicle_tracking`: Partitioned by `recorded_at`
- `system_logs`: Partitioned by `created_at`

#### 3. Gamification System
Points are awarded based on waste type:
- Household: 10 points
- Recyclable: 20 points
- Organic: 15 points
- Hazardous: 25 points
- Bulky: 30 points

Levels:
- Level 1: 0-49 points
- Level 2: 50-199 points
- Level 3: 200-499 points
- Level 4: 500-999 points
- Level 5: 1000+ points

## 🔧 Troubleshooting

Here are solutions to common issues you might encounter.

**Q: I get an error like `Cannot connect to the Docker daemon`.**

**A:** This means Docker Desktop is not running. Open the Docker Desktop application and wait for the engine to start (the whale icon should be steady).

**Q: A service (e.g., `backend`) is not starting or is unhealthy.**

**A:** Check the logs for that specific container to find the error message. Replace `backend` with the name of the service you want to inspect.

```bash
docker compose logs --tail=100 backend
```

**Q: I want to reset my database and start over.**

**A:** To completely remove all data (including database volumes) and stop all containers, run:

```bash
docker compose down -v
```

After this, you can go back to **Step 2** of the installation to start fresh.

**Q: How can I connect to the PostgreSQL database directly?**

**A:** You can use any database client (like DBeaver, pgAdmin, or `psql`) with these credentials:
- **Host**: `localhost`
- **Port**: `5432`
- **Database**: `ecocheck`
- **User**: `ecocheck_user`
- **Password**: `ecocheck_pass`

Or, you can get a shell inside the container:

```bash
docker compose exec postgres psql -U ecocheck_user -d ecocheck
```

## 📱 Mobile Applications

The project includes two Flutter mobile applications located in `/frontend-mobile`:

### EcoCheck User App (`/frontend-mobile/EcoCheck_User`)
For citizens to request waste collection, check schedules, and track gamification points.

**Key Features:**
- Schedule waste collection with flexible time slots
- Smart check-in with location and waste type
- Personal statistics and gamification (points, badges, leaderboard)
- Real-time notifications

**Tech Stack:**
- Flutter 3.x, Dart 3.x
- BLoC state management
- Dio for networking
- Google Maps Flutter

**Quick Start:**
```bash
cd frontend-mobile/EcoCheck_User
flutter pub get
flutter run
```

**Demo Account:**
- Phone: `0901234567`
- Password: `123456`

### EcoCheck Worker App (`/frontend-mobile/EcoCheck_Worker`)
For workers to view assigned routes, check in at collection points, and report incidents.

**Key Features:**
- View assigned collection schedules
- Route navigation and map integration
- Update work status (start, complete)
- Report incidents and exceptions

**Tech Stack:**
- Flutter 3.x, Dart 3.x
- BLoC state management
- Dio for networking
- Google Maps Flutter

**Quick Start:**
```bash
cd frontend-mobile/EcoCheck_Worker
flutter pub get
flutter run
```

**Demo Account:**
- Phone: `0987654321`
- Password: `123456`

**Note:** Ensure backend is running at `http://localhost:3000` (or update API URL in app constants).

## 🌐 API Endpoints

### Manager Endpoints (Require Manager Role)
- `POST /api/manager/personnel` - Create worker account
- `GET /api/manager/personnel` - List all personnel
- `GET /api/schedules` - Get collection schedules
- `POST /api/schedules/:id/assign` - Assign personnel to schedule

### Operations
- `GET /api/alerts` - Get real-time alerts
- `POST /api/alerts/:alertId/dispatch` - Get nearest vehicles for dispatch
- `POST /api/alerts/:alertId/assign` - Assign vehicle to alert
- `GET /api/exceptions` - Get collection exceptions
- `POST /api/exceptions/:id/approve` - Approve exception
- `POST /api/exceptions/:id/reject` - Reject exception
- `POST /api/optimize/vrp` - Optimize routes (VRP algorithm)

### Analytics
- `GET /api/analytics/summary` - Get summary statistics
- `GET /api/analytics/timeseries` - Get time-series data
- `GET /api/analytics/predict` - Get forecast predictions

### Master Data
- `GET /api/master/fleet` - Get all vehicles
- `POST /api/master/fleet` - Create vehicle
- `PATCH /api/master/fleet/:id` - Update vehicle
- `DELETE /api/master/fleet/:id` - Delete vehicle
- `GET /api/master/depots` - Get all depots
- `GET /api/master/dumps` - Get all dumps

## 🏗️ Architecture

### Backend
- **Framework**: Node.js with Express.js
- **Database**: PostgreSQL 15 with PostGIS and TimescaleDB
- **Context Broker**: FIWARE Orion-LD (NGSI-LD)
- **Real-time**: Socket.IO for live updates

### Frontend Web Manager
- **Framework**: React with Vite
- **State Management**: React Hooks
- **Maps**: MapLibre GL for route visualization
- **Charts**: Custom SVG-based charts

### Mobile Apps
- **Framework**: Flutter
- **State Management**: BLoC pattern
- **Architecture**: Clean Architecture with separation of concerns

## 📊 Key Features

### CN7: Dynamic Dispatch
- Automated detection of missed collection points
- Late check-in alerts
- Nearest vehicle assignment using Haversine distance
- Real-time route re-routing

### CN8: Analytics & Prediction
- Time-series data visualization
- 7-day forecast predictions
- Summary statistics (total collection, completion rate, fuel savings)
- Waste type distribution

### CN15: Exception Handling
- Exception reporting (cannot collect, road blocked, wrong waste type, vehicle breakdown)
- Manager approval/rejection workflow
- Exception resolution planning

### Route Optimization (VRP)
- Nearest Neighbor algorithm
- 2-opt optimization
- Cross-route optimization
- Multi-vehicle assignment
- Distance and time calculations using PostGIS

## 🔐 Security

- Role-based access control (RBAC)
- Manager-only endpoints protected by `requireManager` middleware
- Input validation and sanitization
- SQL injection prevention using parameterized queries

## 📝 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

This project was developed for the OLP 2025 competition. For questions or issues, please open an issue on the GitHub repository.

---

**Copyright (c) 2025 Lil5354**
