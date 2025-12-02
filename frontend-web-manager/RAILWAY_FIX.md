# 🔧 Giải Pháp Nhanh: Lỗi "Dockerfile does not exist" trên Railway

## Nguyên nhân cốt lõi

Railway có thể không đọc `railway.toml` đúng cách khi Root Directory được set, hoặc có conflict giữa cấu hình trong UI và `railway.toml`.

## ✅ Giải pháp (Làm ngay)

### Bước 1: Thêm biến môi trường RAILWAY_DOCKERFILE_PATH

1. Vào Railway Dashboard → Chọn **Frontend Service**
2. Click tab **Variables**
3. Click **"+ New Variable"**
4. Thêm:
   - **Name**: `RAILWAY_DOCKERFILE_PATH`
   - **Value**: `frontend-web-manager/Dockerfile.railway`
5. Click **Add** và **Save**

### Bước 2: Kiểm tra Root Directory

1. Vào tab **Settings** → **Source**
2. Đảm bảo **Root Directory** = `frontend-web-manager` (không có dấu `/` ở đầu/cuối)

### Bước 3: Redeploy

1. Vào tab **Deployments**
2. Click **Redeploy** (hoặc push commit mới)

## ✅ Kết quả mong đợi

Sau khi redeploy, build logs phải có:
- ✅ `FROM node:22-alpine AS build` (frontend)
- ✅ `FROM nginx:alpine` (production stage)
- ❌ KHÔNG có: `RUN apk add --no-cache curl postgresql-client` (backend)
- ❌ KHÔNG có: `COPY backend/entrypoint.sh ./` (backend)

## Lý do

Biến môi trường `RAILWAY_DOCKERFILE_PATH` sẽ **override tất cả** cấu hình khác và buộc Railway dùng đúng Dockerfile, bất kể Root Directory hay cấu hình trong UI.

**Tham khảo**: [Railway Documentation - Dockerfiles](https://docs.railway.com/deploy/dockerfiles)


