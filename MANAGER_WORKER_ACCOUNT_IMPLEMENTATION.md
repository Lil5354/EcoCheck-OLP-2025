# Triển khai Tạo Tài Khoản Nhân Viên - Manager Role

## Tổng quan

Đã triển khai thành công tính năng tạo tài khoản nhân viên cho role Manager, đảm bảo liên kết giữa Backend và Mobile App.

## Các thay đổi đã thực hiện

### 1. Database Migration ✅

**File:** `db/migrations/009_add_user_id_to_personnel.sql`

- Thêm cột `user_id` vào bảng `personnel` để liên kết với bảng `users`
- Tạo index cho hiệu suất truy vấn
- Cho phép nhân viên đăng nhập qua mobile app

### 2. Backend API ✅

**File:** `backend/src/index.js`

#### 2.1. Cập nhật API Login
- **Endpoint:** `POST /api/auth/login`
- **Hỗ trợ:** Cả email và phone để đăng nhập
- **Response:** Bao gồm thông tin personnel nếu user là worker
- **Tương thích:** Mobile app có thể đăng nhập bằng email

#### 2.2. API Manager - Personnel Management

**GET `/api/manager/personnel`**
- Lấy danh sách tất cả nhân viên
- Query params: `role`, `status`, `depot_id`
- Response: Danh sách personnel với thông tin user

**POST `/api/manager/personnel`** ⭐
- Tạo tài khoản nhân viên mới
- **Request Body:**
  ```json
  {
    "name": "Nguyễn Văn A",
    "email": "worker@ecocheck.com",
    "phone": "0901234567",
    "password": "123456",
    "role": "driver" | "collector",
    "depot_id": "uuid",
    "certifications": []
  }
  ```
- **Quy trình:**
  1. Tạo user account với `role='worker'`
  2. Tạo personnel record
  3. Link user và personnel qua `user_id`
  4. Return credentials để manager cung cấp cho worker

**PUT `/api/manager/personnel/:id`**
- Cập nhật thông tin nhân viên
- Tự động cập nhật user account nếu email/phone thay đổi

**DELETE `/api/manager/personnel/:id`**
- Soft delete: Set status = 'inactive'
- Tự động deactivate user account

#### 2.3. API Master - Depots

**GET `/api/master/depots`**
- Lấy danh sách tất cả depots active
- Sử dụng cho dropdown trong form tạo worker

### 3. Frontend Web Manager ✅

**File:** `frontend-web-manager/src/pages/master/Personnel.jsx`

**Tính năng:**
- ✅ Load danh sách nhân viên từ API
- ✅ Form tạo worker với đầy đủ fields:
  - Họ tên (required)
  - Email (required, unique)
  - Số điện thoại (optional)
  - Mật khẩu (required, min 6 chars)
  - Vai trò: Tài xế / Nhân viên thu gom
  - Trạm thu gom (required)
- ✅ Hiển thị credentials sau khi tạo thành công
- ✅ Edit và Delete (soft delete) nhân viên
- ✅ Validation và error handling

**File:** `frontend-web-manager/src/lib/api.js`

- Thêm các functions:
  - `getPersonnel()`
  - `createWorker()`
  - `updateWorker()`
  - `deleteWorker()`
  - `getDepots()`

### 4. Mobile App Integration ✅

**Files:**
- `frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart`
- `frontend-mobile/EcoCheck_Worker/lib/data/services/api_client.dart`
- `frontend-mobile/EcoCheck_Worker/lib/data/repositories/auth_repository.dart`

**Tính năng:**
- ✅ API Client với HTTP support
- ✅ Auth Repository kết nối với backend API
- ✅ Login bằng email (tương thích với backend)
- ✅ Fallback to mock data nếu API không khả dụng (cho development)
- ✅ Lưu credentials vào SharedPreferences

## Luồng hoạt động

### Tạo tài khoản nhân viên:

1. **Manager** mở trang "Nhân sự" trên Web Manager
2. Click "Tạo tài khoản nhân viên"
3. Điền form:
   - Họ tên, Email, SĐT (optional), Mật khẩu
   - Chọn Vai trò (driver/collector)
   - Chọn Trạm thu gom
4. Submit → Backend tạo:
   - User account (role='worker')
   - Personnel record
   - Link qua user_id
5. Hiển thị credentials cho manager
6. Manager cung cấp credentials cho worker

### Worker đăng nhập trên Mobile App:

1. Worker mở app, nhập email và password
2. App gọi `POST /api/auth/login` với `{email, password}`
3. Backend:
   - Tìm user theo email
   - Verify password
   - Lấy personnel info nếu role='worker'
   - Return user + personnel data
4. App lưu credentials và chuyển đến dashboard

## API Endpoints Summary

### Authentication
- `POST /api/auth/login` - Login (email hoặc phone)
- `GET /api/auth/me` - Get current user

### Manager - Personnel
- `GET /api/manager/personnel` - List all personnel
- `POST /api/manager/personnel` - Create worker account
- `PUT /api/manager/personnel/:id` - Update personnel
- `DELETE /api/manager/personnel/:id` - Deactivate personnel

### Master Data
- `GET /api/master/depots` - List all depots

## Testing

### Test tạo worker account:

```bash
# 1. Tạo worker account
curl -X POST http://localhost:3000/api/manager/personnel \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nguyễn Văn Test",
    "email": "test.worker@ecocheck.com",
    "phone": "0901234567",
    "password": "123456",
    "role": "driver",
    "depot_id": "<depot_uuid>"
  }'

# 2. Test login với email
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.worker@ecocheck.com",
    "password": "123456"
  }'
```

### Test trên Web Manager:

1. Truy cập: http://localhost:3001/master/personnel
2. Click "Tạo tài khoản nhân viên"
3. Điền form và submit
4. Kiểm tra credentials được hiển thị

### Test trên Mobile App:

1. Mở EcoCheck_Worker app
2. Nhập email và password đã tạo
3. Kiểm tra đăng nhập thành công

## Cấu hình Mobile App

**File:** `frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart`

Cập nhật `baseUrl` theo môi trường:
- **Android Emulator:** `http://10.0.2.2:3000`
- **iOS Simulator:** `http://localhost:3000`
- **Real Device:** `http://<YOUR_LOCAL_IP>:3000`

## Lưu ý quan trọng

1. **Password Security:** Hiện tại password được lưu plain text. Trong production cần hash bằng bcrypt.
2. **JWT Token:** API hiện chưa có JWT authentication. Cần thêm trong production.
3. **Manager Authorization:** Middleware `requireManager` hiện cho phép nếu không có auth header (development mode).
4. **Depots:** Cần có ít nhất 1 depot trong database để tạo worker.

## Next Steps

1. ✅ Tạo tài khoản nhân viên - **HOÀN THÀNH**
2. ⏭️ Hiển thị lịch thu gom từ người dân
3. ⏭️ Gán nhân viên cho lịch thu gom
4. ⏭️ NGSI-LD integration cho schedules

## Files Modified

### Backend
- `backend/src/index.js` - Thêm Manager API và cập nhật Login API
- `db/migrations/009_add_user_id_to_personnel.sql` - Migration mới

### Frontend Web
- `frontend-web-manager/src/pages/master/Personnel.jsx` - Cải thiện form và logic
- `frontend-web-manager/src/lib/api.js` - Thêm Manager API functions

### Mobile App
- `frontend-mobile/EcoCheck_Worker/lib/core/constants/api_constants.dart` - Mới
- `frontend-mobile/EcoCheck_Worker/lib/data/services/api_client.dart` - Mới
- `frontend-mobile/EcoCheck_Worker/lib/data/repositories/auth_repository.dart` - Cập nhật để dùng API thật

---

**Status:** ✅ HOÀN THÀNH - Sẵn sàng test và sử dụng

