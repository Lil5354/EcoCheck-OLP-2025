# Hướng dẫn Deploy EcoCheck lên Render

## Tổng quan
Hướng dẫn này sẽ giúp bạn deploy EcoCheck (Frontend + Backend + Nginx) lên Render sử dụng:
- **PostgreSQL Database** (tự động tạo từ render.yaml)
- **Web Service** với Docker (unified container chứa cả frontend, backend và nginx)

---

## Các file đã được tạo

1. **Dockerfile.render** - Dockerfile để build unified container
2. **render.yaml** - Blueprint config để tạo database và web service
3. **nginx.render.conf** - Nginx config cho Render
4. **generate-nginx-config-render.sh** - Script generate nginx config với PORT động
5. **start.render.sh** - Script khởi động service
6. **supervisord.conf** - Config supervisor để chạy nginx + backend

---

## BƯỚC 1: Push code lên GitHub

### 1.1. Commit và push branch DRender

```bash
# Đảm bảo bạn đang ở branch DRender
git checkout DRender

# Thêm tất cả file mới
git add Dockerfile.render render.yaml nginx.render.conf generate-nginx-config-render.sh start.render.sh supervisord.conf

# Commit
git commit -m "feat: Add Render deployment configuration"

# Push lên GitHub
git push origin DRender
```

**✅ Kiểm tra:** Vào GitHub, đảm bảo branch `DRender` có đầy đủ các file trên.

---

## BƯỚC 2: Đăng nhập vào Render

### 2.1. Tạo tài khoản Render (nếu chưa có)

1. Truy cập: https://render.com
2. Click **"Get Started for Free"** hoặc **"Sign Up"**
3. Đăng nhập bằng GitHub account (khuyến nghị)

### 2.2. Kết nối GitHub Repository

1. Sau khi đăng nhập, vào **Dashboard**
2. Click **"New +"** → **"Blueprint"** (hoặc vào **Blueprints**)
3. Render sẽ yêu cầu kết nối GitHub repository:
   - Nếu chưa kết nối: Click **"Connect GitHub"** hoặc **"Configure GitHub"**
   - Chọn repository: `EcoCheck-OLP-2025`
   - Chọn branch: `DRender`
   - Cấp quyền cần thiết

**✅ Kiểm tra:** Repository đã được kết nối và hiển thị trong Render dashboard.

---

## BƯỚC 3: Deploy bằng Blueprint (render.yaml)

### 3.1. Tạo Blueprint từ render.yaml

1. Trong Render Dashboard, click **"New +"** → **"Blueprint"**
2. Chọn repository: `EcoCheck-OLP-2025`
3. Chọn branch: `DRender`
4. Render sẽ tự động detect file `render.yaml`
5. Click **"Apply"** để bắt đầu deploy

**⚠️ LƯU Ý:** Render sẽ:
- Tạo PostgreSQL database service (ecocheck-database)
- Tạo Web service (ecocheck-web) với Docker
- Tự động set các environment variables từ database service

### 3.2. Đợi build hoàn tất

Render sẽ:
1. Pull code từ GitHub
2. Build Docker image từ `Dockerfile.render`
3. Start PostgreSQL database
4. Deploy web service
5. Chạy migrations tự động

**⏱️ Thời gian:** Khoảng 5-10 phút cho lần đầu tiên

**✅ Kiểm tra:** 
- Vào **Services** tab → Xem logs của cả 2 services
- Database service: Status phải là **"Active"**
- Web service: Status phải là **"Live"** (sau khi build xong)

---

## BƯỚC 4: Kiểm tra và cấu hình (nếu cần)

### 4.1. Kiểm tra Logs

1. Vào **Dashboard** → Click vào service **ecocheck-web**
2. Click tab **"Logs"**
3. Kiểm tra:
   - ✅ Nginx đã start: `Starting nginx...`
   - ✅ Backend đã start: `Starting EcoCheck Backend...`
   - ✅ Migrations đã chạy: `Migrations complete.`
   - ✅ Không có lỗi: No ERROR messages

**❌ Nếu có lỗi:**
- Copy log lỗi và kiểm tra phần **Troubleshooting** ở cuối guide

### 4.2. Kiểm tra Health Check

1. Trong service **ecocheck-web**, xem **"Health Check Status"**
2. Phải hiển thị: **"Healthy"** (green)
3. Health endpoint: `https://your-app.onrender.com/health`

**✅ Test thủ công:**
```bash
curl https://your-app.onrender.com/health
# Phải return: {"status":"OK","service":"nginx","ready":true,"port":"10000"}
```

### 4.3. Kiểm tra Database Connection

1. Vào service **ecocheck-database**
2. Tab **"Info"** → Copy **Internal Database URL** hoặc **Connection String**
3. Kiểm tra trong web service logs xem có kết nối database thành công không

**✅ Kiểm tra trong logs:**
```
Database config: ecocheck_user@dpg-xxxxx:5432/ecocheck
✓ Database is ready.
```

---

## BƯỚC 5: Cấu hình Environment Variables (tùy chọn)

### 5.1. Thêm Custom Environment Variables

Nếu cần thêm biến môi trường (ví dụ: API keys, external services):

1. Vào service **ecocheck-web**
2. Tab **"Environment"**
3. Click **"Add Environment Variable"**
4. Thêm các biến cần thiết:
   - `ORION_LD_URL` (nếu dùng FIWARE Orion external)
   - `SECRET_KEY` (nếu cần)
   - Các biến khác...

### 5.2. Các biến đã được tự động set từ render.yaml:

✅ `DATABASE_URL` - Connection string từ PostgreSQL service  
✅ `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` - Database details  
✅ `NODE_ENV=production`  
✅ `PORT=10000` - Port cho nginx  
✅ `BACKEND_PORT=3000` - Port cho backend (internal)  

**⚠️ KHÔNG CẦN** set lại các biến này, Render đã tự động làm.

---

## BƯỚC 6: Test ứng dụng

### 6.1. Kiểm tra Frontend

1. Copy **Public URL** của service **ecocheck-web**
2. Mở trình duyệt và truy cập URL đó
3. Frontend phải load được (React app)

### 6.2. Kiểm tra Backend API

```bash
# Test health endpoint
curl https://your-app.onrender.com/health

# Test API endpoint (nếu có)
curl https://your-app.onrender.com/api/health
# hoặc
curl https://your-app.onrender.com/api/personnel
```

**✅ Kiểm tra:**
- Frontend load được
- API endpoints trả về dữ liệu
- Không có CORS errors trong browser console

---

## BƯỚC 7: Cấu hình Custom Domain (tùy chọn)

### 7.1. Thêm Custom Domain

1. Vào service **ecocheck-web**
2. Tab **"Settings"** → Scroll xuống **"Custom Domains"**
3. Click **"Add"**
4. Nhập domain của bạn (ví dụ: `ecocheck.example.com`)
5. Render sẽ cung cấp DNS records để thêm vào DNS provider

### 7.2. Cấu hình DNS

1. Vào DNS provider (Cloudflare, Namecheap, etc.)
2. Thêm CNAME record:
   - **Name:** `ecocheck` (hoặc subdomain bạn muốn)
   - **Value:** URL Render cung cấp (ví dụ: `ecocheck-web.onrender.com`)
3. Đợi DNS propagate (5-30 phút)
4. Render sẽ tự động cấp SSL certificate

---

## Troubleshooting

### ❌ Lỗi: Build failed - Cannot find module

**Nguyên nhân:** Dependencies chưa được install đúng

**Giải pháp:**
1. Kiểm tra `package.json` và `package-lock.json` có trong repo
2. Xem build logs để tìm module nào thiếu
3. Đảm bảo `npm ci` chạy thành công trong Dockerfile

---

### ❌ Lỗi: Database connection failed

**Nguyên nhân:** Database chưa ready hoặc connection string sai

**Giải pháp:**
1. Kiểm tra database service đã **Active** chưa
2. Vào service **ecocheck-database** → Copy **Connection String**
3. Vào service **ecocheck-web** → Tab **Environment** → Kiểm tra `DATABASE_URL`
4. Đảm bảo backend đợi database ready (có wait logic trong entrypoint.sh)

---

### ❌ Lỗi: Health check failed

**Nguyên nhân:** Service chưa start hoặc nginx config sai

**Giải pháp:**
1. Xem logs để kiểm tra nginx có start không
2. Kiểm tra PORT environment variable (Render set PORT=10000)
3. Test health endpoint: `curl https://your-app.onrender.com/health`
4. Kiểm tra nginx config có listen đúng port không

---

### ❌ Lỗi: Migrations failed

**Nguyên nhân:** Migration script lỗi hoặc database chưa sẵn sàng

**Giải pháp:**
1. Xem logs để tìm lỗi cụ thể
2. Kiểm tra `/app/db/run_migrations.sh` có được copy vào container không
3. Kiểm tra database user có đủ quyền không
4. Nếu cần, có thể chạy migrations thủ công bằng psql

---

### ❌ Lỗi: Nginx 502 Bad Gateway

**Nguyên nhân:** Backend chưa start hoặc không listen trên port 3000

**Giải pháp:**
1. Kiểm tra backend logs xem có start không
2. Đảm bảo backend listen trên port 3000 (internal)
3. Kiểm tra nginx config proxy_pass đúng `http://127.0.0.1:3000`
4. Kiểm tra supervisor có chạy cả nginx và backend không

---

### ❌ Service bị sleep (Free tier)

**Nguyên nhân:** Render free tier sẽ sleep service sau 15 phút không có traffic

**Giải pháp:**
1. Đây là hành vi bình thường của free tier
2. Service sẽ tự động wake up khi có request (mất ~30 giây)
3. Upgrade lên paid plan nếu cần service luôn online

---

## Tóm tắt checklist

- [ ] ✅ Code đã push lên GitHub branch `DRender`
- [ ] ✅ Render account đã tạo và kết nối GitHub
- [ ] ✅ Blueprint đã được apply (tạo database + web service)
- [ ] ✅ Build hoàn tất không lỗi
- [ ] ✅ Database service status: **Active**
- [ ] ✅ Web service status: **Live**
- [ ] ✅ Health check: **Healthy**
- [ ] ✅ Frontend load được
- [ ] ✅ Backend API hoạt động
- [ ] ✅ Logs không có ERROR

---

## Liên kết hữu ích

- Render Documentation: https://render.com/docs
- Render Docker Guide: https://render.com/docs/docker
- Render Blueprint: https://render.com/docs/blueprint-spec
- Render Environment Variables: https://render.com/docs/environment-variables

---

## Hỗ trợ

Nếu gặp vấn đề không giải quyết được:
1. Kiểm tra logs kỹ lưỡng
2. Thử rebuild service (Settings → Clear build cache → Deploy)
3. Kiểm tra render.yaml syntax đúng chưa
4. Xem Render Status Page: https://status.render.com

---

**Chúc bạn deploy thành công! 🚀**

