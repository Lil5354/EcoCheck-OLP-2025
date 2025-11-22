# EcoCheck Database Schema Documentation

## Entity Relationship Overview

### Master Data Domain
```
depots (Trạm thu gom)
├── vehicles (Phương tiện)
├── personnel (Nhân sự)
└── routes (Lộ trình)

dumps (Bãi rác)
└── routes (Lộ trình)
```

### User Domain
```
users (Người dùng)
├── user_addresses (Địa chỉ)
│   └── points (Điểm thu gom)
├── checkins (Check-in)
├── incidents (Sự cố)
├── user_points (Điểm tích lũy)
├── point_transactions (Giao dịch điểm)
├── user_badges (Huy hiệu)
└── user_bills (Hóa đơn)
```

### Operations Domain
```
routes (Lộ trình)
├── route_stops (Điểm dừng)
│   ├── points (Điểm thu gom)
│   └── exceptions (Ngoại lệ)
└── vehicle_tracking (Theo dõi xe)
```

## Detailed Table Specifications

### 1. Master Data Tables

#### depots
Collection stations and vehicle depots.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| name | text | NOT NULL | Depot name |
| geom | geography(Point,4326) | NOT NULL | GPS location |
| address | text | | Street address |
| capacity_vehicles | int | DEFAULT 10 | Max vehicle capacity |
| opening_hours | text | DEFAULT '18:00-06:00' | Operating hours |
| status | text | CHECK | active/inactive/maintenance |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update timestamp |

**Indexes:**
- GIST index on `geom` for spatial queries
- B-tree index on `status` (partial, WHERE status = 'active')

#### dumps
Waste disposal sites and transfer stations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| name | text | NOT NULL | Dump site name |
| geom | geography(Point,4326) | NOT NULL | GPS location |
| address | text | | Street address |
| accepted_waste_types | text[] | DEFAULT ARRAY[] | Accepted waste types |
| capacity_tons | numeric(10,2) | | Maximum capacity |
| opening_hours | text | DEFAULT '18:00-06:00' | Operating hours |
| status | text | CHECK | active/inactive/full |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update timestamp |

#### vehicles
Collection vehicles (trucks, trikes, specialized).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | text | PK | Vehicle ID (e.g., VH001) |
| plate | text | UNIQUE, NOT NULL | License plate |
| type | text | CHECK | compactor/mini-truck/electric-trike/specialized |
| capacity_kg | int | CHECK > 0 | Load capacity in kg |
| accepted_types | text[] | DEFAULT ARRAY[] | Accepted waste types |
| fuel_type | text | CHECK | diesel/electric/hybrid/cng |
| status | text | CHECK | available/in_use/maintenance/retired |
| depot_id | uuid | FK → depots | Home depot |
| current_load_kg | int | CHECK >= 0 | Current load |
| last_maintenance_at | timestamptz | | Last maintenance date |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update timestamp |

**Indexes:**
- B-tree on `depot_id`, `status`, `type`, `fuel_type`

#### personnel
Staff members (drivers, collectors, managers, dispatchers).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| name | text | NOT NULL | Full name |
| role | text | CHECK | driver/collector/manager/dispatcher/supervisor |
| phone | text | UNIQUE | Phone number |
| email | text | | Email address |
| certifications | text[] | DEFAULT '{}' | Certifications |
| status | text | CHECK | active/inactive/on_leave |
| depot_id | uuid | FK → depots | Assigned depot |
| hired_at | timestamptz | DEFAULT now() | Hire date |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update timestamp |

### 2. User Management Tables

#### users
All system users across roles.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| phone | text | UNIQUE | Phone number |
| email | text | UNIQUE | Email address |
| vneid | text | UNIQUE | VNeID identifier |
| password_hash | text | | Hashed password |
| role | text | CHECK | citizen/worker/manager/admin |
| status | text | CHECK | active/inactive/suspended/banned |
| profile | jsonb | DEFAULT '{}' | User profile data |
| created_at | timestamptz | DEFAULT now() | Registration date |
| updated_at | timestamptz | DEFAULT now() | Last update |
| last_login_at | timestamptz | | Last login timestamp |

**Indexes:**
- B-tree on `phone`, `email`, `role`, `status`

#### user_addresses
User registered addresses.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| user_id | uuid | FK → users, CASCADE | Owner user |
| label | text | | Address label (e.g., "Home") |
| address_text | text | | Full address text |
| geom | geography(Point,4326) | NOT NULL | GPS coordinates |

#### routes
Collection routes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| vehicle_id | text | FK → vehicles | Assigned vehicle |
| depot_id | uuid | FK → depots | Starting depot |
| dump_id | uuid | FK → dumps | Destination dump |
| driver_id | uuid | FK → personnel | Assigned driver |
| collector_id | uuid | FK → personnel | Assigned collector |
| start_at | timestamptz | | Planned start time |
| end_at | timestamptz | | Actual end time |
| planned_distance_km | numeric(10,2) | | Planned distance |
| actual_distance_km | numeric(10,2) | | Actual distance |
| planned_duration_min | int | | Planned duration |
| actual_duration_min | int | | Actual duration |
| status | text | CHECK | planned/in_progress/completed/cancelled |
| optimization_score | numeric(5,2) | | AI optimization score |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update |

**Indexes:**
- B-tree on `vehicle_id`, `depot_id`, `status`, `start_at`, `driver_id`, `collector_id`

#### route_stops
Stops within a route.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| route_id | uuid | FK → routes, CASCADE | Parent route |
| point_id | uuid | FK → points | Collection point |
| seq | int | CHECK >= 0 | Sequence number |
| planned_eta | timestamptz | | Planned arrival time |
| actual_arrival_at | timestamptz | | Actual arrival |
| actual_departure_at | timestamptz | | Actual departure |
| status | text | CHECK | pending/skipped/completed/failed |
| collected_waste_type | text | | Collected waste type |
| collected_weight_kg | numeric(10,2) | | Collected weight |
| reason | text | | Reason for skip/fail |
| photo_url | text | | Photo evidence |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update |

**Indexes:**
- UNIQUE on `(route_id, seq)`
- B-tree on `route_id`, `point_id`, `status`

#### incidents
Reported issues from citizens.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| reporter_id | uuid | FK → users | Reporting user |
| type | text | CHECK | overflow/illegal_dump/missed_collection/vehicle_issue/other |
| description | text | | Issue description |
| geom | geography(Point,4326) | | GPS location |
| photo_url | text | | Photo evidence |
| status | text | CHECK | open/in_progress/resolved/closed/rejected |
| priority | text | CHECK | low/medium/high/urgent |
| assigned_to | uuid | FK → personnel | Assigned staff |
| resolved_at | timestamptz | | Resolution timestamp |
| resolution_notes | text | | Resolution notes |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Report timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update |

**Indexes:**
- GIST on `geom`
- B-tree on `reporter_id`, `status`, `type`, `assigned_to`, `priority`, `created_at`

#### exceptions
Collection exceptions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| route_id | uuid | FK → routes, CASCADE | Related route |
| stop_id | uuid | FK → route_stops, CASCADE | Related stop |
| type | text | CHECK | cannot_collect/road_blocked/vehicle_breakdown/wrong_waste_type/other |
| reason | text | | Exception reason |
| photo_url | text | | Photo evidence |
| status | text | CHECK | pending/approved/rejected/resolved |
| approved_by | uuid | FK → users | Approving user |
| approved_at | timestamptz | | Approval timestamp |
| plan | text | | Resolution plan |
| scheduled_at | timestamptz | | Rescheduled time |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Report timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update |

**Indexes:**
- B-tree on `route_id`, `stop_id`, `status`, `created_at`

### 4. Gamification Tables

#### user_points
User point balances and levels.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| user_id | uuid | FK → users, CASCADE, UNIQUE | User |
| points | int | CHECK >= 0 | Current points |
| level | int | CHECK >= 1 | Current level |
| total_checkins | int | DEFAULT 0 | Total check-ins |
| total_recyclable | int | DEFAULT 0 | Recyclable check-ins |
| total_bulky | int | DEFAULT 0 | Bulky check-ins |
| streak_days | int | DEFAULT 0 | Consecutive days |
| last_checkin_date | date | | Last check-in date |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update |

**Indexes:**
- B-tree on `user_id`, `points DESC`, `level DESC`

#### point_transactions
Point transaction history (TimescaleDB hypertable).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| user_id | uuid | FK → users, CASCADE | User |
| points | int | NOT NULL | Points amount (+/-) |
| type | text | CHECK | earn/spend/bonus/penalty/adjustment |
| reason | text | NOT NULL | Transaction reason |
| reference_id | uuid | | Related entity ID |
| reference_type | text | | Related entity type |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Transaction timestamp |

**Indexes:**
- B-tree on `user_id`, `type`, `created_at DESC`
- Time-series partitioning on `created_at`

#### badges
Available badges.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| code | text | UNIQUE, NOT NULL | Badge code |
| name | text | NOT NULL | Badge name |
| description | text | | Badge description |
| icon_url | text | | Icon URL |
| criteria | jsonb | NOT NULL | Earning criteria |
| points_reward | int | DEFAULT 0 | Bonus points |
| rarity | text | CHECK | common/rare/epic/legendary |
| active | boolean | DEFAULT true | Is active |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |

**Indexes:**
- B-tree on `code`
- Partial on `active` WHERE active = true

#### user_badges
Badges earned by users.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| user_id | uuid | FK → users, CASCADE | User |
| badge_id | uuid | FK → badges, CASCADE | Badge |
| earned_at | timestamptz | DEFAULT now() | Earned timestamp |

**Constraints:**
- UNIQUE on `(user_id, badge_id)`

**Indexes:**
- B-tree on `user_id`, `badge_id`, `earned_at DESC`

### 5. Billing Tables (PAYT)

#### billing_cycles
Monthly billing periods.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| name | text | NOT NULL | Cycle name |
| start_date | date | NOT NULL | Start date |
| end_date | date | NOT NULL | End date |
| status | text | CHECK | active/closed/cancelled |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |

**Constraints:**
- UNIQUE on `(start_date, end_date)`

**Indexes:**
- B-tree on `(start_date, end_date)`, `status`

#### user_bills
User bills per cycle.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| user_id | uuid | FK → users, CASCADE | User |
| billing_cycle_id | uuid | FK → billing_cycles, CASCADE | Billing cycle |
| total_checkins | int | DEFAULT 0 | Total check-ins |
| total_weight_estimated_kg | numeric(10,2) | DEFAULT 0 | Estimated weight |
| base_fee | numeric(10,2) | DEFAULT 0 | Base fee |
| variable_fee | numeric(10,2) | DEFAULT 0 | Variable fee (PAYT) |
| discount | numeric(10,2) | DEFAULT 0 | Discount amount |
| total_amount | numeric(10,2) | NOT NULL | Total amount |
| status | text | CHECK | pending/paid/overdue/cancelled |
| due_date | date | | Payment due date |
| paid_at | timestamptz | | Payment timestamp |
| payment_method | text | | Payment method |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update |

**Constraints:**
- UNIQUE on `(user_id, billing_cycle_id)`

**Indexes:**
- B-tree on `user_id`, `billing_cycle_id`, `status`, `due_date`

### 6. Analytics Tables

#### vehicle_tracking
Real-time vehicle GPS tracking (TimescaleDB hypertable).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| vehicle_id | text | FK → vehicles, CASCADE | Vehicle |
| route_id | uuid | FK → routes | Current route |
| geom | geography(Point,4326) | NOT NULL | GPS location |
| speed_kmh | numeric(5,2) | | Speed in km/h |
| heading | numeric(5,2) | | Heading in degrees |
| accuracy_m | numeric(10,2) | | GPS accuracy |
| battery_level | int | | Battery level (%) |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| recorded_at | timestamptz | DEFAULT now() | Recording timestamp |

**Indexes:**
- GIST on `geom`
- B-tree on `vehicle_id`, `route_id`, `recorded_at DESC`
- Time-series partitioning on `recorded_at`

#### system_logs
System activity logs (TimescaleDB hypertable).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| level | text | CHECK | debug/info/warning/error/critical |
| category | text | NOT NULL | Log category |
| message | text | NOT NULL | Log message |
| user_id | uuid | FK → users | Related user |
| entity_type | text | | Related entity type |
| entity_id | uuid | | Related entity ID |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Log timestamp |

**Indexes:**
- B-tree on `level`, `category`, `user_id`, `created_at DESC`
- Time-series partitioning on `created_at`

## Data Types Reference

### Waste Types
- `household`: Regular household waste
- `recyclable`: Recyclable materials
- `bulky`: Bulky items (furniture, appliances)
- `hazardous`: Hazardous waste
- `organic`: Organic/compostable waste

### User Roles
- `citizen`: Regular citizen user
- `worker`: Collection worker
- `manager`: System manager
- `admin`: System administrator

### Vehicle Types
- `compactor`: Garbage compactor truck
- `mini-truck`: Small collection truck
- `electric-trike`: Electric tricycle
- `specialized`: Specialized vehicle

### Status Values
Various status enums are used throughout:
- **General**: active, inactive
- **Routes**: planned, in_progress, completed, cancelled
- **Stops**: pending, skipped, completed, failed
- **Incidents**: open, in_progress, resolved, closed, rejected
- **Bills**: pending, paid, overdue, cancelled

## Performance Considerations

### Spatial Queries
All geographic columns use PostGIS `geography(Point,4326)` with GIST indexes for efficient spatial operations.

### Time-Series Data
High-volume time-series tables use TimescaleDB hypertables:
- `checkins`: Partitioned by `created_at`
- `point_transactions`: Partitioned by `created_at`
- `vehicle_tracking`: Partitioned by `recorded_at`
- `system_logs`: Partitioned by `created_at`

### Automatic Maintenance
- Triggers update `updated_at` timestamps automatically
- Triggers maintain denormalized statistics (point totals, user points)
- Constraints ensure data integrity

## NGSI-LD Compliance

The schema is designed to support FIWARE NGSI-LD standards:
- All entities can be mapped to NGSI-LD format
- Spatial data uses GeoJSON-compatible format
- Metadata stored in `meta` JSONB columns
- Timestamps follow ISO 8601 format

**Indexes:**
- GIST on `geom`
- B-tree on `user_id`
- Partial on `(user_id, is_default)` WHERE is_default = true

#### points
Collection points (registered or ghost).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| address_id | uuid | FK → user_addresses | Linked address (NULL for ghost) |
| geom | geography(Point,4326) | NOT NULL | GPS location |
| ghost | boolean | DEFAULT false | Is ghost point |
| last_waste_type | text | | Last reported waste type |
| last_level | numeric(3,2) | CHECK 0-1 | Last filling level |
| last_checkin_at | timestamptz | | Last check-in time |
| total_checkins | int | DEFAULT 0 | Total check-ins |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Creation timestamp |
| updated_at | timestamptz | DEFAULT now() | Last update |

**Indexes:**
- GIST on `geom`
- B-tree on `ghost`, `address_id`, `last_checkin_at`

### 3. Operations Tables

#### checkins
Waste check-ins from citizens (TimescaleDB hypertable).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | uuid | PK | Unique identifier |
| user_id | uuid | FK → users | Check-in user |
| point_id | uuid | FK → points | Collection point |
| waste_type | text | CHECK | household/recyclable/bulky/hazardous/organic |
| filling_level | numeric(3,2) | CHECK 0-1 | Estimated filling level |
| geom | geography(Point,4326) | NOT NULL | GPS location |
| photo_url | text | | Photo evidence URL |
| source | text | CHECK | mobile_app/web/api/system |
| verified | boolean | DEFAULT false | Verified by worker |
| verified_at | timestamptz | | Verification timestamp |
| verified_by | uuid | FK → users | Verifying user |
| meta | jsonb | DEFAULT '{}' | Additional metadata |
| created_at | timestamptz | DEFAULT now() | Check-in timestamp |

**Indexes:**
- GIST on `geom`
- B-tree on `user_id`, `point_id`, `waste_type`, `verified`
- Time-series partitioning on `created_at`

**Triggers:**
- `update_point_on_checkin`: Updates point statistics
- `award_points_on_checkin`: Awards gamification points


