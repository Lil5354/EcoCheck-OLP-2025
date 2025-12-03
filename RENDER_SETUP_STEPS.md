# Hướng dẫn Setup Render - Step by Step

## ⚠️ Lưu Ý Quan Trọng

Render Blueprint **KHÔNG hỗ trợ** tạo database trực tiếp trong `render.yaml`. Bạn cần:
1. **Tạo database thủ công** trong Render Dashboard trước
2. Sau đó dùng Blueprint để deploy web service và link với database

---

## 📋 Các Bước Setup Hoàn Chỉnh

### BƯỚC 1: Tạo PostgreSQL Database Thủ Công

1. Vào **Render Dashboard**
2. Click **"+ New"** → **"Postgres"** (hoặc vào **"New Postgres"**)
3. Điền form:
   - **Name:** `ecocheck-database`
   - **Database:** `ecocheck`
   - **User:** `ecocheck_user`
   - **Region:** Singapore (hoặc region bạn muốn)
   - **PostgreSQL Version:** 15 (mặc định)
   - **Plan:** Starter (Free tier)
4. Click **"Create Database"**
5. Đợi database provisioning xong (~1-2 phút)
6. Status phải là **"Available"** (màu xanh)

**✅ Kiểm tra:** Database service đã được tạo và "Available"

---

### BƯỚC 2: Tạo Blueprint cho Web Service

1. Vào **Dashboard** → Click **"Blueprints"** (sidebar trái)
2. Click **"New Blueprint"**
3. Điền form:
   - **Repository:** `EcoCheck-OLP-2025` (chọn từ dropdown)
   - **Branch:** `DRender`
   - **Blueprint Name:** `EcoCheck-OLP-2025` (hoặc tên bạn muốn)
4. Click **"Apply"** hoặc **"Create Blueprint"**

**✅ Kiểm tra:** 
- Blueprint tạo thành công
- Web service được tạo (chưa link database)

---

### BƯỚC 3: Link Database với Web Service

1. Vào service **`ecocheck-web`** (hoặc tên service Blueprint tạo)
2. Tab **"Settings"** (icon bánh răng)
3. Scroll xuống phần **"Databases"**
4. Click **"Link Database"**
5. Chọn **`ecocheck-database`** từ dropdown
6. Click **"Link"**

**✅ Kiểm tra:**
- Tab **"Environment"** → Có `DATABASE_URL` và các `DB_*` variables

---

### BƯỚC 4: Redeploy Web Service

1. Vào service **`ecocheck-web`**
2. Tab **"Events"** hoặc **"Manual Deploy"**
3. Click **"Clear build cache & deploy"**
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
```

**❌ Nếu vẫn lỗi:**
- Kiểm tra lại Bước 3 (Link Database)
- Kiểm tra tab "Environment" có `DATABASE_URL` không

---

### BƯỚC 6: Test Ứng Dụng

1. **Health Check:**
   - Copy Public URL của service
   - Truy cập: `https://your-url.onrender.com/health`
   - Phải return: `{"status":"OK","service":"nginx","ready":true}`

2. **Frontend:**
   - Truy cập Public URL
   - Frontend phải load được

3. **API:**
   ```bash
   curl https://your-url.onrender.com/api/health
   ```

---

## 🔄 Workflow Hoàn Chỉnh

```
1. Tạo Database (Thủ công)
   ↓
2. Tạo Blueprint (Tự động tạo Web Service)
   ↓
3. Link Database với Web Service (Thủ công)
   ↓
4. Redeploy (Áp dụng link)
   ↓
5. Kiểm tra Logs & Test
```

---

## ❓ FAQ

### Q: Tại sao không thể tạo database trong render.yaml?

**A:** Render Blueprint không hỗ trợ tạo managed databases (PostgreSQL, Redis, etc.) trực tiếp từ `render.yaml`. Bạn phải tạo thủ công trong Dashboard.

### Q: Có cách nào tự động tạo database không?

**A:** Không, bạn phải tạo database thủ công một lần. Sau đó có thể dùng Blueprint để deploy web service và tự động link với database đã tồn tại.

### Q: Nếu tôi đã có database rồi thì sao?

**A:** Chỉ cần làm Bước 2, 3, 4 - tạo Blueprint, link database, và deploy.

---

## ✅ Checklist Hoàn Thành

- [ ] ✅ Database service đã được tạo (thủ công)
- [ ] ✅ Database status = "Available"
- [ ] ✅ Blueprint đã được tạo và apply thành công
- [ ] ✅ Web service đã được tạo từ Blueprint
- [ ] ✅ Web service đã link với database
- [ ] ✅ Environment variables có `DATABASE_URL`
- [ ] ✅ Web service đã redeploy
- [ ] ✅ Logs không còn lỗi
- [ ] ✅ Health check trả về 200
- [ ] ✅ Frontend và API hoạt động

---

**Sau khi hoàn thành các bước trên, ứng dụng sẽ deploy thành công! 🚀**



