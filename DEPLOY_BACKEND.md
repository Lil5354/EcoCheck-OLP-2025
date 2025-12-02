# 🚀 Deploy Backend lên Railway

## Cách Deploy Backend Service

### Bước 1: Tạo Service Mới trên Railway

1. Vào Railway Dashboard: https://railway.app
2. Click vào project hiện tại
3. Click **"+ Create"** → **"GitHub Repo"**
4. Chọn repository: `Lil5354/EcoCheck-OLP-2025`
5. **QUAN TRỌNG**: Set **Root Directory**: `.` (root của repo) hoặc để trống
   - Backend cần build từ root repo vì cần cả `backend/` và `db/`

### Bước 2: Cấu Hình Build

Railway sẽ tự động detect `railway.toml` và `Dockerfile.railway` ở root repo

Hoặc cấu hình thủ công trong Settings → Build & Deploy:
- **Build Command**: (để trống, Dockerfile sẽ build)
- **Dockerfile Path**: `Dockerfile.railway`
- **Root Directory**: `.` (root) hoặc để trống

### Bước 3: Set Environment Variables

Vào tab **Variables** → Click **"+ New Variable"** → Thêm các biến sau:

```env
# Database
DATABASE_URL=postgresql://user:pass@host:5432/dbname
DB_HOST=your-db-host
DB_USER=your-db-user
DB_PASSWORD=your-db-password
DB_NAME=your-db-name
DB_PORT=5432

# FIWARE Orion-LD
ORION_LD_URL=http://orion-ld:1026
FIWARE_SERVICE=ecocheck
FIWARE_SERVICE_PATH=/hcm

# App
NODE_ENV=production
PORT=3000

# OpenWeatherMap (nếu có)
OPENWEATHER_API_KEY=your-api-key

# Air Quality API (nếu có)
AIRQUALITY_API_KEY=your-api-key
```

### Bước 4: Lấy Public URL

1. Vào tab **Settings**
2. Bật **"Generate Domain"**
3. Copy URL (ví dụ: `ecocheck-backend.up.railway.app`)

---

## ✅ Hoàn Tất!

Backend sẽ có URL riêng và tự động chạy migrations khi khởi động.

**URLs:**
- Backend API: `https://YOUR_BACKEND_URL.railway.app`
- Health Check: `https://YOUR_BACKEND_URL.railway.app/health`

---

## 🐛 Troubleshooting

### Lỗi: "/backend/entrypoint.sh": not found

**Nguyên nhân**: 
- File `backend/entrypoint.sh` chưa được commit/push lên GitHub
- Hoặc Railway đang build từ commit cũ chưa có file này
- Hoặc Root Directory chưa được set đúng (phải là `.` hoặc để trống)

**Cách kiểm tra**:
1. Kiểm tra file có trong repo local:
   ```bash
   git ls-files backend/entrypoint.sh
   ```
2. Kiểm tra file có trong commit hiện tại:
   ```bash
   git show HEAD:backend/entrypoint.sh
   ```
3. Kiểm tra Root Directory trong Railway Settings:
   - Phải là `.` (root) hoặc để trống
   - KHÔNG được set = `backend` (sai!)

**Giải pháp**:
1. Nếu file chưa có trong commit, thêm và push:
   ```bash
   git add backend/entrypoint.sh
   git commit -m "Add backend entrypoint.sh"
   git push origin TWeb
   ```
2. Kiểm tra Root Directory trong Railway Settings:
   - Vào Settings → Source hoặc Build & Deploy
   - Root Directory phải là `.` (root) hoặc để trống
   - KHÔNG được set = `backend`
3. Vào Railway → Deployments → Redeploy để build lại
4. Nếu vẫn lỗi, thử trigger build bằng cách push commit mới (dù chỉ là whitespace change)

### Lỗi: "Database connection failed"

**Nguyên nhân**: Database variables chưa được set đúng.

**Giải pháp**:
1. Kiểm tra Variables trong Railway Settings
2. Đảm bảo `DATABASE_URL` hoặc các biến `DB_*` đã được set
3. Kiểm tra database service đã được tạo và running chưa

### Lỗi: "Migration script not found"

**Nguyên nhân**: File `db/run_migrations.sh` chưa có hoặc chưa được copy vào container.

**Giải pháp**:
1. Kiểm tra file `db/run_migrations.sh` có trong repo
2. Đảm bảo Dockerfile.railway có dòng: `COPY db ./db`
3. Push và redeploy

### Build thành công nhưng app không start

**Kiểm tra**:
1. Xem Deploy Logs (không phải Build Logs)
2. Kiểm tra Variables đã set đầy đủ chưa
3. Kiểm tra PORT environment variable
4. Xem logs để tìm lỗi cụ thể

---

**Xem chi tiết:** [DEPLOYMENT.md](DEPLOYMENT.md)

