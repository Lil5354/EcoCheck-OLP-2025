# EcoCheck Database Entity Relationship Diagram

## Core Relationships

```mermaid
erDiagram
    %% Master Data Domain
    depots ||--o{ vehicles : "houses"
    depots ||--o{ personnel : "employs"
    depots ||--o{ routes : "starts_from"
    dumps ||--o{ routes : "ends_at"
    
    %% User Domain
    users ||--o{ user_addresses : "has"
    user_addresses ||--o{ points : "creates"
    users ||--o{ checkins : "performs"
    users ||--o{ incidents : "reports"
    users ||--o{ user_points : "earns"
    users ||--o{ point_transactions : "has"
    users ||--o{ user_badges : "earns"
    users ||--o{ user_bills : "receives"
    
    %% Operations Domain
    vehicles ||--o{ routes : "assigned_to"
    personnel ||--o{ routes : "drives"
    personnel ||--o{ routes : "collects"
    routes ||--o{ route_stops : "contains"
    routes ||--o{ exceptions : "has"
    routes ||--o{ vehicle_tracking : "tracks"
    points ||--o{ route_stops : "visited_at"
    points ||--o{ checkins : "located_at"
    route_stops ||--o{ exceptions : "causes"
    
    %% Gamification Domain
    badges ||--o{ user_badges : "awarded_as"
    
    %% Billing Domain
    billing_cycles ||--o{ user_bills : "generates"
    
    %% Entity Definitions
    depots {
        uuid id PK
        text name
        geography geom
        text address
        int capacity_vehicles
        text opening_hours
        text status
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
    
    dumps {
        uuid id PK
        text name
        geography geom
        text address
        text_array accepted_waste_types
        numeric capacity_tons
        text opening_hours
        text status
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
    
    vehicles {
        text id PK
        text plate UK
        text type
        int capacity_kg
        text_array accepted_types
        text fuel_type
        text status
        uuid depot_id FK
        int current_load_kg
        timestamptz last_maintenance_at
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
    
    personnel {
        uuid id PK
        text name
        text role
        text phone UK
        text email
        text_array certifications
        text status
        uuid depot_id FK
        timestamptz hired_at
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
    
    users {
        uuid id PK
        text phone UK
        text email UK
        text vneid UK
        text password_hash
        text role
        text status
        jsonb profile
        timestamptz created_at
        timestamptz updated_at
        timestamptz last_login_at
    }
    
    user_addresses {
        uuid id PK
        uuid user_id FK
        text label
        text address_text
        geography geom
        boolean is_default
        boolean verified
        timestamptz created_at
        timestamptz updated_at
    }
    
    points {
        uuid id PK
        uuid address_id FK
        geography geom
        boolean ghost
        text last_waste_type
        numeric last_level
        timestamptz last_checkin_at
        int total_checkins
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
    
    checkins {
        uuid id PK
        uuid user_id FK
        uuid point_id FK
        text waste_type
        numeric filling_level
        geography geom
        text photo_url
        text source
        boolean verified
        timestamptz verified_at
        uuid verified_by FK
        jsonb meta
        timestamptz created_at
    }
    
    routes {
        uuid id PK
        text vehicle_id FK
        uuid depot_id FK
        uuid dump_id FK
        uuid driver_id FK
        uuid collector_id FK
        timestamptz start_at
        timestamptz end_at
        numeric planned_distance_km
        numeric actual_distance_km
        int planned_duration_min
        int actual_duration_min
        text status
        numeric optimization_score
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
    
    route_stops {
        uuid id PK
        uuid route_id FK
        uuid point_id FK
        int seq
        timestamptz planned_eta
        timestamptz actual_arrival_at
        timestamptz actual_departure_at
        text status
        text collected_waste_type
        numeric collected_weight_kg
        text reason
        text photo_url
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
```

## Gamification & Billing

```mermaid
erDiagram
    users ||--o{ user_points : "has"
    users ||--o{ point_transactions : "performs"
    users ||--o{ user_badges : "earns"
    badges ||--o{ user_badges : "awarded_as"
    billing_cycles ||--o{ user_bills : "generates"
    users ||--o{ user_bills : "receives"
    
    user_points {
        uuid id PK
        uuid user_id FK_UK
        int points
        int level
        int total_checkins
        int total_recyclable
        int total_bulky
        int streak_days
        date last_checkin_date
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
    
    point_transactions {
        uuid id PK
        uuid user_id FK
        int points
        text type
        text reason
        uuid reference_id
        text reference_type
        jsonb meta
        timestamptz created_at
    }
    
    badges {
        uuid id PK
        text code UK
        text name
        text description
        text icon_url
        jsonb criteria
        int points_reward
        text rarity
        boolean active
        timestamptz created_at
    }
    
    user_badges {
        uuid id PK
        uuid user_id FK
        uuid badge_id FK
        timestamptz earned_at
    }
    
    billing_cycles {
        uuid id PK
        text name
        date start_date
        date end_date
        text status
        timestamptz created_at
    }
    
    user_bills {
        uuid id PK
        uuid user_id FK
        uuid billing_cycle_id FK
        int total_checkins
        numeric total_weight_estimated_kg
        numeric base_fee
        numeric variable_fee
        numeric discount
        numeric total_amount
        text status
        date due_date
        timestamptz paid_at
        text payment_method
        jsonb meta
        timestamptz created_at
        timestamptz updated_at
    }
```

## Legend

- **PK**: Primary Key
- **FK**: Foreign Key
- **UK**: Unique Key
- **||--o{**: One-to-Many relationship
- **geography**: PostGIS geography(Point,4326) type
- **jsonb**: JSON binary type for flexible metadata
- **text_array**: PostgreSQL text array type

