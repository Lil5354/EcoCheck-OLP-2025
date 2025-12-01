# 🚀 Hướng Dẫn Deploy EcoCheck

Tài liệu này hướng dẫn deploy EcoCheck lên public server. **Phương án tối ưu nhất: Railway.app (FREE)**

---

## ⚡ Deploy lên Railway.app (Khuyến nghị - FREE)

### Bước 1: Đăng Ký Railway
1. Truy cập: **https://railway.app**
2. Click **"Start a New Project"**
3. Chọn **"Login with GitHub"**
4. Authorize Railway để truy cập GitHub repos

### Bước 2: Deploy Backend
1. Click **"New Project"** → **"Deploy from GitHub repo"**
2. Chọn repository: **`Lil5354/EcoCheck-OLP-2025`**
3. Railway tự động detect `railway.toml` và `Dockerfile.railway`

**Lưu ý:** Nếu gặp lỗi "Error creating build plan with Railpack":
- Vào **Settings** của service
- Tìm **"Build Settings"** hoặc **"Deploy Settings"**
- Set **Dockerfile Path:** `Dockerfile.railway`
- Hoặc tắt Railpack và bật Docker build

### Bước 3: Thêm PostgreSQL Database
1. Click **"New"** → **"Database"** → **"Add PostgreSQL"**
2. Railway tự động tạo database và set `DATABASE_URL`
3. Database tự động connect với backend service

### Bước 4: Cấu Hình Environment Variables
Click vào service → **Variables** tab → Thêm (nếu chưa có):
```env
NODE_ENV=production
PORT=3000
ORION_LD_URL=http://orion-ld:1026
FIWARE_SERVICE=ecocheck
FIWARE_SERVICE_PATH=/hcm
```

**Lưu ý:** `DATABASE_URL` tự động được set khi thêm PostgreSQL.

### Bước 5: Lấy Public URL
1. Click service → **Settings**
2. Bật **"Generate Domain"**
3. Copy URL (ví dụ: `ecocheck-production.up.railway.app`)

### Bước 6: Kiểm Tra
```bash
# Health check
curl https://YOUR_RAILWAY_URL.railway.app/health

# API status
curl https://YOUR_RAILWAY_URL.railway.app/api/status
```

---

## 🖥️ Deploy lên VPS (Alternative)

### Bước 1: Chuẩn Bị Server
```bash
# Cài Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Cài Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Mở firewall
sudo ufw allow 3000/tcp
sudo ufw allow 3001/tcp
sudo ufw enable
```

### Bước 2: Deploy
```bash
# Clone code
git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
cd EcoCheck-OLP-2025

# Deploy tự động
chmod +x scripts/deploy-complete.sh
./scripts/deploy-complete.sh
```

**Windows:**
```powershell
.\scripts\deploy-complete.ps1
```

### Bước 3: Kiểm Tra
```bash
# Test backend
curl http://YOUR_SERVER_IP:3000/health

# Frontend: http://YOUR_SERVER_IP:3001
```

---

## 📱 Cập Nhật Mobile App

Sau khi deploy, cập nhật Mobile App:

**File:** `frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart`

```dart
// Railway
static const String baseUrl = 'https://YOUR_RAILWAY_URL.railway.app';

// Hoặc VPS
static const String baseUrl = 'http://YOUR_SERVER_IP:3000';
```

**Rebuild:**
```bash
cd frontend-mobile/EcoCheck_Worker
flutter clean && flutter pub get && flutter build apk
```

---

## 🧹 Tiết Kiệm Dung Lượng (VPS)

Sau khi deploy trên VPS, chạy cleanup:
```bash
chmod +x scripts/cleanup-docker.sh
./scripts/cleanup-docker.sh
```

Hoặc Windows:
```powershell
.\scripts\cleanup-docker.ps1
```

---

## 🔧 Troubleshooting

### Railway: "Error creating build plan with Railpack"
- Vào **Settings** → **Build Settings**
- Set **Dockerfile Path:** `Dockerfile.railway`
- Hoặc tắt Railpack

### Railway: Không tìm thấy repository
- Cài Railway GitHub App: https://github.com/apps/railway
- Authorize với quyền truy cập repositories

### Backend không khởi động
- Xem logs: Click service → **Logs** tab
- Kiểm tra environment variables
- Kiểm tra `DATABASE_URL` đã được set chưa

### Database connection error
- Đảm bảo PostgreSQL service đã được tạo
- Kiểm tra `DATABASE_URL` trong environment variables

---

## ✅ Checklist

- [ ] Đã deploy lên Railway hoặc VPS
- [ ] Đã thêm PostgreSQL database
- [ ] Environment variables đã cấu hình
- [ ] Đã lấy public URL
- [ ] Backend health check OK
- [ ] Mobile app đã cập nhật baseUrl
- [ ] Đã chạy cleanup script (nếu dùng VPS)

---

## 📚 Tài Liệu Khác

- [README.md](README.md) - Tổng quan dự án
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Kiến trúc hệ thống
- [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) - Hướng dẫn test

---

**Chúc bạn deploy thành công! 🚀**

