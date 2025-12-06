# ✅ AI Integration Hoàn Thành

## Tổng Quan

Đã tích hợp thành công AI phân tích ảnh rác thải vào hệ thống EcoCheck, cho phép tự động điền form check-in khi user chụp/upload ảnh.

## Các Thay Đổi Đã Thực Hiện

### 1. Backend - AI Service ✅
- **File mới**: `backend/src/services/ai_analyzer.js`
  - Sử dụng Hugging Face Inference API
  - Model: `google/vit-base-patch16-224` (Vision Transformer)
  - Fallback: `facebook/detr-resnet-50` (Object Detection)
  - Phân tích ảnh và trích xuất:
    - `waste_type`: household, recyclable, bulky, organic, hazardous
    - `estimated_weight_kg`: ước tính khối lượng (kg)
    - `weight_category`: small, medium, large

### 2. Backend - API Endpoints ✅
- **POST `/api/ai/analyze-image`**
  - Input: `{ "image_url": "..." }`
  - Output: `{ "ok": true, "data": { "waste_type", "estimated_weight_kg", "weight_category", "confidence" } }`
  
- **POST `/api/user/checkin`**
  - Input: `{ "user_id", "waste_type", "filling_level", "estimated_weight_kg", "photo_url", "latitude", "longitude", "address" }`
  - Tự động tạo/update point tại vị trí check-in
  - Tự động tính điểm gamification
  - Emit realtime event qua Socket.IO

### 3. Environment Variables ✅
- **File**: `backend/env.example`
  - Thêm `HUGGINGFACE_API_TOKEN=your_huggingface_api_token_here`

### 4. Mobile App ✅
- **File**: `frontend-mobile/EcoCheck_User/lib/presentation/pages/checkin/checkin_page.dart`
  - Đã có sẵn code gọi AI API
  - Tự động upload ảnh và phân tích
  - Tự động điền form sau khi AI phân tích xong
  - User có thể chỉnh sửa thông tin nếu cần

## Luồng Hoạt Động

1. **User chụp/chọn ảnh** → Mobile app
2. **Upload ảnh** → Backend `/api/upload` → Trả về `image_url`
3. **Phân tích AI** → Backend `/api/ai/analyze-image` với `image_url`
   - AI service download ảnh từ URL
   - Gửi đến Hugging Face API để phân tích
   - Trích xuất thông tin: waste_type, weight
4. **Tự động điền form** → Mobile app nhận kết quả và điền vào form
5. **User submit check-in** → Backend `/api/user/checkin`
   - Lưu vào database (bảng `checkins`)
   - Tạo/update point tại vị trí
   - Tính điểm gamification
   - Emit realtime event

## Database

- **Bảng `checkins`**: Lưu thông tin check-in
- **Bảng `points`**: Lưu điểm thu gom rác
- **Bảng `user_points`**: Tính điểm cho user
- **Bảng `point_transactions`**: Lịch sử giao dịch điểm

Tất cả đều sử dụng **chung một database** (PostgreSQL) cho cả mobile và web.

## Cách Khởi Chạy

### Option 1: Sử dụng Script (Khuyến nghị)
```powershell
.\scripts\start-ai-integration.ps1
```

### Option 2: Manual

1. **Start Database**:
   ```powershell
   docker-compose up -d postgres
   ```

2. **Setup Backend**:
   ```powershell
   cd backend
   # Copy env.example to .env if not exists
   if (-not (Test-Path .env)) { Copy-Item env.example .env }
   npm install
   npm start
   ```

3. **Start Mobile App**:
   ```powershell
   cd frontend-mobile/EcoCheck_User
   flutter run
   ```

## Testing

### Test AI Analysis
```bash
curl -X POST http://localhost:3000/api/ai/analyze-image \
  -H "Content-Type: application/json" \
  -d "{\"image_url\": \"YOUR_IMAGE_URL\"}"
```

### Test User Check-in
```bash
curl -X POST http://localhost:3000/api/user/checkin \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"test-user-id\",
    \"waste_type\": \"household\",
    \"filling_level\": 0.5,
    \"estimated_weight_kg\": 2.0,
    \"photo_url\": \"https://example.com/image.jpg\",
    \"latitude\": 10.7769,
    \"longitude\": 106.6958,
    \"address\": \"Test Address\"
  }"
```

## Lưu Ý

1. **Hugging Face Token**: Đã được cấu hình trong `env.example`. Đảm bảo copy vào `.env` khi chạy.
2. **Database**: Cần chạy PostgreSQL trước (qua Docker hoặc local).
3. **Mobile App**: Cần cấu hình đúng base URL:
   - Android emulator: `http://10.0.2.2:3000`
   - iOS simulator: `http://localhost:3000`
4. **AI Model**: Hiện tại sử dụng model tổng quát. Có thể cải thiện bằng cách:
   - Fine-tune model trên dataset rác thải Việt Nam
   - Sử dụng model chuyên biệt cho waste classification

## Cải Tiến Tương Lai

- [ ] Fine-tune AI model trên dataset rác thải Việt Nam
- [ ] Thêm confidence score chi tiết hơn
- [ ] Cache kết quả phân tích để tối ưu performance
- [ ] Thêm batch processing cho nhiều ảnh cùng lúc
- [ ] Tích hợp với model object detection để nhận diện từng loại rác trong ảnh

## Tác Giả

Lil5354 - MIT License 2025

