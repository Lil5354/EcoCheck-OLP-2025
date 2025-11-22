# EcoCheck Database Guide

## Overview

The EcoCheck project now uses a **comprehensive PostgreSQL database** with PostGIS and TimescaleDB extensions, replacing the previous mock data approach. This provides a production-ready, scalable, and FIWARE NGSI-LD compliant data layer.

## Database Architecture

### Technology Stack
- **PostgreSQL 15**: Core relational database
- **PostGIS**: Spatial and geographic data support
- **TimescaleDB**: Time-series data optimization
- **Docker**: Containerized deployment

### Key Features
- ✅ 27 tables covering all project features
- ✅ Spatial indexing for geographic queries
- ✅ Time-series optimization for high-volume data
- ✅ Automatic triggers for data integrity
- ✅ Comprehensive gamification system
- ✅ PAYT (Pay-As-You-Throw) billing support
- ✅ Real-time vehicle tracking
- ✅ Multi-role user management

## Quick Start

### Option 1: Using Docker Compose (Recommended)

1. **Start the database**:
   ```bash
   docker-compose up -d postgres
   ```

2. **Wait for database to be ready**:
   ```bash
   docker-compose exec postgres pg_isready -U ecocheck_user -d ecocheck
   ```

3. **Run migrations**:
   ```bash
   cd db
   ./run_migrations.sh      # Linux/Mac
   # OR
   .\run_migrations.ps1     # Windows
   ```

### Option 2: Manual Setup

1. **Create database**:
   ```bash
   createdb -U postgres ecocheck
   ```

2. **Run migrations in order**:
   ```bash
   psql -U postgres -d ecocheck -f db/migrations/001_init.sql
   psql -U postgres -d ecocheck -f db/migrations/002_comprehensive_schema.sql
   psql -U postgres -d ecocheck -f db/migrations/003_seed_badges.sql
   psql -U postgres -d ecocheck -f db/migrations/004_enhanced_seed_data.sql
   psql -U postgres -d ecocheck -f db/migrations/005_seed_addresses_points.sql
   psql -U postgres -d ecocheck -f db/migrations/006_seed_checkins_operations.sql
   psql -U postgres -d ecocheck -f db/migrations/007_seed_routes_billing.sql
   ```

## Connection Details

### Docker Environment
```
Host: localhost
Port: 5432
Database: ecocheck
User: ecocheck_user
Password: ecocheck_pass
```

### Connection String
```
postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck
```

## Viewing Data

### Using psql
```bash
# Connect to database
psql -U ecocheck_user -d ecocheck

# List all tables
\dt

# View table structure
\d table_name

# Query data
SELECT * FROM users LIMIT 10;
```

### Using pgAdmin
1. Add new server
2. Enter connection details above
3. Browse database schema

### Using Backend API

The backend API now connects to the real database instead of mock data:

```bash
cd backend
npm install
npm start
```

## Important Endpoints (Now Database-Backed)

All endpoints now query the real database:

- **Get fleet**: `http://localhost:3000/api/master/fleet`
- **Get collection points**: `http://localhost:3000/api/points`
- **Get real-time vehicles**: `http://localhost:3000/api/rt/vehicles`
- **Get alerts**: `http://localhost:3000/api/rt/alerts`
- **Get exceptions**: `http://localhost:3000/api/exceptions`
- **Get check-ins**: `http://localhost:3000/api/checkins`
- **Get routes**: `http://localhost:3000/api/routes`
- **Get user points**: `http://localhost:3000/api/gamification/points`
- **Get badges**: `http://localhost:3000/api/gamification/badges`

## Database Documentation

Comprehensive documentation is available in the `db/` directory:

- **[README.md](db/README.md)**: Setup and usage guide
- **[SCHEMA.md](db/SCHEMA.md)**: Detailed schema documentation
- **[QUERIES.md](db/QUERIES.md)**: Common query reference
- **[ER_DIAGRAM.md](db/ER_DIAGRAM.md)**: Entity relationship diagrams
- **[DATABASE_IMPLEMENTATION_SUMMARY.md](db/DATABASE_IMPLEMENTATION_SUMMARY.md)**: Implementation summary

## Sample Data

The database is pre-populated with sample data:

- **5 depots** (collection stations)
- **4 dumps** (disposal sites)
- **12 vehicles** (various types)
- **15 personnel** (drivers, collectors, managers)
- **15 users** (citizens, workers, managers, admin)
- **17 addresses** and collection points
- **17 badges** for gamification
- **Sample check-ins, routes, incidents, and bills**

## Key Tables

### Master Data
- `depots`: Collection stations
- `dumps`: Waste disposal sites
- `vehicles`: Fleet management
- `personnel`: Staff management

### User Management
- `users`: All system users
- `user_addresses`: User addresses
- `points`: Collection points

### Operations
- `checkins`: Waste check-ins (TimescaleDB hypertable)
- `routes`: Collection routes
- `route_stops`: Route stops
- `incidents`: Reported issues
- `exceptions`: Collection exceptions

### Gamification
- `user_points`: Point balances and levels
- `point_transactions`: Transaction history (TimescaleDB hypertable)
- `badges`: Available badges
- `user_badges`: Earned badges

### Billing
- `billing_cycles`: Monthly billing periods
- `user_bills`: User bills

### Analytics
- `vehicle_tracking`: Real-time GPS (TimescaleDB hypertable)
- `system_logs`: System logs (TimescaleDB hypertable)

## Maintenance

### Regular Maintenance
```sql
-- Weekly
VACUUM ANALYZE;

-- Monthly
REINDEX DATABASE ecocheck;
```

### Backup
```bash
pg_dump -U ecocheck_user -d ecocheck -F c -f ecocheck_backup.dump
```

### Restore
```bash
pg_restore -U ecocheck_user -d ecocheck -c ecocheck_backup.dump
```

## Troubleshooting

### Database won't start
```bash
# Check logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

### Migration errors
```bash
# Drop and recreate database
dropdb -U postgres ecocheck
createdb -U postgres ecocheck

# Re-run migrations
cd db
./run_migrations.sh
```

### Connection refused
- Ensure PostgreSQL is running
- Check firewall settings
- Verify connection details

## FIWARE Integration

The database schema is fully compatible with FIWARE NGSI-LD:
- All entities can be mapped to NGSI-LD format
- Spatial data uses GeoJSON-compatible format
- Metadata stored in JSONB columns
- Timestamps follow ISO 8601 format

## License

MIT License - Copyright (c) 2025 Lil5354

---

**Note**: This is a production-ready database implementation. The old mock data system has been replaced with a comprehensive PostgreSQL database that supports all project features and competition requirements.
