# EcoCheck Database Documentation

## Overview

The EcoCheck database is built on **PostgreSQL 15** with **PostGIS** for spatial data and **TimescaleDB** for time-series optimization. It follows FIWARE NGSI-LD standards and implements a comprehensive schema for dynamic waste collection management.

## Architecture

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

## Database Schema

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

#### Operations
- **checkins**: Waste check-ins from citizens
- **routes**: Collection routes
- **route_stops**: Stops within routes
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

## Migration Files

Execute migrations in order:

1. **001_init.sql**: Base schema creation
2. **002_comprehensive_schema.sql**: Enhanced schema with all features
3. **003_seed_badges.sql**: Gamification badges
4. **004_enhanced_seed_data.sql**: Master data and users
5. **005_seed_addresses_points.sql**: Addresses and collection points
6. **006_seed_checkins_operations.sql**: Check-ins and incidents
7. **007_seed_routes_billing.sql**: Routes and billing data

## Setup Instructions

### Using Docker Compose

```bash
# Start the database
docker-compose up -d postgres

# Wait for database to be ready
docker-compose exec postgres pg_isready -U ecocheck_user -d ecocheck

# Run migrations
docker-compose exec postgres psql -U ecocheck_user -d ecocheck -f /docker-entrypoint-initdb.d/001_init.sql
docker-compose exec postgres psql -U ecocheck_user -d ecocheck -f /docker-entrypoint-initdb.d/002_comprehensive_schema.sql
# ... continue with other migrations
```

### Manual Setup

```bash
# Create database
createdb -U postgres ecocheck

# Run migrations in order
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
- **Host**: localhost
- **Port**: 5432
- **Database**: ecocheck
- **User**: ecocheck_user
- **Password**: ecocheck_pass

### Connection String
```
postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck
```

## Key Features Implementation

### 1. Spatial Queries
All geographic data uses PostGIS `geography(Point,4326)` type with GIST indexes for efficient spatial queries.

```sql
-- Find points within 1km radius
SELECT * FROM points 
WHERE ST_DWithin(geom, ST_GeogFromText('POINT(106.6958 10.7769)'), 1000);
```

### 2. Time-Series Optimization
TimescaleDB hypertables for high-volume time-series data:
- `checkins`: Partitioned by `created_at`
- `point_transactions`: Partitioned by `created_at`
- `vehicle_tracking`: Partitioned by `recorded_at`
- `system_logs`: Partitioned by `created_at`

### 3. Automatic Triggers

#### Updated At Trigger
Automatically updates `updated_at` timestamp on row modification.

#### Check-in Triggers
- **update_point_on_checkin**: Updates point statistics
- **award_points_on_checkin**: Awards gamification points to users

### 4. Gamification System

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

### 5. PAYT Billing

Billing formula:
```
Total = Base Fee + Variable Fee - Discount
Variable Fee = Total Weight (kg) × Rate per kg
```

## Data Integrity

### Constraints
- Foreign key constraints for referential integrity
- Check constraints for valid enum values
- Unique constraints for preventing duplicates
- NOT NULL constraints for required fields

### Indexes
- Primary key indexes (B-tree)
- Foreign key indexes for join optimization
- Spatial indexes (GIST) for geographic queries
- Partial indexes for filtered queries
- Composite indexes for common query patterns

## Backup and Restore

### Backup
```bash
pg_dump -U ecocheck_user -d ecocheck -F c -f ecocheck_backup.dump
```

### Restore
```bash
pg_restore -U ecocheck_user -d ecocheck -c ecocheck_backup.dump
```

## Performance Tuning

### Recommended PostgreSQL Settings
```
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
```

### TimescaleDB Settings
```
timescaledb.max_background_workers = 8
```

## License

MIT License - Copyright (c) 2025 Lil5354

