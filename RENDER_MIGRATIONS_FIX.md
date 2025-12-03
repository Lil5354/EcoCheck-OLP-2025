# Hướng dẫn Fix Migrations trên Render

## Vấn đề
Lỗi: `relation "vehicles" does not exist` - Migrations chưa chạy hoặc chạy thất bại.

## Đã Fix
1. ✅ Cải thiện entrypoint.sh với logging chi tiết
2. ✅ Verify migration files tồn tại trước khi chạy
3. ✅ Better error handling

## Cách 1: Redeploy và Kiểm tra Logs (Khuyến nghị)

### Bước 1: Redeploy Service
1. Vào service `EcoCheck-OLP-2025` trong Render
2. Tab "Events" hoặc "Manual Deploy"
3. Click "Clear build cache & deploy"
4. Đợi deploy xong (~5-10 phút)

### Bước 2: Kiểm tra Logs
1. Vào tab "Logs"
2. Tìm các dòng sau khi service start:

**Nếu thành công:**
```
Checking for migration script...
✓ Migration script found at /app/db/run_migrations.sh
Running database migrations...
Found X migration file(s) in /app/db/migrations
✓ Migrations completed successfully!
```

**Nếu thất bại:**
```
⚠ WARNING: Migration script not found at /app/db/run_migrations.sh
```
Hoặc
```
⚠ WARNING: Migration script exited with code: X
```

---

## Cách 2: Chạy Migrations Thủ Công qua Render Shell

Nếu migrations không chạy tự động:

### Bước 1: Mở Shell
1. Vào service `EcoCheck-OLP-2025`
2. Tab "Shell" (sidebar trái, icon terminal)
3. Click "Connect" để mở shell

### Bước 2: Chạy Migrations
Trong shell, chạy các lệnh sau:

```bash
# Check if migrations directory exists
ls -la /app/db
ls -la /app/db/migrations

# Check environment variables
echo "DB_HOST: $DB_HOST"
echo "DB_NAME: $DB_NAME"
echo "DB_USER: $DB_USER"

# Run migrations
cd /app/db
export PGPASSWORD=$DB_PASSWORD
bash ./run_migrations.sh
```

### Bước 3: Kiểm tra Kết Quả
Sau khi chạy, bạn sẽ thấy:
```
✓ Database connection successful
✓ All migrations completed successfully!
```

---

## Cách 3: Thêm Pre-Deploy Command (Backup)

Nếu entrypoint không chạy migrations:

### Bước 1: Vào Settings
1. Vào service `EcoCheck-OLP-2025`
2. Tab "Settings" → Right sidebar → "Build & Deploy"

### Bước 2: Thêm Pre-Deploy Command
1. Scroll xuống phần "Pre-Deploy Command"
2. Click "Edit"
3. Thêm command:
```bash
cd /app/db && export PGPASSWORD=$DB_PASSWORD && bash ./run_migrations.sh
```
4. Click "Save"

### Bước 3: Redeploy
1. Tab "Events" hoặc "Manual Deploy"
2. Click "Deploy latest commit"
3. Migrations sẽ chạy trước khi service start

---

## Cách 4: Chạy Migrations Qua SQL Trực Tiếp

Nếu script không hoạt động, có thể chạy migrations trực tiếp:

### Bước 1: Lấy Database Connection Info
1. Vào database service `ecocheck-database`
2. Tab "Info" → Copy connection details

### Bước 2: Connect và Chạy SQL
Sử dụng psql hoặc database client:

```bash
# Connect to database
psql "postgresql://user:password@host:5432/database"

# Hoặc từ Render Shell của web service:
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME
```

### Bước 3: Chạy Migration Files
```sql
-- Example: Create vehicles table
CREATE TABLE IF NOT EXISTS vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plate VARCHAR(20) UNIQUE NOT NULL,
    -- ... other columns
);
```

---

## Kiểm tra Migrations Đã Chạy

Sau khi chạy migrations, kiểm tra:

```sql
-- List all tables
\dt

-- Check schema_migrations table
SELECT * FROM schema_migrations ORDER BY version;

-- Check if vehicles table exists
SELECT * FROM vehicles LIMIT 1;
```

---

## Troubleshooting

### ❌ "Migration script not found"
**Nguyên nhân:** `/app/db/run_migrations.sh` không tồn tại trong container

**Giải pháp:**
1. Kiểm tra Dockerfile có copy `db` directory không
2. Check logs để xem path chính xác
3. Dùng Cách 2 (Shell) để check

### ❌ "Could not connect to database"
**Nguyên nhân:** DB_HOST, DB_PASSWORD, etc. chưa được set

**Giải pháp:**
1. Kiểm tra tab "Environment" có DB_* variables không
2. Đảm bảo database service đã "Available"
3. Kiểm tra Internal Database URL đúng chưa

### ❌ "Migrations failed, but continuing"
**Nguyên nhân:** Migration script có lỗi SQL

**Giải pháp:**
1. Xem logs chi tiết để tìm lỗi SQL cụ thể
2. Kiểm tra migration files có syntax error không
3. Chạy từng migration file riêng lẻ để tìm lỗi

---

## Sau Khi Migrations Chạy Thành Công

Bạn sẽ thấy:
- ✅ Tables được tạo (vehicles, depots, personnel, etc.)
- ✅ Không còn lỗi "relation does not exist"
- ✅ Backend có thể query database
- ✅ Socket.IO và cron jobs hoạt động bình thường

---

**Hãy thử Cách 1 trước (Redeploy), sau đó kiểm tra logs. Nếu vẫn lỗi, dùng Cách 2 (Shell) để chạy thủ công.**



