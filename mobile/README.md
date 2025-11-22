# EcoCheck Mobile Apps

## Cấu trúc thư mục

```
mobile/
├── frontend/
│   ├── nguoi-dan/      # App cho người dân (Citizen App)
│   └── nhan-vien/      # App cho nhân viên (Worker App)
└── README.md
```

## Database Setup

### 1. Khởi động PostgreSQL

```bash
# Từ thư mục gốc dự án
docker-compose up -d postgres
```

### 2. Chạy Migration

```bash
# Kết nối vào PostgreSQL
docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck

# Chạy migration
\i /path/to/db/migrations/001_init.sql
```

### 3. Import Seed Data

```bash
# Chạy seed data
docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck -f /path/to/db/seed_data.sql
```

## Database Schema

Xem chi tiết tại: `db/README.md`

### Các bảng chính:

**Master Data:**
- `depots` - Trạm thu gom
- `dumps` - Bãi rác / Trạm trung chuyển
- `vehicles` - Phương tiện
- `personnel` - Nhân sự

**User Data:**
- `users` - Người dùng
- `user_addresses` - Địa chỉ người dùng
- `points` - Điểm thu gom

**Operations:**
- `routes` - Tuyến đường
- `route_stops` - Điểm dừng trong tuyến
- `checkins` - Check-in rác
- `incidents` - Sự cố
- `exceptions` - Ngoại lệ

## Backend API Development

### Connection String

```env
DATABASE_URL=postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck
```

### Node.js Connection

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'ecocheck',
  user: 'ecocheck_user',
  password: 'ecocheck_pass'
});
```

### API Endpoints cần implement

#### Người dân (nguoi-dan)

**Authentication:**
- `POST /api/auth/register` - Đăng ký
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/verify-otp` - Xác thực OTP

**User Profile:**
- `GET /api/users/me` - Thông tin người dùng
- `PUT /api/users/me` - Cập nhật thông tin
- `GET /api/users/addresses` - Danh sách địa chỉ
- `POST /api/users/addresses` - Thêm địa chỉ

**Check-in:**
- `POST /api/checkins` - Tạo check-in
- `GET /api/checkins/history` - Lịch sử check-in

**Schedule:**
- `GET /api/schedules` - Lịch thu gom
- `POST /api/schedules` - Đặt lịch thu gom

**Incidents:**
- `POST /api/incidents` - Báo cáo sự cố
- `GET /api/incidents` - Danh sách sự cố

**Gamification:**
- `GET /api/gamification/stats` - Thống kê điểm
- `GET /api/gamification/badges` - Huy hiệu
- `GET /api/gamification/leaderboard` - Bảng xếp hạng

#### Nhân viên (nhan-vien)

**Authentication:**
- `POST /api/worker/auth/login` - Đăng nhập

**Routes:**
- `GET /api/worker/routes` - Danh sách tuyến
- `GET /api/worker/routes/:id` - Chi tiết tuyến
- `POST /api/worker/routes/:id/start` - Bắt đầu tuyến
- `POST /api/worker/routes/:id/complete` - Hoàn thành tuyến

**Route Stops:**
- `GET /api/worker/routes/:routeId/stops` - Điểm dừng
- `POST /api/worker/stops/:id/complete` - Hoàn thành điểm dừng
- `POST /api/worker/stops/:id/skip` - Bỏ qua điểm dừng

**Collections:**
- `POST /api/worker/collections` - Ghi nhận thu gom
- `GET /api/worker/collections/today` - Thu gom hôm nay
- `GET /api/worker/collections/stats` - Thống kê

**Exceptions:**
- `POST /api/worker/exceptions` - Báo cáo ngoại lệ
- `GET /api/worker/exceptions` - Danh sách ngoại lệ

**Location:**
- `POST /api/worker/location` - Cập nhật vị trí
- `GET /api/worker/location/history` - Lịch sử vị trí

## Các Query SQL hữu ích

### Lấy điểm thu gom gần nhất (trong bán kính 5km)

```sql
SELECT p.*, 
       ST_Distance(p.geom, ST_GeogFromText('POINT(106.6958 10.7769)')) as distance
FROM points p
WHERE ST_DWithin(p.geom, ST_GeogFromText('POINT(106.6958 10.7769)'), 5000)
ORDER BY distance
LIMIT 10;
```

### Lấy lịch sử check-in của user

```sql
SELECT c.*, p.*, ua.label as address_label
FROM checkins c
LEFT JOIN points p ON c.point_id = p.id
LEFT JOIN user_addresses ua ON p.address_id = ua.id
WHERE c.user_id = $1
ORDER BY c.created_at DESC
LIMIT 20;
```

### Thống kê thu gom theo ngày

```sql
SELECT 
  DATE(created_at) as date,
  waste_type,
  COUNT(*) as count,
  AVG(filling_level) as avg_level
FROM checkins
WHERE user_id = $1
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at), waste_type
ORDER BY date DESC;
```

## Tài liệu tham khảo

- Database Schema: `db/README.md`
- Seed Data: `db/seed_data.sql`
- Migration: `db/migrations/001_init.sql`

