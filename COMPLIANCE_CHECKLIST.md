# Compliance Checklist - OLP 2025

Checklist này giúp đảm bảo dự án EcoCheck đáp ứng đầy đủ các tiêu chí chấm điểm của cuộc thi OLP 2025.

## 📋 Checklist Tổng Quan

### ✅ Đã Hoàn Thành

- [x] **Hệ thống quản lý mã nguồn công khai** (GitHub)
- [x] **Giấy phép OSI-approved** (MIT License)
- [x] **Bản sao toàn văn giấy phép** (LICENSE file)
- [x] **Thông báo về mục đích giấy phép** (README + LICENSES.md)
- [x] **Tương thích giấy phép dependencies** (LICENSES.md)
- [x] **Hướng dẫn build từ source** (README - Building from Source)
- [x] **Tài liệu về thư viện** (LICENSES.md)
- [x] **Changelog** (CHANGELOG.md)
- [x] **README** (README.md chi tiết)
- [x] **Cấu trúc repos rõ ràng** (PROJECT_STRUCTURE.md + README)
- [x] **Tài liệu nguồn dữ liệu** (DATA_SOURCES.md)
- [x] **Script tự động thêm license headers** (scripts/add-license-headers.*)
- [x] **Hướng dẫn tạo GitHub Release** (GITHUB_RELEASE_GUIDE.md)
- [x] **Environment variables examples** (env.example files)

### ⚠️ Cần Hoàn Thành Trước Khi Nộp Bài

#### 1. License Headers trong Code (Ưu tiên cao)

- [ ] **Chạy script thêm license headers vào Mobile apps:**
  ```powershell
  .\scripts\add-license-headers.ps1
  ```
  Hoặc:
  ```bash
  chmod +x scripts/add-license-headers.sh
  ./scripts/add-license-headers.sh
  ```

- [ ] **Chạy script thêm license headers vào Frontend Web:**
  ```powershell
  .\scripts\add-license-headers-web.ps1
  ```
  Hoặc:
  ```bash
  chmod +x scripts/add-license-headers-web.sh
  ./scripts/add-license-headers-web.sh
  ```

- [ ] **Kiểm tra lại:**
  - Tất cả file `.dart` trong `frontend-mobile/*/lib/` đã có license header
  - Tất cả file `.jsx`, `.js` trong `frontend-web-manager/src/` đã có license header
  - Tất cả file `.js` trong `backend/src/` đã có license header

**Rủi ro nếu không làm**: -10 PoF

#### 2. Tạo GitHub Release (Ưu tiên cao)

- [ ] **Tạo Git tag:**
  ```bash
  git tag -a v1.0.0 -m "EcoCheck v1.0.0 - Initial Release for OLP 2025"
  git push origin v1.0.0
  ```

- [ ] **Tạo GitHub Release:**
  - Truy cập: https://github.com/Lil5354/EcoCheck-OLP-2025/releases/new
  - Chọn tag: `v1.0.0`
  - Title: `EcoCheck v1.0.0 - Initial Release for OLP 2025`
  - Description: Copy từ `RELEASE_NOTES.md`
  - Click "Publish release"

**📖 Xem thêm**: [GITHUB_RELEASE_GUIDE.md](GITHUB_RELEASE_GUIDE.md)

**Rủi ro nếu không làm**: -50 PoF

**⚠️ QUAN TRỌNG**: Phải tạo release **TRƯỚC** 17:00 Thứ 2 ngày 08/12/2025

#### 3. Xác Nhận GitHub Issues Được Bật (Ưu tiên cao)

- [ ] **Kiểm tra Repository Settings:**
  - Vào: https://github.com/Lil5354/EcoCheck-OLP-2025/settings
  - Mục **General** → **Features**
  - Đảm bảo **Issues** được bật (checkbox checked)

- [ ] **Kiểm tra Issues hoạt động:**
  - Truy cập: https://github.com/Lil5354/EcoCheck-OLP-2025/issues
  - Đảm bảo có thể tạo issue mới

**Rủi ro nếu không làm**: -20 PoF

#### 4. Copy env.example thành .env (Nếu cần)

- [ ] **Backend:**
  ```bash
  cd backend
  cp env.example .env
  # Chỉnh sửa .env với các giá trị thực tế
  ```

- [ ] **Frontend Web:**
  ```bash
  cd frontend-web-manager
  cp env.example .env
  # Chỉnh sửa .env với các giá trị thực tế
  ```

**Lưu ý**: File `.env` không được commit vào Git (đã có trong .gitignore)

## 📊 Điểm Rủi Ro (PoF) Hiện Tại

Sau khi hoàn thành các checklist trên:

| Trạng thái | PoF ước tính |
|------------|-------------|
| **Nếu hoàn thành tất cả** | **0-10 PoF** (Hoàn hảo!) |
| **Nếu thiếu license headers** | +10 PoF |
| **Nếu thiếu GitHub Release** | +50 PoF |
| **Nếu Issues không bật** | +20 PoF |

**Mục tiêu**: Giữ PoF ở mức **0-25 PoF** (Bạn đang làm tốt!)

## ✅ Verification Checklist

Trước khi nộp bài, kiểm tra:

- [ ] Đã chạy script thêm license headers
- [ ] Đã tạo GitHub Release với tag v1.0.0
- [ ] Đã xác nhận GitHub Issues được bật
- [ ] Đã kiểm tra tất cả file quan trọng có license header
- [ ] Đã kiểm tra README đầy đủ và chính xác
- [ ] Đã kiểm tra CHANGELOG.md có version 1.0.0
- [ ] Đã kiểm tra LICENSE file tồn tại
- [ ] Đã kiểm tra tất cả tài liệu (DATA_SOURCES.md, LICENSES.md, PROJECT_STRUCTURE.md)

## 🔗 Tài Liệu Liên Quan

- [LICENSE_HEADERS_GUIDE.md](LICENSE_HEADERS_GUIDE.md) - Hướng dẫn thêm license headers
- [GITHUB_RELEASE_GUIDE.md](GITHUB_RELEASE_GUIDE.md) - Hướng dẫn tạo GitHub Release
- [LICENSES.md](LICENSES.md) - Tương thích giấy phép
- [DATA_SOURCES.md](DATA_SOURCES.md) - Nguồn dữ liệu mở

## 📅 Timeline

**Khuyến nghị hoàn thành trước:**
- **License headers**: 1-2 ngày trước thời hạn
- **GitHub Release**: 1 ngày trước thời hạn
- **Final check**: Ngày trước thời hạn nộp bài

**Thời hạn nộp bài**: 17:00 Thứ 2 ngày 08/12/2025

---

**Last Updated**: 2025-01-28  
**Version**: 1.0.0

