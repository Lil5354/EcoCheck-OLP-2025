# EcoCheck Database Query Reference

## Common Queries

### 1. Spatial Queries

#### Find collection points within radius
```sql
-- Find all points within 1km of a location
SELECT
    p.id,
    p.last_waste_type,
    p.last_level,
    ST_Distance(p.geom, ST_GeogFromText('POINT(106.6958 10.7769)')) as distance_m
FROM points p
WHERE ST_DWithin(
    p.geom,
    ST_GeogFromText('POINT(106.6958 10.7769)'),
    1000  -- 1000 meters
)
ORDER BY distance_m;
```

#### Find nearest depot to a location
```sql
SELECT
    d.id,
    d.name,
    d.address,
    ST_Distance(d.geom, ST_GeogFromText('POINT(106.6958 10.7769)')) as distance_m
FROM depots d
WHERE d.status = 'active'
ORDER BY distance_m
LIMIT 1;
```

#### Get points in a bounding box
```sql
SELECT *
FROM points
WHERE ST_Intersects(
    geom,
    ST_MakeEnvelope(106.65, 10.75, 106.75, 10.85, 4326)::geography
);
```

### 2. User & Gamification Queries

#### Get user leaderboard
```sql
SELECT
    u.id,
    u.profile->>'name' as name,
    up.points,
    up.level,
    up.total_checkins,
    up.streak_days,
    RANK() OVER (ORDER BY up.points DESC) as rank
FROM user_points up
JOIN users u ON u.id = up.user_id
WHERE u.status = 'active'
ORDER BY up.points DESC
LIMIT 100;
```

#### Get user badges
```sql
SELECT
    u.profile->>'name' as user_name,
    b.name as badge_name,
    b.description,
    b.rarity,
    ub.earned_at
FROM user_badges ub
JOIN users u ON u.id = ub.user_id
JOIN badges b ON b.id = ub.badge_id
WHERE u.id = 'USER_ID_HERE'
ORDER BY ub.earned_at DESC;
```

#### Get point transaction history
```sql
SELECT
    pt.points,
    pt.type,
    pt.reason,
    pt.created_at
FROM point_transactions pt
WHERE pt.user_id = 'USER_ID_HERE'
ORDER BY pt.created_at DESC
LIMIT 50;
```

### 3. Check-in Queries

#### Get recent check-ins with user info
```sql
SELECT
    c.id,
    u.profile->>'name' as user_name,
    c.waste_type,
    c.filling_level,
    c.verified,
    c.created_at,
    ST_AsGeoJSON(c.geom) as location
FROM checkins c
JOIN users u ON u.id = c.user_id
WHERE c.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY c.created_at DESC;
```

#### Get check-in statistics by waste type
```sql
SELECT
    waste_type,
    COUNT(*) as total_checkins,
    AVG(filling_level) as avg_level,
    COUNT(DISTINCT user_id) as unique_users
FROM checkins
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY waste_type
ORDER BY total_checkins DESC;
```

#### Get unverified check-ins
```sql
SELECT
    c.id,
    u.profile->>'name' as user_name,
    u.phone,
    c.waste_type,
    c.filling_level,
    c.created_at,
    ST_AsGeoJSON(c.geom) as location
FROM checkins c
JOIN users u ON u.id = c.user_id
WHERE c.verified = false
ORDER BY c.created_at DESC;
```

### 4. Route & Operations Queries

#### Get active routes with vehicle info
```sql
SELECT
    r.id,
    v.plate as vehicle_plate,
    v.type as vehicle_type,
    p1.name as driver_name,
    p2.name as collector_name,

### 7. Analytics Queries

#### Get vehicle tracking history
```sql
SELECT
    vt.vehicle_id,
    v.plate,
    vt.speed_kmh,
    vt.heading,
    vt.battery_level,
    vt.recorded_at,
    ST_AsGeoJSON(vt.geom) as location
FROM vehicle_tracking vt
JOIN vehicles v ON v.id = vt.vehicle_id
WHERE vt.vehicle_id = 'VEHICLE_ID_HERE'
    AND vt.recorded_at >= NOW() - INTERVAL '1 hour'
ORDER BY vt.recorded_at DESC;
```

#### Get collection statistics by district
```sql
WITH district_stats AS (
    SELECT
        CASE
            WHEN ST_Distance(c.geom, ST_GeogFromText('POINT(106.6958 10.7769)')) < 2000 THEN 'Quận 1'
            WHEN ST_Distance(c.geom, ST_GeogFromText('POINT(106.6830 10.7830)')) < 2000 THEN 'Quận 3'
            WHEN ST_Distance(c.geom, ST_GeogFromText('POINT(106.7054 10.8014)')) < 2000 THEN 'Bình Thạnh'
            ELSE 'Other'
        END as district,
        c.waste_type,
        COUNT(*) as checkin_count,
        AVG(c.filling_level) as avg_level
    FROM checkins c
    WHERE c.created_at >= NOW() - INTERVAL '7 days'
    GROUP BY district, c.waste_type
)
SELECT * FROM district_stats
ORDER BY district, checkin_count DESC;
```

#### Get daily check-in trends
```sql
SELECT
    DATE(created_at) as date,
    waste_type,
    COUNT(*) as total_checkins,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(filling_level) as avg_level
FROM checkins
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at), waste_type
ORDER BY date DESC, total_checkins DESC;
```

#### Get vehicle utilization
```sql
SELECT
    v.id,
    v.plate,
    v.type,
    COUNT(DISTINCT r.id) as total_routes,
    SUM(r.actual_distance_km) as total_distance_km,
    AVG(r.optimization_score) as avg_optimization_score,
    SUM(EXTRACT(EPOCH FROM (r.end_at - r.start_at))/3600) as total_hours
FROM vehicles v
LEFT JOIN routes r ON r.vehicle_id = v.id
    AND r.status = 'completed'
    AND r.created_at >= NOW() - INTERVAL '30 days'
WHERE v.status != 'retired'
GROUP BY v.id, v.plate, v.type
ORDER BY total_routes DESC;
```

### 8. Performance Monitoring Queries

#### Get table sizes
```sql
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### Get index usage statistics
```sql
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

#### Get slow queries (requires pg_stat_statements extension)
```sql
SELECT
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    stddev_exec_time
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 20;
```

### 9. Data Integrity Checks

#### Find orphaned points (no address, not ghost)
```sql
SELECT *
FROM points
WHERE address_id IS NULL
    AND ghost = false;
```

#### Find users with no addresses
```sql
SELECT u.id, u.phone, u.profile->>'name' as name
FROM users u
LEFT JOIN user_addresses ua ON ua.user_id = u.id
WHERE u.role = 'citizen'
    AND u.status = 'active'
    AND ua.id IS NULL;
```

#### Find routes with no stops
```sql
SELECT r.id, r.vehicle_id, r.status, r.start_at
FROM routes r
LEFT JOIN route_stops rs ON rs.route_id = r.id
WHERE rs.id IS NULL
    AND r.status != 'cancelled';
```

#### Find check-ins far from registered points
```sql
SELECT
    c.id,
    c.user_id,
    ST_Distance(c.geom, p.geom) as distance_m
FROM checkins c
JOIN points p ON p.id = c.point_id
WHERE ST_Distance(c.geom, p.geom) > 100  -- More than 100m away
ORDER BY distance_m DESC;
```

### 10. Maintenance Queries

#### Vacuum and analyze all tables
```sql
VACUUM ANALYZE;
```

#### Reindex specific table
```sql
REINDEX TABLE checkins;
```

#### Update statistics
```sql
ANALYZE checkins;
ANALYZE points;
ANALYZE routes;
```

#### Check for missing indexes on foreign keys
```sql
SELECT
    c.conrelid::regclass AS table_name,
    a.attname AS column_name,
    c.confrelid::regclass AS referenced_table
FROM pg_constraint c
JOIN pg_attribute a ON a.attnum = ANY(c.conkey) AND a.attrelid = c.conrelid
WHERE c.contype = 'f'
    AND NOT EXISTS (
        SELECT 1 FROM pg_index i
        WHERE i.indrelid = c.conrelid
            AND a.attnum = ANY(i.indkey)
    );
```

## Useful Functions

### Calculate distance between two points
```sql
SELECT ST_Distance(
    ST_GeogFromText('POINT(106.6958 10.7769)'),
    ST_GeogFromText('POINT(106.7000 10.7800)')
) as distance_meters;
```

### Convert geometry to GeoJSON
```sql
SELECT ST_AsGeoJSON(geom) FROM points LIMIT 1;
```

### Get point from coordinates
```sql
SELECT ST_GeogFromText('POINT(106.6958 10.7769)');
```

### Calculate bounding box
```sql
SELECT ST_Extent(geom::geometry) FROM points;
```

## TimescaleDB Specific Queries

### Get hypertable information
```sql
SELECT * FROM timescaledb_information.hypertables;
```

### Get chunk information
```sql
SELECT * FROM timescaledb_information.chunks
WHERE hypertable_name = 'checkins';
```

### Compress old data
```sql
SELECT compress_chunk(i)
FROM show_chunks('checkins', older_than => INTERVAL '90 days') i;
```

### Get compression statistics
```sql
SELECT
    hypertable_name,
    pg_size_pretty(before_compression_total_bytes) as before_compression,
    pg_size_pretty(after_compression_total_bytes) as after_compression,
    ROUND(100.0 * (before_compression_total_bytes - after_compression_total_bytes) / before_compression_total_bytes, 2) as compression_ratio
FROM timescaledb_information.compression_settings;
```

## Best Practices

1. **Always use spatial indexes** for geographic queries
2. **Use EXPLAIN ANALYZE** to understand query performance
3. **Batch insert operations** for better performance
4. **Use prepared statements** to prevent SQL injection
5. **Regularly vacuum and analyze** tables
6. **Monitor slow queries** and optimize them
7. **Use appropriate data types** (e.g., geography for coordinates)
8. **Create indexes** on frequently queried columns
9. **Use TimescaleDB features** for time-series data
10. **Keep statistics up to date** with ANALYZE
FROM routes r
JOIN vehicles v ON v.id = r.vehicle_id
LEFT JOIN personnel p1 ON p1.id = r.driver_id
LEFT JOIN personnel p2 ON p2.id = r.collector_id
LEFT JOIN route_stops rs ON rs.route_id = r.id
WHERE r.status IN ('planned', 'in_progress')
GROUP BY r.id, v.plate, v.type, p1.name, p2.name
ORDER BY r.start_at;
```

#### Get route efficiency metrics
```sql
SELECT
    r.id,
    r.planned_distance_km,
    r.actual_distance_km,
    r.planned_duration_min,
    r.actual_duration_min,
    r.optimization_score,
    ROUND(100.0 * r.actual_distance_km / NULLIF(r.planned_distance_km, 0), 2) as distance_efficiency_pct,
    ROUND(100.0 * r.actual_duration_min / NULLIF(r.planned_duration_min, 0), 2) as time_efficiency_pct
FROM routes r
WHERE r.status = 'completed'
    AND r.created_at >= NOW() - INTERVAL '7 days'
ORDER BY r.optimization_score DESC;
```

#### Get route stops with ETA
```sql
SELECT
    rs.seq,
    p.last_waste_type,
    p.last_level,
    rs.planned_eta,
    rs.actual_arrival_at,
    rs.status,
    ST_AsGeoJSON(p.geom) as location
FROM route_stops rs
JOIN points p ON p.id = rs.point_id
WHERE rs.route_id = 'ROUTE_ID_HERE'
ORDER BY rs.seq;
```

### 5. Incident Queries

#### Get open incidents by priority
```sql
SELECT
    i.id,
    i.type,
    i.description,
    i.priority,
    u.profile->>'name' as reporter_name,
    u.phone as reporter_phone,
    i.created_at,
    ST_AsGeoJSON(i.geom) as location
FROM incidents i
JOIN users u ON u.id = i.reporter_id
WHERE i.status = 'open'
ORDER BY
    CASE i.priority
        WHEN 'urgent' THEN 1
        WHEN 'high' THEN 2
        WHEN 'medium' THEN 3
        WHEN 'low' THEN 4
    END,
    i.created_at;
```

#### Get incident resolution statistics
```sql
SELECT
    type,
    COUNT(*) as total,
    AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) as avg_resolution_hours,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved_count,
    COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_count
FROM incidents
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY type
ORDER BY total DESC;
```

### 6. Billing Queries

#### Get user bill summary
```sql
SELECT
    u.profile->>'name' as user_name,
    u.phone,
    bc.name as billing_cycle,
    ub.total_checkins,
    ub.total_weight_estimated_kg,
    ub.base_fee,
    ub.variable_fee,
    ub.discount,
    ub.total_amount,
    ub.status,
    ub.due_date
FROM user_bills ub
JOIN users u ON u.id = ub.user_id
JOIN billing_cycles bc ON bc.id = ub.billing_cycle_id
WHERE ub.user_id = 'USER_ID_HERE'
ORDER BY bc.start_date DESC;
```

#### Get unpaid bills
```sql
SELECT
    u.profile->>'name' as user_name,
    u.phone,
    u.email,
    bc.name as billing_cycle,
    ub.total_amount,
    ub.due_date,
    CASE
        WHEN ub.due_date < CURRENT_DATE THEN 'overdue'
        ELSE 'pending'
    END as payment_status
FROM user_bills ub
JOIN users u ON u.id = ub.user_id
JOIN billing_cycles bc ON bc.id = ub.billing_cycle_id
WHERE ub.status IN ('pending', 'overdue')
ORDER BY ub.due_date;
```


