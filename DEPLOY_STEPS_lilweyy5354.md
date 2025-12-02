# 🚀 Hướng Dẫn Deploy EcoCheck - Username: lilweyy5354

## 📋 Checklist

- [ ] Docker Desktop đã chạy ✅
- [ ] Đã login Docker Hub
- [ ] Đã build và push images
- [ ] Đã chuẩn bị server
- [ ] Đã deploy trên server

---

## Bước 1: Login Docker Hub

### Cách 1: Dùng Password

```powershell
docker login
```

Nhập:
- **Username**: `lilweyy5354`
- **Password**: [Password Docker Hub của bạn]

### Cách 2: Dùng Personal Access Token (Khuyến nghị)

1. Truy cập: https://hub.docker.com/settings/security
2. Click **"New Access Token"**
3. Tạo token với quyền **Read, Write, Delete**
4. Copy token
5. Login:

```powershell
docker login -u lilweyy5354
# Paste token khi được hỏi password
```

---

## Bước 2: Build và Push Images

### Option 1: Dùng Script Helper (Dễ nhất)

```powershell
.\scripts\build-and-push-lilweyy5354.ps1
```

### Option 2: Dùng Script Chính

```powershell
# Set environment variables
$env:DOCKER_REGISTRY = "lilweyy5354"
$env:IMAGE_TAG = "latest"
$env:VITE_API_URL = "http://localhost:3000"  # Thay bằng IP server của bạn

# Chạy script
.\scripts\build-and-push-images.ps1
```

**Thời gian**: 10-20 phút (tùy tốc độ mạng)

**Kết quả mong đợi**:
- ✅ Backend image built successfully
- ✅ Frontend image built successfully
- ✅ Backend image pushed successfully
- ✅ Frontend image pushed successfully

---

## Bước 3: Kiểm Tra Images trên Docker Hub

1. Truy cập: https://hub.docker.com/u/lilweyy5354
2. Kiểm tra có 2 repositories:
   - `ecocheck-backend`
   - `ecocheck-frontend`

---

## Bước 4: Chuẩn Bị Server

### Yêu Cầu:
- VPS/Server có Docker và Docker Compose
- Ports mở: 80, 3000, 5432
- Git đã cài

### Cài Docker trên Ubuntu/Debian:

```bash
# Cài Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Cài Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Logout và login lại để áp dụng group changes
```

---

## Bước 5: Deploy trên Server

### 5.1. Clone Repository

```bash
git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
cd EcoCheck-OLP-2025
git checkout TWeb
```

### 5.2. Tạo File .env

```bash
# Copy example
cp .env.example .env

# Edit .env
nano .env
```

**Cập nhật .env:**

```env
# Docker Registry
DOCKER_REGISTRY=lilweyy5354
IMAGE_TAG=latest

# Database password (THAY BẰNG PASSWORD MẠNH!)
DB_PASSWORD=your_secure_password_here

# Ports
BACKEND_PORT=3000
FRONTEND_PORT=80
POSTGRES_PORT=5432

# Frontend API URL (THAY BẰNG IP/DOMAIN CỦA SERVER!)
VITE_API_URL=http://YOUR_SERVER_IP:3000
BACKEND_URL=http://backend:3000
```

### 5.3. Deploy

```bash
# Make script executable
chmod +x scripts/deploy-from-registry.sh

# Deploy
./scripts/deploy-from-registry.sh
```

**Hoặc deploy thủ công:**

```bash
# Pull images
docker-compose -f docker-compose.deploy.yml pull

# Start services
docker-compose -f docker-compose.deploy.yml up -d

# Check status
docker-compose -f docker-compose.deploy.yml ps
```

### 5.4. Chạy Database Migrations

```bash
# Vào backend container
docker exec -it ecocheck-backend-prod sh

# Chạy migrations
cd /app/db
PGPASSWORD=$DB_PASSWORD psql -h postgres -p 5432 -U ecocheck_user -d ecocheck -f run_migrations.sh

# Exit
exit
```

---

## Bước 6: Kiểm Tra

### Health Check

```bash
curl http://localhost:3000/health
```

**Expected**: `{"status":"ok",...}`

### Xem Logs

```bash
# Tất cả services
docker-compose -f docker-compose.deploy.yml logs -f

# Chỉ backend
docker-compose -f docker-compose.deploy.yml logs -f backend
```

### Truy Cập Frontend

Mở browser: `http://YOUR_SERVER_IP`

---

## 🔄 Update Deployment

Khi có code mới:

```bash
# 1. Build và push images mới (từ máy dev)
.\scripts\build-and-push-lilweyy5354.ps1

# 2. Trên server, pull images mới
docker-compose -f docker-compose.deploy.yml pull

# 3. Restart services
docker-compose -f docker-compose.deploy.yml up -d
```

---

## 🆘 Troubleshooting

### Lỗi: "unauthorized: authentication required"

**Giải pháp**: Login lại Docker Hub
```powershell
docker login
```

### Lỗi: "image not found"

**Giải pháp**: Kiểm tra images trên Docker Hub đã push chưa

### Lỗi: "port already in use"

**Giải pháp**: Đổi port trong `.env` hoặc stop service đang dùng port

---

## 📞 Support

Nếu gặp vấn đề, kiểm tra:
1. Docker logs: `docker-compose -f docker-compose.deploy.yml logs`
2. Container status: `docker-compose -f docker-compose.deploy.yml ps`
3. Docker Hub: https://hub.docker.com/u/lilweyy5354

---

**Chúc bạn deploy thành công! 🎉**


