# Hướng dẫn Hoàn Thành Deploy trên Render

## ✅ Đã Fix Các Lỗi

### 1. Fix render.yaml
- **Lỗi:** `unknown type "pspg"`
- **Fix:** Đổi `type: pspg` → `type: pg` (đúng type cho PostgreSQL trong Render)

### 2. Fix psql Connection
- **Lỗi:** `psql: error: connection to server on socket "/run/postgresql/.s.PGSQL.5432" failed`
- **Fix:** Đảm bảo `run_migrations.sh` luôn dùng TCP connection với `-h "$DB_HOST"`

### 3. Fix Database Connection
- **Lỗi:** `ECONNREFUSED ::1:5432`
- **Fix:** Code sẽ tự build `DATABASE_URL` từ `DB_*` env vars hoặc fail early

---

## 🚀 Các Bước Hoàn Thành Deploy

### BƯỚC 1: Apply Blueprint (nếu chưa apply)

1. Vào **Dashboard** → Click **"Blueprints"** (sidebar trái)
2. Nếu chưa có blueprint:
   - Click **"New Blueprint"**
   - Chọn repository: `EcoCheck-OLP-2025`
   - Chọn branch: `DRender`
   - Click **"Apply"**
3. Nếu đã có blueprint nhưng lỗi:
   - Click vào blueprint
   - Click **"Apply"** lại để update với code mới

**✅ Kiểm tra:** Blueprint không còn lỗi `unknown type "pspg"`

---

### BƯỚC 2: Kiểm tra Database Service

1. Vào **Dashboard** → Xem **"Ungrouped Services"** hoặc **"Production"**
2. Tìm service **`ecocheck-database`**
3. Kiểm tra:
   - ✅ Status = **"Available"** (màu xanh)
   - ✅ Runtime = **"PostgreSQL 15"**

**✅ Kiểm tra:** Database service đang hoạt động

---

### BƯỚC 3: Link Database với Web Service

1. Vào service **`ecocheck-web`** (hoặc **`EcoCheck-OLP-2025`**)
2. Tab **"Settings"** (icon bánh răng)
3. Scroll xuống phần **"Databases"**
4. Click **"Link Database"**
5. Chọn **`ecocheck-database`** từ dropdown
6. Click **"Link"**

**✅ Kiểm tra:** 
- Tab **"Environment"** → Có `DATABASE_URL` và các `DB_*` variables

---

### BƯỚC 4: Redeploy Web Service

Sau khi link database hoặc có code mới:

1. Vào service **`ecocheck-web`**
2. Tab **"Events"** hoặc **"Manual Deploy"**
3. Click **"Clear build cache & deploy"** hoặc **"Deploy latest commit"**
4. Đợi deploy xong (~5-10 phút)

**✅ Kiểm tra:** 
- Build thành công
- Service status = **"Live"** (màu xanh)

---

### BƯỚC 5: Kiểm tra Logs

1. Vào service **`ecocheck-web`**
2. Tab **"Logs"**
3. Tìm các dòng sau:

**✅ Nếu thành công:**
```
Database Configuration:
  DATABASE_URL: postgresql://user@host:port/database
  DB_HOST: dpg-xxxxx-a.singapore-postgres.render.com
🔗 DATABASE_URL: postgresql://user@host:port/database
🐘 Connected to PostgreSQL database
Running database migrations...
✓ Database connection successful
✓ All migrations completed successfully!
Starting Node.js backend...
```

**❌ Nếu vẫn lỗi:**
```
⚠ WARNING: DATABASE_URL is NOT set!
⚠ WARNING: No database connection info found
```
→ Cần kiểm tra lại bước 3 (Link Database)

**❌ Nếu còn ECONNREFUSED:**
```
Error: connect ECONNREFUSED ::1:5432
```
→ Cần đảm bảo `DATABASE_URL` hoặc `DB_HOST` được set đúng

---

### BƯỚC 6: Test Ứng Dụng

1. **Kiểm tra Health Check:**
   - Vào service **`ecocheck-web`**
   - Copy **Public URL** (ví dụ: `https://ecocheck-web.onrender.com`)
   - Mở browser và truy cập: `https://your-url.onrender.com/health`
   - Phải return: `{"status":"OK","service":"nginx","ready":true}`

2. **Kiểm tra Frontend:**
   - Truy cập Public URL
   - Frontend phải load được (React app)

3. **Kiểm tra Backend API:**
   ```bash
   curl https://your-url.onrender.com/api/health
   # hoặc
   curl https://your-url.onrender.com/api/personnel
   ```

**✅ Kiểm tra:** 
- Frontend load được
- API trả về dữ liệu (không phải 500 error)
- Không còn lỗi trong logs

---

## 🔍 Troubleshooting

### ❌ Blueprint vẫn lỗi "unknown type pspg"

**Giải pháp:**
- Đảm bảo đã commit và push code mới lên branch `DRender`
- Reapply Blueprint (hoặc xóa và tạo lại)

---

### ❌ Logs vẫn hiển thị "DATABASE_URL is NOT set"

**Kiểm tra:**
1. Tab **"Environment"** của web service
2. Có `DATABASE_URL` không? (không được empty)
3. Có `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` không?

**Giải pháp:**
1. Đảm bảo đã link database (Bước 3)
2. Nếu chưa link được, thêm thủ công:
   - Vào database service → Tab **"Info"** → Copy **Internal Database URL**
   - Vào web service → Tab **"Environment"** → Add `DATABASE_URL`
   - Redeploy

---

### ❌ Vẫn lỗi ECONNREFUSED sau khi set DATABASE_URL

**Kiểm tra:**
1. DATABASE_URL có đúng format không?
   - ✅ Đúng: `postgresql://user:pass@host:5432/dbname`
   - ❌ Sai: `postgres://...` (thiếu 'ql') hoặc thiếu port/dbname

2. Dùng **Internal Database URL** (không phải External)
   - Internal: Dùng cho services trong cùng Render
   - External: Dùng cho kết nối từ bên ngoài

**Giải pháp:**
- Kiểm tra lại Internal Database URL từ database service
- Copy chính xác, không chỉnh sửa

---

### ❌ Migrations fail với psql error

**Kiểm tra logs:**
- Nếu thấy `psql: error: connection to server on socket...`
- Có nghĩa là `DB_HOST` chưa được set khi chạy migrations

**Giải pháp:**
1. Đảm bảo đã link database (Bước 3)
2. Kiểm tra tab **"Environment"** có `DB_HOST` không
3. Redeploy để apply environment variables

---

## ✅ Checklist Hoàn Thành

- [ ] ✅ Blueprint apply thành công (không lỗi)
- [ ] ✅ Database service status = "Available"
- [ ] ✅ Web service đã link với database service
- [ ] ✅ Environment variables có `DATABASE_URL` và `DB_*` vars
- [ ] ✅ Web service đã redeploy với code mới
- [ ] ✅ Logs không còn warning "DATABASE_URL is NOT set"
- [ ] ✅ Logs hiển thị "🐘 Connected to PostgreSQL database"
- [ ] ✅ Migrations chạy thành công
- [ ] ✅ Health check endpoint trả về 200
- [ ] ✅ Frontend load được
- [ ] ✅ Backend API hoạt động
- [ ] ✅ Không còn lỗi ECONNREFUSED trong logs

---

## 📝 Tóm Tắt Các Thay Đổi Đã Fix

1. **render.yaml:**
   - `type: pspg` → `type: pg`

2. **backend/src/index.js:**
   - Build `DATABASE_URL` từ `DB_*` vars nếu chưa có
   - Fail early trong production nếu không có database connection
   - Better error messages

3. **backend/entrypoint.sh:**
   - Export `DB_*` vars cho migrations script
   - Better error handling

---

## 🎉 Sau Khi Hoàn Thành

1. Service sẽ chạy ổn định
2. Database migrations đã chạy
3. Backend kết nối database thành công
4. Cron jobs và Socket.IO broadcast hoạt động bình thường
5. Frontend và API đều accessible

**Chúc bạn deploy thành công! 🚀**



