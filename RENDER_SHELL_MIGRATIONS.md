# Hướng dẫn Chạy Migrations Qua Render Shell

## Vấn đề: `bash: not found`

Container Alpine Linux không có `bash`, chỉ có `sh`. 

## Giải pháp: Dùng `sh` thay vì `bash`

### Cách 1: Chạy trực tiếp với `sh`

Trong Render Shell, chạy:

```bash
cd /app/db
export PGPASSWORD=$DB_PASSWORD
sh ./run_migrations.sh
```

Hoặc nếu muốn chạy trực tiếp:

```bash
cd /app/db && export PGPASSWORD=$DB_PASSWORD && sh ./run_migrations.sh
```

---

### Cách 2: Chạy migrations từng file

Nếu script vẫn không chạy, có thể chạy trực tiếp với psql:

```bash
# Set environment
export PGPASSWORD=$DB_PASSWORD

# Connect và chạy migration files
cd /app/db/migrations

# List migration files
ls -la *.sql

# Chạy từng file (thay 001_init_no_postgis.sql bằng tên file thực tế)
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 001_init_no_postgis.sql
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f 002_comprehensive_schema.sql
# ... tiếp tục với các file khác
```

---

### Cách 3: Sửa entrypoint để dùng `sh` thay vì `bash`

Đã fix trong code mới - entrypoint sẽ dùng `/bin/sh` thay vì `bash`.

---

## Lệnh Hoàn Chỉnh để Chạy Migrations

Copy và paste vào Render Shell:

```bash
cd /app/db
export PGPASSWORD=$DB_PASSWORD
echo "DB_HOST: $DB_HOST"
echo "DB_NAME: $DB_NAME"
echo "DB_USER: $DB_USER"
sh ./run_migrations.sh
```

---

## Kiểm tra Sau Khi Chạy

Sau khi migrations chạy xong, kiểm tra:

```bash
# Connect to database
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME

# Trong psql, chạy:
\dt              # List all tables
SELECT * FROM schema_migrations;  # Check migrations đã chạy
SELECT * FROM vehicles LIMIT 1;   # Check vehicles table exists
\q               # Exit psql
```

---

## Nếu Vẫn Lỗi

Kiểm tra:
1. Migration script có executable permission không:
   ```bash
   ls -la /app/db/run_migrations.sh
   chmod +x /app/db/run_migrations.sh
   ```

2. Migration files có tồn tại không:
   ```bash
   ls -la /app/db/migrations/
   ```

3. Database connection:
   ```bash
   PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;"
   ```

