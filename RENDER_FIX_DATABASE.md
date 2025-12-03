# Hướng dẫn Fix Lỗi Database Connection trên Render

## Vấn đề
Lỗi: `ECONNREFUSED ::1:5432` - Backend không thể kết nối tới database vì đang dùng localhost thay vì database service của Render.

## Nguyên nhân
`DATABASE_URL` environment variable chưa được set hoặc web service chưa được link với database service.

---

## CÁCH 1: Kiểm tra và Link Database trong Render Dashboard (Nhanh nhất)

### Bước 1: Kiểm tra Database Service
1. Vào **Dashboard** → Click vào service **`ecocheck-database`** (hoặc tên database service của bạn)
2. Kiểm tra **Status** phải là **"Active"** (màu xanh)
3. Nếu đang "Provisioning", đợi xong (1-2 phút)

### Bước 2: Link Database với Web Service
1. Vào **Dashboard** → Click vào service **`ecocheck-web`** (hoặc **`EcoCheck-OLP-2025-1`**)
2. Vào tab **"Settings"** (icon bánh răng ở sidebar trái)
3. Scroll xuống phần **"Databases"**
4. Tìm button **"Link Database"** hoặc **"Add Database"**
5. Chọn database service **`ecocheck-database`** từ dropdown
6. Click **"Link"** hoặc **"Save"**

**✅ Render sẽ tự động:**
- Thêm `DATABASE_URL` environment variable
- Thêm `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`

### Bước 3: Redeploy Service
Sau khi link database:
1. Vẫn trong service **`ecocheck-web`**
2. Vào tab **"Events"** (hoặc tab **"Manual Deploy"**)
3. Click **"Clear build cache & deploy"** hoặc **"Deploy latest commit"**
4. Đợi deploy xong (~5 phút)

---

## CÁCH 2: Thêm Environment Variables Thủ Công

Nếu cách 1 không hoạt động hoặc không thấy option "Link Database":

### Bước 1: Lấy Database Connection Info
1. Vào service **`ecocheck-database`**
2. Vào tab **"Info"** (hoặc **"Connections"**)
3. Copy các thông tin sau:
   - **Internal Database URL** (dùng cho services trong Render)
   - **Hostname** (ví dụ: `dpg-xxxxx-a.singapore-postgres.render.com`)
   - **Port** (thường là `5432`)
   - **Database Name** (ví dụ: `ecocheck`)
   - **User** (ví dụ: `ecocheck_user`)
   - **Password** (có thể cần click "Show" để xem)

### Bước 2: Thêm Environment Variables vào Web Service
1. Vào service **`ecocheck-web`**
2. Vào tab **"Environment"** (icon document ở sidebar)
3. Click **"Add Environment Variable"**

Thêm từng biến sau:

**DATABASE_URL:**
- **Key:** `DATABASE_URL`
- **Value:** Paste **Internal Database URL** từ bước 1
  - Format: `postgresql://user:password@host:port/database`

**DB_HOST:**
- **Key:** `DB_HOST`
- **Value:** Hostname từ bước 1 (không bao gồm port)

**DB_PORT:**
- **Key:** `DB_PORT`
- **Value:** `5432` (hoặc port từ database service)

**DB_USER:**
- **Key:** `DB_USER`
- **Value:** User từ bước 1 (ví dụ: `ecocheck_user`)

**DB_PASSWORD:**
- **Key:** `DB_PASSWORD`
- **Value:** Password từ bước 1

**DB_NAME:**
- **Key:** `DB_NAME`
- **Value:** Database name từ bước 1 (ví dụ: `ecocheck`)

4. Click **"Save Changes"** sau mỗi biến

### Bước 3: Redeploy Service
1. Vào tab **"Events"** hoặc **"Manual Deploy"**
2. Click **"Clear build cache & deploy"**
3. Đợi deploy xong

---

## CÁCH 3: Kiểm tra Blueprint Configuration

Nếu bạn dùng Blueprint (render.yaml):

### Bước 1: Kiểm tra Blueprint
1. Vào **Dashboard** → Click **"Blueprints"** ở sidebar trái
2. Click vào blueprint đã tạo
3. Kiểm tra:
   - Database service: **`ecocheck-database`** đã được tạo
   - Web service: **`ecocheck-web`** đã được tạo
   - Web service có link tới database service

### Bước 2: Reapply Blueprint (nếu cần)
Nếu services chưa được link:
1. Trong Blueprint, click **"Apply"** lại
2. Render sẽ tạo lại services với đúng cấu hình

---

## Kiểm tra Logs sau khi Fix

Sau khi redeploy, kiểm tra logs:

### Bước 1: Xem Logs
1. Vào service **`ecocheck-web`**
2. Tab **"Logs"**
3. Tìm các dòng sau:

**✅ Nếu thành công:**
```
Database Configuration:
  DATABASE_URL: postgresql://user@host:port/database
  DB_HOST: dpg-xxxxx-a.singapore-postgres.render.com
  DB_PORT: 5432
  DB_USER: ecocheck_user
  DB_NAME: ecocheck
🐘 Connected to PostgreSQL database
```

**❌ Nếu vẫn lỗi:**
```
⚠ WARNING: DATABASE_URL is NOT set!
⚠ WARNING: DATABASE_URL environment variable is NOT set!
```

→ Nếu thấy warning này, environment variables chưa được set đúng.

---

## Troubleshooting

### ❌ Vẫn thấy "DATABASE_URL is NOT set"
**Giải pháp:**
1. Kiểm tra lại tab **"Environment"** → Đảm bảo `DATABASE_URL` có giá trị (không phải empty)
2. Đảm bảo đã click **"Save Changes"**
3. Redeploy service
4. Kiểm tra lại logs

### ❌ Database service chưa ready
**Giải pháp:**
1. Đợi database service status = **"Active"** (màu xanh)
2. Database provisioning thường mất 1-2 phút

### ❌ Vẫn lỗi ECONNREFUSED sau khi set DATABASE_URL
**Kiểm tra:**
1. DATABASE_URL có đúng format không?
   - ✅ Đúng: `postgresql://user:pass@host:5432/dbname`
   - ❌ Sai: `postgres://user:pass@host` (thiếu port/database)
2. Dùng **Internal Database URL** (không phải External)
3. Hostname có đúng không? (phải là internal hostname của Render)

### ❌ "Link Database" button không có
**Giải pháp:**
- Dùng **CÁCH 2** (thêm environment variables thủ công)
- Hoặc kiểm tra xem có phải đang dùng Blueprint không

---

## Checklist

Sau khi fix, đảm bảo:
- [ ] Database service status = **"Active"**
- [ ] Web service đã link tới database service (hoặc có environment variables)
- [ ] `DATABASE_URL` được set trong tab **"Environment"**
- [ ] Đã redeploy service sau khi thay đổi
- [ ] Logs không còn warning "DATABASE_URL is NOT set"
- [ ] Logs hiển thị "🐘 Connected to PostgreSQL database"

---

## Sau khi Fix Thành Công

1. Kiểm tra logs để đảm bảo:
   - Database connection thành công
   - Migrations đã chạy
   - Backend đã start
   - Nginx đã start

2. Test ứng dụng:
   - Mở Public URL của service
   - Frontend phải load được
   - Test API endpoints

**Chúc bạn fix thành công! 🚀**

