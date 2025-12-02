# 🆓 Setup Oracle Cloud Free Tier - Server Public Miễn Phí

## ✅ Đáp Ứng Yêu Cầu Của Bạn

- ✅ **Server Public**: Có IP public, truy cập được từ internet
- ✅ **Hoàn Toàn Miễn Phí**: Free forever, không tốn phí
- ✅ **Đủ Mạnh**: Chạy được EcoCheck với Docker

## 📋 Tài Nguyên Free Tier

- **2 VMs** (Virtual Machines)
- Mỗi VM: **1GB RAM**, **1 CPU core**
- **200GB storage** tổng cộng
- **10TB bandwidth** mỗi tháng
- **Public IP** miễn phí
- **Không giới hạn thời gian** (free forever)

---

## 🚀 Bước 1: Đăng Ký Oracle Cloud

### 1.1. Truy Cập Website

1. Mở browser: https://www.oracle.com/cloud/free/
2. Click **"Start for free"** hoặc **"Try Oracle Cloud Free Tier"**

### 1.2. Điền Thông Tin

**Thông tin cần điền:**
- **Email**: Email của bạn
- **Password**: Mật khẩu mạnh
- **Country**: Chọn quốc gia
- **First Name & Last Name**: Tên của bạn

### 1.3. Xác Thực

- Oracle sẽ gửi email xác thực
- Click link trong email để verify

### 1.4. Thông Tin Thanh Toán (Optional)

**Lưu ý quan trọng:**
- Oracle có thể yêu cầu thông tin thẻ tín dụng để **verify identity**
- **KHÔNG charge** nếu bạn chỉ dùng Free Tier
- Nếu lo lắng, có thể dùng thẻ ảo hoặc thẻ có giới hạn

**Nếu không muốn dùng thẻ:**
- Thử đăng ký với email khác
- Hoặc chọn region khác (một số region không yêu cầu thẻ)

---

## 🚀 Bước 2: Tạo VM Instance

### 2.1. Đăng Nhập Console

1. Truy cập: https://cloud.oracle.com/
2. Đăng nhập với tài khoản vừa tạo
3. Chọn **"Create a free autonomous database"** hoặc vào **"Compute"** → **"Instances"**

### 2.2. Tạo Compute Instance

1. Vào menu **☰** (hamburger menu) → **Compute** → **Instances**
2. Click **"Create Instance"**

### 2.3. Cấu Hình Instance

**Name:**
- Đặt tên: `ecocheck-server` (hoặc tên bạn muốn)

**Image:**
- Chọn **"Canonical Ubuntu"** hoặc **"Oracle Linux"**
- Version: **22.04** hoặc **latest**

**Shape:**
- **QUAN TRỌNG**: Chọn **"Always Free Eligible"**
- Chọn: **VM.Standard.A1.Flex** (Ampere)
- **OCPU count**: 1
- **Memory**: 1 GB

**Networking:**
- **Virtual Cloud Network**: Tạo mới hoặc dùng mặc định
- **Subnet**: Tạo mới hoặc dùng mặc định
- **Assign a public IPv4 address**: ✅ **BẬT** (quan trọng!)

**SSH Keys:**
- Chọn **"Generate a key pair for me"** (dễ nhất)
- Hoặc upload SSH key của bạn nếu có

**Boot Volume:**
- Size: **50 GB** (free tier cho phép)
- **Encryption**: Default

### 2.4. Tạo Instance

1. Click **"Create"**
2. Đợi 2-5 phút để instance khởi tạo
3. **Lưu lại**:
   - **Public IP**: Ví dụ `123.45.67.89`
   - **Username**: Thường là `ubuntu` hoặc `opc`
   - **SSH Private Key**: Download và lưu an toàn

---

## 🚀 Bước 3: Kết Nối SSH

### 3.1. Trên Windows

**Option 1: Dùng PowerShell (Windows 10/11)**

```powershell
# Nếu chưa có SSH key, tạo mới
ssh-keygen -t rsa -b 4096

# Kết nối (thay IP và username)
ssh -i path/to/private-key ubuntu@YOUR_PUBLIC_IP
```

**Option 2: Dùng PuTTY**

1. Download PuTTY: https://www.putty.org/
2. Mở PuTTY
3. Host Name: `ubuntu@YOUR_PUBLIC_IP`
4. Connection → SSH → Auth → Browse → Chọn private key
5. Click **"Open"**

### 3.2. Trên Linux/Mac

```bash
# Set quyền cho private key
chmod 400 path/to/private-key

# Kết nối
ssh -i path/to/private-key ubuntu@YOUR_PUBLIC_IP
```

### 3.3. Test Kết Nối

Nếu kết nối thành công, bạn sẽ thấy:
```
Welcome to Ubuntu 22.04...
ubuntu@instance-name:~$
```

---

## 🚀 Bước 4: Cài Đặt Docker

### 4.1. Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### 4.2. Cài Docker

```bash
# Cài dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update và cài Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user vào docker group (để không cần sudo)
sudo usermod -aG docker $USER

# Khởi động Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify
docker --version
docker compose version
```

### 4.3. Logout và Login Lại

```bash
exit
# SSH lại vào server
ssh -i path/to/private-key ubuntu@YOUR_PUBLIC_IP
```

---

## 🚀 Bước 5: Setup Firewall

### 5.1. Mở Ports Cần Thiết

```bash
# Cài ufw (firewall)
sudo apt install -y ufw

# Cho phép SSH
sudo ufw allow 22/tcp

# Cho phép HTTP
sudo ufw allow 80/tcp

# Cho phép HTTPS
sudo ufw allow 443/tcp

# Cho phép Backend API
sudo ufw allow 3000/tcp

# Enable firewall
sudo ufw enable

# Kiểm tra
sudo ufw status
```

### 5.2. Mở Ports Trong Oracle Cloud Console

**QUAN TRỌNG**: Cần mở ports trong Security List của Oracle Cloud!

1. Vào Oracle Cloud Console
2. **Networking** → **Virtual Cloud Networks**
3. Click vào VCN của bạn
4. **Security Lists** → Click vào security list
5. **Ingress Rules** → **Add Ingress Rules**

**Thêm các rules:**

| Source Type | Source CIDR | IP Protocol | Destination Port Range | Description |
|-------------|-------------|-------------|------------------------|-------------|
| CIDR | 0.0.0.0/0 | TCP | 22 | SSH |
| CIDR | 0.0.0.0/0 | TCP | 80 | HTTP |
| CIDR | 0.0.0.0.0/0 | TCP | 443 | HTTPS |
| CIDR | 0.0.0.0/0 | TCP | 3000 | Backend API |

6. Click **"Add Ingress Rules"**

---

## 🚀 Bước 6: Deploy EcoCheck

### 6.1. Clone Repository

```bash
# Cài Git nếu chưa có
sudo apt install -y git

# Clone repo
git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
cd EcoCheck-OLP-2025
git checkout TWeb
```

### 6.2. Tạo File .env

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

# Frontend API URL (THAY BẰNG PUBLIC IP CỦA SERVER!)
VITE_API_URL=http://YOUR_PUBLIC_IP:3000
BACKEND_URL=http://backend:3000
```

**Lưu ý**: Thay `YOUR_PUBLIC_IP` bằng IP thực tế của server!

### 6.3. Deploy

```bash
# Pull images từ Docker Hub
docker compose -f docker-compose.deploy.yml pull

# Start services
docker compose -f docker-compose.deploy.yml up -d

# Check status
docker compose -f docker-compose.deploy.yml ps

# View logs
docker compose -f docker-compose.deploy.yml logs -f
```

### 6.4. Chạy Migrations

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

## ✅ Kiểm Tra Deployment

### Test Backend

```bash
curl http://localhost:3000/health
```

**Expected**: `{"status":"ok",...}`

### Test Frontend

Mở browser: `http://YOUR_PUBLIC_IP`

### Test từ Máy Tính Của Bạn

```bash
# Thay YOUR_PUBLIC_IP bằng IP thực tế
curl http://YOUR_PUBLIC_IP:3000/health
```

---

## 🔧 Troubleshooting

### Lỗi: "Connection refused" khi SSH

**Giải pháp:**
- Kiểm tra Security List đã mở port 22 chưa
- Kiểm tra Public IP đúng chưa
- Đợi 2-3 phút sau khi tạo instance

### Lỗi: "Cannot connect to Docker daemon"

**Giải pháp:**
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
# Logout và login lại
```

### Lỗi: "Port already in use"

**Giải pháp:**
- Kiểm tra port đang dùng: `sudo netstat -tulpn | grep :3000`
- Đổi port trong `.env` hoặc stop service đang dùng

### Không truy cập được từ internet

**Giải pháp:**
- Kiểm tra Security List đã mở ports chưa
- Kiểm tra firewall: `sudo ufw status`
- Kiểm tra Public IP đúng chưa

---

## 📊 Monitoring

### Xem Logs

```bash
# Tất cả services
docker compose -f docker-compose.deploy.yml logs -f

# Chỉ backend
docker compose -f docker-compose.deploy.yml logs -f backend
```

### Xem Resource Usage

```bash
# Docker stats
docker stats

# System resources
htop
# Hoặc
top
```

---

## 🔐 Security Best Practices

1. **Đổi password mặc định**: Luôn đổi password trong `.env`
2. **Không commit .env**: File `.env` đã được ignore
3. **Setup SSL**: Dùng nginx reverse proxy với Let's Encrypt
4. **Regular updates**: Update system và Docker images thường xuyên
5. **Backup**: Backup database thường xuyên

---

## 📝 Tóm Tắt

1. ✅ Đăng ký Oracle Cloud Free Tier
2. ✅ Tạo VM instance với public IP
3. ✅ SSH vào server
4. ✅ Cài Docker và Docker Compose
5. ✅ Mở ports trong Security List và firewall
6. ✅ Clone repository
7. ✅ Tạo `.env` file
8. ✅ Deploy EcoCheck
9. ✅ Chạy migrations
10. ✅ Test services

---

## 🎉 Kết Quả

Sau khi hoàn tất, bạn sẽ có:
- ✅ Server public miễn phí
- ✅ EcoCheck chạy trên internet
- ✅ Truy cập được từ bất kỳ đâu
- ✅ Không tốn phí

**Happy Deploying! 🚀**


