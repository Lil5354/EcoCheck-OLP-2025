# EcoCheck Database Documentation

## Tổng quan

Database của EcoCheck được thiết kế để hỗ trợ hệ thống quản lý rác thải thông minh với 2 phần chính:
- **PostgreSQL + PostGIS**: Lưu trữ dữ liệu vận hành (operational data)
- **MongoDB**: Sử dụng bởi FIWARE Orion-LD Context Broker

## Cấu trúc Database (PostgreSQL)

### 1. Master Data (Dữ liệu chủ)

#### `depots` - Trạm thu gom
```sql
- id: uuid (Primary Key)
- name: text (Tên trạm)
- geom: geography(Point,4326) (Vị trí GPS)
- created_at: timestamptz
```

#### `dumps` - Bãi rác / Trạm trung chuyển
```sql
- id: uuid (Primary Key)
- name: text (Tên bãi rác)
- geom: geography(Point,4326) (Vị trí GPS)
- created_at: timestamptz
```

#### `vehicles` - Phương tiện
```sql
- id: text (Primary Key)
- plate: text (Biển số xe)
- type: text (Loại xe: compactor, mini-truck, electric-trike)
- capacity_kg: int (Sức chứa kg)
- accepted_types: text[] (Loại rác chấp nhận)
- status: text (Trạng thái: available, in_use, maintenance)
- depot_id: uuid (FK -> depots)
- created_at: timestamptz
```

#### `personnel` - Nhân sự
```sql
- id: uuid (Primary Key)
- name: text (Họ tên)
- role: text (Vai trò: driver, collector, manager, dispatcher)
- phone: text (Số điện thoại)
- status: text (Trạng thái: active, inactive)
- depot_id: uuid (FK -> depots)
- created_at: timestamptz
```

### 2. User Data (Dữ liệu người dùng)

#### `users` - Người dùng
```sql
- id: uuid (Primary Key)
- phone: text (Số điện thoại - unique)
- vneid: text (VNeID)
- role: text (Vai trò: citizen, worker, manager)
- status: text (Trạng thái: active, inactive)
- created_at: timestamptz
```

#### `user_addresses` - Địa chỉ người dùng
```sql
- id: uuid (Primary Key)
- user_id: uuid (FK -> users)
- label: text (Nhãn: Nhà, Công ty, etc.)
- geom: geography(Point,4326) (Vị trí GPS)
- is_default: boolean (Địa chỉ mặc định)
- created_at: timestamptz
```

#### `points` - Điểm thu gom
```sql
- id: uuid (Primary Key)
- address_id: uuid (FK -> user_addresses)
- geom: geography(Point,4326) (Vị trí GPS)
- ghost: boolean (Điểm ảo - không có địa chỉ cụ thể)
- last_waste_type: text (Loại rác lần cuối)
- last_level: numeric(3,2) (Mức độ đầy lần cuối: 0.00-1.00)
- last_checkin_at: timestamptz (Thời gian check-in cuối)
```

### 3. Operations (Vận hành)

#### `routes` - Tuyến đường
```sql
- id: uuid (Primary Key)
- vehicle_id: text (FK -> vehicles)
- depot_id: uuid (FK -> depots - điểm xuất phát)
- dump_id: uuid (FK -> dumps - điểm đổ rác)
- start_at: timestamptz (Thời gian bắt đầu)
- end_at: timestamptz (Thời gian kết thúc)
- status: text (Trạng thái: planned, in_progress, completed, cancelled)
- meta: jsonb (Metadata bổ sung)
```

#### `route_stops` - Điểm dừng trong tuyến
```sql
- id: uuid (Primary Key)
- route_id: uuid (FK -> routes)
- point_id: uuid (FK -> points)
- seq: int (Thứ tự điểm dừng)
- planned_eta: timestamptz (Thời gian dự kiến đến)
- status: text (Trạng thái: pending, completed, skipped)
- actual_at: timestamptz (Thời gian thực tế)
- reason: text (Lý do nếu bỏ qua)
```

#### `checkins` - Check-in rác
```sql
- id: uuid (Primary Key)
- user_id: uuid (FK -> users)
- point_id: uuid (FK -> points)
- waste_type: text (Loại rác: household, recyclable, bulky)
- filling_level: numeric(3,2) (Mức độ đầy: 0.00-1.00)
- geom: geography(Point,4326) (Vị trí GPS)
- photo_url: text (URL ảnh)
- source: text (Nguồn: mobile_app, worker_app)
- created_at: timestamptz
```

#### `incidents` - Sự cố
```sql
- id: uuid (Primary Key)
- reporter_id: uuid (FK -> users)
- type: text (Loại sự cố: overflow, illegal_dump, broken_bin)
- description: text (Mô tả)
- geom: geography(Point,4326) (Vị trí GPS)
- photo_url: text (URL ảnh)
- status: text (Trạng thái: open, in_progress, resolved)
- created_at: timestamptz
```

#### `exceptions` - Ngoại lệ
```sql
- id: uuid (Primary Key)
- route_id: uuid (FK -> routes)
- stop_id: uuid (FK -> route_stops)
- type: text (Loại ngoại lệ)
- reason: text (Lý do)
- photo_url: text (URL ảnh)
- status: text (Trạng thái: pending, approved, rejected)
- approved_by: uuid (Người phê duyệt)
- approved_at: timestamptz (Thời gian phê duyệt)
- plan: text (Kế hoạch xử lý)
- scheduled_at: timestamptz (Thời gian lên lịch)
- created_at: timestamptz
```


## Setup Database

### Bước 1: Khởi động Docker Compose

```bash
# Từ thư mục gốc dự án
docker-compose up -d postgres
```

Database sẽ được tạo tự động với thông tin:
- **Database**: `ecocheck`
- **User**: `ecocheck_user`
- **Password**: `ecocheck_pass`
- **Port**: `5432`

### Bước 2: Chạy Migration

```bash
# Kết nối vào PostgreSQL container
docker exec -it ecocheck-postgres psql -U ecocheck_user -d ecocheck

# Hoặc từ máy local (nếu đã cài PostgreSQL client)
psql -h localhost -p 5432 -U ecocheck_user -d ecocheck

# Chạy migration script
\i /path/to/db/migrations/001_init.sql
```

### Bước 3: Tạo dữ liệu mẫu (Seed Data)

Xem file `db/seed_data.sql` để có dữ liệu mẫu đầy đủ.

## Connection String cho Mobile Backend

### Node.js / Express
```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'ecocheck',
  user: 'ecocheck_user',
  password: 'ecocheck_pass'
});

// Hoặc sử dụng connection string
const connectionString = 'postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck';
```

### Environment Variables (.env)
```env
DATABASE_URL=postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck
DB_HOST=localhost
DB_PORT=5432
DB_NAME=ecocheck
DB_USER=ecocheck_user
DB_PASSWORD=ecocheck_pass
```

## API Endpoints cho Mobile App

### Người dân (nguoi-dan)

#### 1. Authentication
- `POST /api/auth/register` - Đăng ký tài khoản
- `POST /api/auth/login` - Đăng nhập
- `POST /api/auth/verify-otp` - Xác thực OTP

#### 2. User Profile
- `GET /api/users/me` - Lấy thông tin người dùng
- `PUT /api/users/me` - Cập nhật thông tin
- `GET /api/users/addresses` - Danh sách địa chỉ
- `POST /api/users/addresses` - Thêm địa chỉ mới
- `PUT /api/users/addresses/:id` - Cập nhật địa chỉ
- `DELETE /api/users/addresses/:id` - Xóa địa chỉ

#### 3. Check-in
- `POST /api/checkins` - Tạo check-in mới
- `GET /api/checkins/history` - Lịch sử check-in
- `GET /api/checkins/:id` - Chi tiết check-in

#### 4. Schedule
- `GET /api/schedules` - Lịch thu gom của người dùng
- `POST /api/schedules` - Đặt lịch thu gom
- `PUT /api/schedules/:id` - Cập nhật lịch
- `DELETE /api/schedules/:id` - Hủy lịch

#### 5. Incidents
- `POST /api/incidents` - Báo cáo sự cố
- `GET /api/incidents` - Danh sách sự cố
- `GET /api/incidents/:id` - Chi tiết sự cố

#### 6. Gamification
- `GET /api/gamification/stats` - Thống kê điểm
- `GET /api/gamification/badges` - Huy hiệu
- `GET /api/gamification/leaderboard` - Bảng xếp hạng

### Nhân viên (nhan-vien)

#### 1. Authentication
- `POST /api/worker/auth/login` - Đăng nhập
- `POST /api/worker/auth/logout` - Đăng xuất

#### 2. Routes
- `GET /api/worker/routes` - Danh sách tuyến đường
- `GET /api/worker/routes/:id` - Chi tiết tuyến
- `POST /api/worker/routes/:id/start` - Bắt đầu tuyến
- `POST /api/worker/routes/:id/complete` - Hoàn thành tuyến

#### 3. Route Stops
- `GET /api/worker/routes/:routeId/stops` - Điểm dừng
- `POST /api/worker/stops/:id/complete` - Hoàn thành điểm dừng
- `POST /api/worker/stops/:id/skip` - Bỏ qua điểm dừng

#### 4. Collections
- `POST /api/worker/collections` - Ghi nhận thu gom
- `GET /api/worker/collections/today` - Thu gom hôm nay
- `GET /api/worker/collections/stats` - Thống kê

#### 5. Exceptions
- `POST /api/worker/exceptions` - Báo cáo ngoại lệ
- `GET /api/worker/exceptions` - Danh sách ngoại lệ

#### 6. Location Tracking
- `POST /api/worker/location` - Cập nhật vị trí
- `GET /api/worker/location/history` - Lịch sử vị trí


