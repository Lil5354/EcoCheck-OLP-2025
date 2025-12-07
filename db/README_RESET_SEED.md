# Hướng Dẫn Reset và Seed Dữ Liệu TPHCM

Script này sẽ xóa toàn bộ dữ liệu cũ và seed lại với dữ liệu đa dạng, chỉ trong TPHCM.

## ⚠️ CẢNH BÁO

**Script này sẽ XÓA TOÀN BỘ dữ liệu hiện tại!** Chỉ chạy khi bạn chắc chắn muốn reset database.

## 📋 Yêu Cầu

- PostgreSQL đã được setup
- Database `ecocheck` đã được tạo
- Các migrations đã được chạy (schema đã có sẵn)

## 🚀 Cách Chạy

### Trên Local (Windows)

```powershell
cd db
.\run_reset_seed_tphcm.ps1
```

### Trên Local (Linux/Mac)

```bash
cd db
chmod +x run_reset_seed_tphcm.sh
./run_reset_seed_tphcm.sh
```

### Trên Render (Production)

1. **Kết nối vào Render Database:**

```bash
# Lấy connection string từ Render Dashboard
# Format: postgresql://user:password@host:port/database

# Set environment variables
export DB_HOST=your-render-db-host
export DB_PORT=5432
export DB_NAME=your-db-name
export DB_USER=your-db-user
export DB_PASSWORD=your-db-password

# Chạy script
cd db
./run_reset_seed_tphcm.sh
```

2. **Hoặc dùng psql trực tiếp:**

```bash
psql "postgresql://user:password@host:port/database" -f db/reset_and_seed_tphcm_data.sql
```

## 📊 Dữ Liệu Sẽ Được Seed

### Master Data
- **7 Depots** (Trạm thu gom) - Chỉ trong TPHCM
- **3 Dumps** (Bãi rác) - Chỉ trong TPHCM
- **12 Vehicles** (Phương tiện) - Đa dạng loại
- **13 Personnel** (Nhân sự) - Drivers, Collectors, Managers, etc.

### User Data
- **12 Users** (Người dân) - Bao gồm test users
- **12 User Addresses** - Chỉ trong TPHCM (Quận 1, 3, 5, 7, 10, Bình Thạnh, Tân Bình, Phú Nhuận)
- **30 Points** (Điểm thu gom) - Chỉ trong TPHCM

### Operational Data
- **40-100 Schedules** (Lịch thu gom) - Đa dạng status:
  - `pending` - Chờ xử lý
  - `scheduled` - Đã lên lịch
  - `assigned` - Đã phân công
  - `in_progress` - Đang thực hiện
  - `completed` - Đã hoàn thành
  
- **20-60 Incidents** (Báo cáo) - Đa dạng:
  - **Violations** (Vi phạm): illegal_dump, wrong_classification, overloaded_bin, littering, burning_waste
  - **Damages** (Hư hỏng): broken_bin, damaged_equipment, road_damage, facility_damage
  - Status: pending, open, in_progress, resolved, closed

- **10 Routes** (Tuyến đường) - Active routes với route_stops
- **50 Checkins** (Check-in rác) - Dữ liệu check-in

## 🗺️ Địa Chỉ Chỉ Trong TPHCM

Tất cả địa chỉ được giới hạn trong phạm vi TPHCM:
- **Latitude**: 10.7 - 10.9
- **Longitude**: 106.6 - 106.8

Các quận được sử dụng:
- Quận 1, 3, 5, 7, 10
- Bình Thạnh, Tân Bình, Phú Nhuận

## ✅ Sau Khi Chạy

Script sẽ hiển thị summary với số lượng records đã được seed cho mỗi bảng.

Kiểm tra dữ liệu:
```sql
SELECT 
  'schedules' as table_name, COUNT(*) as count, 
  COUNT(DISTINCT status) as status_count
FROM schedules
UNION ALL
SELECT 'incidents', COUNT(*), COUNT(DISTINCT status) FROM incidents
UNION ALL
SELECT 'routes', COUNT(*), COUNT(DISTINCT status) FROM routes;
```

## 🔧 Troubleshooting

### Lỗi: "relation does not exist"
- Đảm bảo đã chạy migrations trước
- Chạy: `./run_migrations.sh` hoặc `.\run_migrations.ps1`

### Lỗi: "permission denied"
- Kiểm tra quyền của database user
- Đảm bảo user có quyền TRUNCATE và INSERT

### Lỗi: "foreign key constraint"
- Script đã xóa theo thứ tự đúng
- Nếu vẫn lỗi, kiểm tra lại schema migrations

## 📝 Notes

- Script giữ nguyên schema (không xóa tables)
- Chỉ xóa dữ liệu (TRUNCATE)
- Tất cả dữ liệu được seed với địa chỉ trong TPHCM
- Dữ liệu đa dạng để test các tính năng khác nhau

