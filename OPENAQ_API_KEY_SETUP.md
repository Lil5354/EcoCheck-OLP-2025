# Hướng Dẫn Lấy OpenAQ API Key

## ✅ Trạng Thái Hiện Tại

Hệ thống đã được cập nhật để sử dụng **OpenAQ API v3** với API key authentication. 

**Lưu ý:** OpenAQ API v2 đã bị retired (ngừng hoạt động). Hệ thống hiện sử dụng v3 và yêu cầu API key.

## 📝 Các Bước Lấy OpenAQ API Key

### Bước 1: Đăng Ký Tài Khoản OpenAQ

1. Truy cập: **https://explore.openaq.org/register**
2. Điền thông tin đăng ký:
   - Email
   - Mật khẩu
   - Tên người dùng
3. Xác nhận email (nếu yêu cầu)

### Bước 2: Lấy API Key

1. Sau khi đăng nhập, truy cập: **https://explore.openaq.org/account**
2. Tìm phần **"API Keys"** hoặc **"Your API Key"**
3. Copy API key của bạn (sẽ có dạng như: `abc123def456ghi789...`)

### Bước 3: Cấu Hình API Key Trong Dự Án

1. Mở file: `backend/.env` (nếu chưa có, copy từ `backend/env.example`)
2. Thêm hoặc cập nhật dòng:
   ```env
   AIRQUALITY_API_KEY=your_openaq_api_key_here
   ```
3. Thay `your_openaq_api_key_here` bằng API key thực tế của bạn

### Bước 4: Khởi Động Lại Backend

Sau khi cấu hình API key, khởi động lại backend server:

```powershell
# Dừng backend hiện tại (Ctrl+C trong terminal backend)
# Sau đó chạy lại:
cd backend
npm run dev
```

## ✅ Kiểm Tra

Sau khi cấu hình, kiểm tra logs trong terminal backend:

**Nếu thành công:**
```
[AirQuality] 🔍 Fetching data for 10.78, 106.70 with radius 50km...
[AirQuality] ✅ Found data from OpenAQ: [Tên trạm], distance: X.Xkm, PM2.5: XX.X
```

**Nếu chưa có API key:**
```
[AirQuality] ⚠️ No OpenAQ API key found. Please set AIRQUALITY_API_KEY in .env file.
```

**Nếu API key sai:**
```
[AirQuality] ❌ API Key authentication failed. Please check your API key.
```

## 🔗 Liên Kết Hữu Ích

- **Đăng ký OpenAQ**: https://explore.openaq.org/register
- **Tài khoản/API Key**: https://explore.openaq.org/account
- **Tài liệu API v3**: https://docs.openaq.org/
- **Hướng dẫn sử dụng API Key**: https://docs.openaq.org/using-the-api/api-key

## 📌 Lưu Ý

1. **Bảo mật API Key**: Không commit API key vào Git. File `.env` đã được thêm vào `.gitignore`
2. **Rate Limits**: OpenAQ có giới hạn số lượng requests. Code đã có retry mechanism và delay để tránh vượt quá limit
3. **Dữ liệu TPHCM**: Có thể không có nhiều trạm quan trắc tại TPHCM. Code sẽ tự động tìm trong bán kính lớn (50km → 100km → 250km)

## 🆘 Nếu Vẫn Không Hoạt Động

1. Kiểm tra API key có đúng không
2. Kiểm tra file `.env` có được load đúng không
3. Xem logs trong terminal backend để biết lỗi cụ thể
4. Thử test API trực tiếp với curl:
   ```bash
   curl -H "X-API-Key: YOUR_API_KEY" "https://api.openaq.org/v3/latest?coordinates=10.7769,106.7009&radius=50000&limit=5"
   ```


