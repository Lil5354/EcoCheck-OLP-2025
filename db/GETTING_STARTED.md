# Hướng dẫn nhanh: Xem và dùng Database EcoCheck

File này dành cho coder mới vào dự án. Làm theo 3 bước dưới đây là xem được dữ liệu thật (PostgreSQL + PostGIS + TimescaleDB).

## 1) Khởi động database (5 phút)

- Yêu cầu: Docker Desktop cài sẵn

```bash
# Từ thư mục gốc dự án
docker-compose up -d postgres

# Kiểm tra database đã sẵn sàng
docker-compose exec postgres pg_isready -U ecocheck_user -d ecocheck
```

Chạy migration + seed dữ liệu:

- Windows (PowerShell)
```powershell
cd db
.\run_migrations.ps1
```
- Linux/Mac (Bash)
```bash
cd db
chmod +x run_migrations.sh
./run_migrations.sh
```

Kỳ vọng: hiện các dòng "Success" và "All migrations completed successfully!".

Kết nối DB (mặc định):
```
postgresql://ecocheck_user:ecocheck_pass@localhost:5432/ecocheck
```

## 2) Cách xem database

- pgAdmin (khuyên dùng): Add Server → host: localhost, db: ecocheck, user: ecocheck_user, pass: ecocheck_pass
- DBeaver: New Connection → PostgreSQL → điền thông tin như trên
- VS Code: cài extension "PostgreSQL" → Add Connection
- psql (CLI):
```bash
psql -U ecocheck_user -h localhost -d ecocheck
\dt              -- liệt kê bảng
\d users         -- cấu trúc bảng
\q               -- thoát
```

## 3) Dữ liệu mẫu đã seed (đủ để dev ngay)

- Master data: 5 depots, 4 dumps, 12 vehicles, 15 personnel
- Users: 10 citizens + 2 workers + 2 managers + 1 admin
- Gamification: 17 badges, điểm & transactions mẫu
- Operations: check-ins, routes, route_stops, incidents, exceptions
- Billing: billing_cycles, user_bills

Một số account tiêu biểu:

| Role    | Phone      | Email                 |
|---------|------------|-----------------------|
| citizen | 0911111111 | user1@example.com     |
| citizen | 0922222222 | user2@example.com     |
| citizen | 0933333333 | user3@example.com     |
| worker  | 0901234567 | worker1@ecocheck.vn   |
| worker  | 0903456789 | worker2@ecocheck.vn   |
| manager | 0910123456 | manager1@ecocheck.vn  |
| manager | 0911234567 | manager2@ecocheck.vn  |
| admin   | 0900000001 | admin@ecocheck.vn     |

## 4) Query nhanh (copy/paste)

- Check users:
```sql
SELECT id, phone, email, role, profile->>'name' AS name
FROM users ORDER BY role, phone LIMIT 20;
```

- Check-ins gần đây (TimescaleDB hypertable):
```sql
SELECT c.id, u.profile->>'name' AS user_name, c.waste_type, c.filling_level, c.verified, c.created_at
FROM checkins c JOIN users u ON u.id = c.user_id
ORDER BY c.created_at DESC LIMIT 10;
```

- Lộ trình đang hoạt động:
```sql
SELECT r.id, v.plate AS vehicle, r.status, r.start_at, COUNT(rs.id) AS total_stops
FROM routes r JOIN vehicles v ON v.id = r.vehicle_id
LEFT JOIN route_stops rs ON rs.route_id = r.id
WHERE r.status IN ('planned','in_progress')
GROUP BY r.id, v.plate ORDER BY r.start_at DESC;
```

- Spatial: điểm thu gom trong bán kính 1km từ (106.6958, 10.7769)
```sql
SELECT p.id, p.last_waste_type,
       ST_Distance(p.geom, ST_GeogFromText('POINT(106.6958 10.7769)')) AS distance_m
FROM points p
WHERE ST_DWithin(p.geom, ST_GeogFromText('POINT(106.6958 10.7769)'), 1000)
ORDER BY distance_m;
```

## 5) Tài liệu chi tiết (thư mục db/)
- README.md: setup & kiến trúc DB
- SCHEMA.md: mô tả 27 bảng, quan hệ, index
- QUERIES.md: bộ query tham khảo (analytics, performance)
- ER_DIAGRAM.md: sơ đồ ER (Mermaid)

## 6) Troubleshooting

```bash
# xem logs
docker-compose logs postgres
# restart DB
docker-compose restart postgres
# reset DB hoàn toàn
docker-compose down -v && docker-compose up -d postgres && cd db && ./run_migrations.sh
```

Chúc bạn code vui vẻ! 🚀

