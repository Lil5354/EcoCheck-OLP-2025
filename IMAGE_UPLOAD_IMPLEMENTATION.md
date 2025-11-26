# IMAGE UPLOAD & PHOTO VERIFICATION IMPLEMENTATION

## Tóm tắt
Đã hoàn thiện logic chụp ảnh bắt buộc cho checkin và báo cáo ở cả 2 app (User & Worker), kết nối với backend để lưu ảnh vào database.

## ✅ Backend Changes

### 1. Image Upload API
**File:** `backend/src/index.js`

- ✅ Cài đặt `multer` package để xử lý multipart/form-data
- ✅ Tạo folder `public/uploads` để lưu ảnh
- ✅ Configure multer với:
  - Image validation (JPEG, PNG, WebP only)
  - File size limit: 5MB
  - Unique filename generation
  
**Endpoints mới:**
```javascript
POST /api/upload              // Upload single image
POST /api/upload/multiple     // Upload multiple images (max 5)
```

**Response:**
```json
{
  "success": true,
  "url": "http://localhost:3000/uploads/image-1234567890.jpg",
  "filename": "image-1234567890.jpg",
  "size": 102400,
  "mimetype": "image/jpeg"
}
```

### 2. Check-in API Update
**File:** `backend/src/index.js`, `backend/src/realtime.js`

- ✅ Thêm parameter `image_url` (required)
- ✅ Validate bắt buộc phải có ảnh khi checkin
- ✅ Lưu image_url vào realtime store

**Request:**
```json
{
  "route_id": "R001",
  "point_id": "P123",
  "vehicle_id": "V001",
  "image_url": "http://localhost:3000/uploads/checkin-1234.jpg"
}
```

### 3. Incidents API Update
**File:** `backend/src/index.js`

- ✅ Validate bắt buộc phải có ít nhất 1 ảnh
- ✅ Lưu array `image_urls` vào database

**Request:**
```json
{
  "reporter_id": "user123",
  "report_category": "violation",
  "type": "illegal_dump",
  "description": "Rác thải chất đống...",
  "latitude": 10.762622,
  "longitude": 106.660172,
  "location_address": "123 Nguyễn Huệ, Q1",
  "image_urls": [
    "http://localhost:3000/uploads/report-1.jpg",
    "http://localhost:3000/uploads/report-2.jpg"
  ],
  "priority": "medium"
}
```

## ✅ User App Changes

### 1. Image Upload Service
**File:** `lib/data/services/image_upload_service.dart`

Features:
- ✅ Compress ảnh trước khi upload (quality 70%, max 1024x1024)
- ✅ Upload single/multiple images
- ✅ Error handling
- ✅ Return public URL

Dependencies thêm vào `pubspec.yaml`:
```yaml
http: ^1.1.0
flutter_image_compress: ^2.1.0
path_provider: ^2.1.1
path: ^1.8.3
```

### 2. Create Report Dialog Update
**File:** `lib/presentation/widgets/report/create_report_dialog.dart`

Changes:
- ✅ Import `ImageUploadService`
- ✅ Thêm biến `_isUploadingImages` để hiển thị loading state
- ✅ **Validate bắt buộc phải có ít nhất 1 ảnh**
- ✅ Upload ảnh lên server trước khi submit
- ✅ Hiển thị progress "Đang tải ảnh..." / "Đang gửi..."
- ✅ Xóa mock data, sử dụng real image URLs

UI Changes:
```dart
// Label thay đổi
'Hình ảnh * (bắt buộc, tối đa 5 ảnh)'
'Vui lòng chụp ảnh hiện trường để xác nhận'

// Validation
if (_images.isEmpty) {
  return error: 'Vui lòng chụp ít nhất 1 ảnh để xác nhận'
}

// Upload flow
final imageUrls = await _imageUploadService.uploadMultipleImages(_images);
```

## ✅ Worker App Changes

### 1. Image Upload Service
**File:** `lib/data/services/image_upload_service.dart`

- ✅ Copy từ User app
- ✅ Cài đặt dependencies (http, flutter_image_compress, path_provider, path)

### 2. Complete Task Dialog Update
**File:** `lib/presentation/widgets/route/complete_task_dialog.dart`

Changes:
- ✅ Import `ImageUploadService` và `dart:io`
- ✅ Thêm biến `_isUploading`
- ✅ **Validate bắt buộc phải có ít nhất 1 ảnh**
- ✅ Convert XFile → File và upload lên server
- ✅ Hiển thị loading "Đang tải ảnh..."
- ✅ Success message sau khi upload thành công

```dart
// Validation
if (_images.isEmpty) {
  return error: 'Vui lòng chụp ít nhất 1 ảnh để xác nhận hoàn thành'
}

// Upload flow
final files = _images.map((xFile) => File(xFile.path)).toList();
final imageUrls = await _imageUploadService.uploadMultipleImages(files);

// TODO: Send imageUrls to backend API for checkin
```

### 3. Report Feature
**Files:** `lib/presentation/pages/report/`, `lib/presentation/widgets/report/`

- ✅ Copy toàn bộ report feature từ User app
- ✅ Bao gồm: `report_screen.dart`, `create_report_dialog.dart`, `report_card.dart`
- ✅ Tích hợp ImageUploadService giống User app

## 📝 TODO: Backend Integration

### Cần cập nhật sau:
1. **Worker Checkin API:** Gửi image_url khi call API checkin
2. **User Report API:** Call POST /api/incidents với image_urls đã upload
3. **Display Images:** Hiển thị ảnh đã lưu trong database

## 🧪 Testing Checklist

### User App - Report Feature
- [ ] Chụp ảnh bằng camera
- [ ] Chọn ảnh từ thư viện
- [ ] Xóa ảnh đã chọn
- [ ] Validate: Không cho submit khi chưa có ảnh
- [ ] Upload thành công và nhận được URL
- [ ] Hiển thị loading state khi upload
- [ ] Error handling khi upload fail

### Worker App - Checkin
- [ ] Bắt buộc phải chụp ảnh mới complete task
- [ ] Upload ảnh thành công
- [ ] Hiển thị "Đang tải ảnh..."
- [ ] Success message sau khi upload

### Worker App - Report
- [ ] Giống User app
- [ ] 2 tabs: Vi phạm / Hư hỏng
- [ ] Upload multiple images

### Backend
- [ ] POST /api/upload - single image
- [ ] POST /api/upload/multiple - multiple images
- [ ] File size validation (max 5MB)
- [ ] File type validation (JPEG, PNG, WebP)
- [ ] Return correct public URL
- [ ] Static file serving: http://localhost:3000/uploads/[filename]

## 📦 Deployment Notes

### Docker Volume
Cần mount volume để lưu uploaded images:
```yaml
# docker-compose.yml
services:
  backend:
    volumes:
      - ./backend/public/uploads:/app/public/uploads
```

### Nginx (Production)
Cấu hình serve static files:
```nginx
location /uploads/ {
    alias /var/www/ecocheck/uploads/;
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### Environment Variables
```env
# .env
BACKEND_URL=http://localhost:3000
# Trong production: https://api.ecocheck.vn
```

## 🔐 Security Considerations

1. **File Validation:**
   - ✅ Kiểm tra MIME type
   - ✅ Giới hạn file size (5MB)
   - ⚠️ TODO: Scan virus/malware
   - ⚠️ TODO: Image dimension validation

2. **Rate Limiting:**
   - ⚠️ TODO: Giới hạn số lượng upload/user/day
   - ⚠️ TODO: IP-based rate limiting

3. **Storage:**
   - ✅ Unique filename để tránh conflict
   - ⚠️ TODO: Cleanup old files (retention policy)
   - ⚠️ TODO: Move to cloud storage (S3, Cloudinary)

## 📊 Performance Optimizations

1. **Image Compression:**
   - ✅ Client-side: quality 70%, max 1024x1024
   - ⚠️ TODO: Server-side: generate thumbnails
   - ⚠️ TODO: WebP conversion for better compression

2. **CDN:**
   - ⚠️ TODO: Serve images through CDN
   - ⚠️ TODO: Image optimization pipeline

## 🎯 Next Steps

1. **Immediate:**
   - Test upload flow end-to-end
   - Fix Worker app import paths nếu còn lỗi
   - Test trên real device (Android/iOS)

2. **Short-term:**
   - Integrate real API calls (thay mock data)
   - Add image preview trong report detail
   - Add image gallery viewer

3. **Long-term:**
   - Move to cloud storage (AWS S3 / Cloudinary)
   - Implement image processing pipeline
   - Add OCR for automatic damage detection
