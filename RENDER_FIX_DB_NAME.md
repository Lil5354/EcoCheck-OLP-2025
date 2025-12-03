# Fix Database Name Error trên Render

## Vấn đề
Lỗi: `FATAL: database "ecocheck-database" does not exist`

**Nguyên nhân:** Environment variable `DB_NAME` đang set là `ecocheck-database` (tên service), nhưng database thực tế có tên khác (thường là `ecocheck`).

---

## CÁCH 1: Kiểm tra Database Name Thực Tế

### Bước 1: List tất cả databases

Trong Render Shell, chạy:

```bash
# Connect to PostgreSQL server (không chỉ định database cụ thể)
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "\l"
```

Hoặc:

```bash
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c "SELECT datname FROM pg_database WHERE datistemplate = false;"
```

**Kết quả:** Bạn sẽ thấy danh sách databases. Tìm database có tên như:
- `ecocheck`
- `ecocheck_user` 
- Hoặc tên khác (không phải `ecocheck-database`)

---

## CÁCH 2: Kiểm tra trong Render Dashboard

### Bước 1: Vào Database Service
1. Vào Render Dashboard
2. Click vào database service `ecocheck-database`
3. Tab "Info" hoặc "Settings"

### Bước 2: Tìm Database Name
Tìm thông tin:
- **Database Name** hoặc **Database**
- Thường là `ecocheck` (không phải `ecocheck-database`)

---

## CÁCH 3: Sửa Environment Variable DB_NAME

### Bước 1: Vào Web Service
1. Vào service `EcoCheck-OLP-2025`
2. Tab "Environment"

### Bước 2: Sửa DB_NAME
1. Tìm environment variable `DB_NAME`
2. Click "Edit" hoặc click vào giá trị hiện tại
3. Đổi từ `ecocheck-database` → `ecocheck` (hoặc tên database thực tế)
4. Click "Save"

### Bước 3: Redeploy
1. Tab "Events" hoặc "Manual Deploy"
2. Click "Deploy latest commit"
3. Đợi deploy xong

---

## CÁCH 4: Test Connection với Database Name Đúng

Sau khi biết database name đúng, test:

```bash
# Test với database name đúng (ví dụ: ecocheck)
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d ecocheck -c "SELECT 1;"
```

Nếu thành công → database name là `ecocheck`

---

## Quick Fix: Chạy Migrations với Database Name Đúng

Nếu database name là `ecocheck`, chạy:

```bash
cd /app/db
export PGPASSWORD=$DB_PASSWORD
export DB_NAME=ecocheck  # Override DB_NAME
sh ./run_migrations.sh
```

Hoặc chạy trực tiếp với database name đúng:

```bash
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d ecocheck -f /app/db/migrations/001_init_no_postgis.sql
```

---

## Checklist

- [ ] Đã list databases để tìm tên database thực tế
- [ ] Đã sửa `DB_NAME` environment variable trong Render
- [ ] Đã redeploy service
- [ ] Đã test connection với database name đúng
- [ ] Migrations chạy thành công

---

**Hãy thử CÁCH 1 trước để tìm database name thực tế, sau đó sửa `DB_NAME` environment variable.**



