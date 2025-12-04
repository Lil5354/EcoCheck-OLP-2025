# Hướng Dẫn Seed Dữ Liệu Test Cho Dashboard

Tài liệu này hướng dẫn cách seed dữ liệu test để dashboard hiển thị số liệu thay vì 0%.

---

## 🎯 Vấn Đề

Dashboard hiển thị:
- **Tỷ lệ thu gom**: 0%
- **Thu gom hôm nay**: 0.0t

**Nguyên nhân**: Không có dữ liệu schedules với `status = 'completed'` và `completed_at = hôm nay` trong database.

---

## ✅ Giải Pháp

Có 2 cách để seed dữ liệu:

### Cách 1: Sử dụng API Endpoint (Khuyến nghị cho Public Server)

**Endpoint**: `POST /api/dev/seed-dashboard-data`

**Cách sử dụng:**

1. **Qua cURL:**
   ```bash
   curl -X POST http://your-server:3000/api/dev/seed-dashboard-data
   ```

2. **Qua Postman/Thunder Client:**
   - Method: `POST`
   - URL: `http://your-server:3000/api/dev/seed-dashboard-data`
   - Headers: `Content-Type: application/json`
   - Body: (không cần)

3. **Qua Browser Console:**
   ```javascript
   fetch('http://your-server:3000/api/dev/seed-dashboard-data', {
     method: 'POST',
     headers: { 'Content-Type': 'application/json' }
   })
   .then(r => r.json())
   .then(console.log);
   ```

**Response:**
```json
{
  "ok": true,
  "message": "Seeded 9 schedules for today and 3 for yesterday",
  "data": {
    "today": 9,
    "yesterday": 3,
    "totalWeightToday": "172.6 kg",
    "totalWeightTodayTons": "0.2 t",
    "collectionRate": "66.7%",
    "completedToday": 6,
    "totalToday": 9
  }
}
```

**Dữ liệu được tạo:**
- **Hôm nay**: 9 schedules
  - 6 schedules `completed` (tổng 172.6 kg = 0.2 tấn)
  - 3 schedules `in_progress`/`assigned` (chưa completed)
- **Hôm qua**: 3 schedules `completed` (tổng 65.5 kg = 0.07 tấn)

**Kết quả sau khi seed:**
- ✅ Tỷ lệ thu gom: **66.7%** (6/9)
- ✅ Thu gom hôm nay: **0.2t** (172.6 kg)
- ✅ Routes Active: Giữ nguyên (15 routes)

---

### Cách 2: Sử dụng SQL Script

**File**: `db/seed_dashboard_data.sql`

**Cách sử dụng:**

1. **Qua psql:**
   ```bash
   psql -U ecocheck_user -d ecocheck -f db/seed_dashboard_data.sql
   ```

2. **Qua Docker:**
   ```bash
   docker compose exec postgres psql -U ecocheck_user -d ecocheck -f /app/db/seed_dashboard_data.sql
   ```

3. **Qua pgAdmin hoặc DBeaver:**
   - Mở file `db/seed_dashboard_data.sql`
   - Chạy script

**Dữ liệu được tạo:** Tương tự như Cách 1

---

## 📊 Dữ Liệu Chi Tiết

### Schedules Hôm Nay (9 schedules)

**Completed (6 schedules - 172.6 kg):**
1. Morning - Household: 25.5 kg
2. Morning - Recyclable: 18.2 kg
3. Afternoon - Household: 32.1 kg
4. Afternoon - Bulky: 45.8 kg
5. Evening - Recyclable: 22.3 kg
6. Evening - Household: 28.7 kg

**In Progress/Assigned (3 schedules):**
7. Morning - Household: 20.0 kg (in_progress)
8. Afternoon - Recyclable: 15.0 kg (assigned)
9. Evening - Bulky: 30.0 kg (assigned)

### Schedules Hôm Qua (3 schedules - 65.5 kg)

1. Morning - Household: 20.0 kg
2. Afternoon - Recyclable: 15.5 kg
3. Evening - Household: 30.0 kg

---

## 🔄 Xóa Dữ Liệu Test (Nếu cần)

Nếu muốn xóa dữ liệu test đã seed:

```sql
-- Xóa schedules test (cẩn thận!)
DELETE FROM schedules 
WHERE address LIKE '%Đường Lê Lợi, Q1, HCM%'
  AND created_at >= CURRENT_DATE - INTERVAL '2 days';
```

---

## ⚠️ Lưu Ý

1. **Endpoint này chỉ dùng cho development/testing**
   - Không nên expose trên production
   - Có thể thêm authentication nếu cần

2. **Dữ liệu sẽ được tạo mỗi lần gọi API**
   - Nếu gọi nhiều lần, sẽ có duplicate data
   - Nên xóa dữ liệu cũ trước khi seed lại

3. **Cần có users và personnel trong database**
   - Nếu chưa có, chạy `db/seed_data.sql` trước

---

## 🎉 Kết Quả

Sau khi seed dữ liệu, dashboard sẽ hiển thị:
- ✅ **Tỷ lệ thu gom**: 66.7% (thay vì 0%)
- ✅ **Thu gom hôm nay**: 0.2t (thay vì 0.0t)
- ✅ **Routes Active**: 15 (giữ nguyên)
- ✅ **Biểu đồ**: Có dữ liệu hiển thị
- ✅ **Rác theo loại**: Có phân bố (household, recyclable, bulky)

---

**Chúc bạn thành công!** 🚀

