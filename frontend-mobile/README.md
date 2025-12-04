# Hướng Dẫn Khởi Động Flutter Apps

## Yêu Cầu Hệ Thống

- Flutter SDK (phiên bản stable mới nhất)
- Dart SDK (đi kèm với Flutter)
- Android Studio / VS Code với Flutter extension
- Xcode (cho macOS - nếu build iOS)
- Chrome (để test web)

## Kiểm Tra Cài Đặt Flutter

```bash
flutter doctor
```

Đảm bảo tất cả các mục quan trọng đều có dấu ✓ (checkmark).

## Cấu Trúc Dự Án

```
frontend-mobile/
├── EcoCheck_User/      # App cho người dùng
├── EcoCheck_Worker/    # App cho công nhân
```

---

## 🚀 Khởi Động App EcoCheck_User

### Bước 1: Di chuyển vào thư mục

```bash
cd frontend-mobile/EcoCheck_User
```

### Bước 2: Cài đặt dependencies

```bash
flutter pub get
```

### Bước 3: Chạy app

#### Chạy trên Chrome (Web):
```bash
flutter run -d chrome
```

#### Chạy trên Android Emulator:
```bash
# Khởi động emulator trước
flutter emulators --launch <emulator_id>

# Sau đó chạy app
flutter run
```

#### Chạy trên iOS Simulator (macOS only):
```bash
open -a Simulator
flutter run
```

#### Chạy trên thiết bị thực:
```bash
# Kết nối điện thoại qua USB và bật USB debugging
flutter devices  # Kiểm tra device
flutter run
```

### Bước 4: Hot Reload

Khi app đang chạy:
- Nhấn `r` để hot reload
- Nhấn `R` để hot restart
- Nhấn `q` để thoát

---

## 👷 Khởi Động App EcoCheck_Worker

### Bước 1: Di chuyển vào thư mục

```bash
cd frontend-mobile/EcoCheck_Worker
```

### Bước 2: Cài đặt dependencies

```bash
flutter pub get
```

### Bước 3: Chạy app

#### Chạy trên Chrome (Web):
```bash
flutter run -d chrome
```

#### Chạy trên Android Emulator:
```bash
flutter run
```

#### Chạy trên iOS Simulator (macOS only):
```bash
flutter run
```

#### Chạy trên thiết bị thực:
```bash
flutter run
```

---

## 🔧 Các Lệnh Hữu Ích

### Clean build cache (khi gặp lỗi build)

```bash
flutter clean
flutter pub get
```

### Kiểm tra devices có sẵn

```bash
flutter devices
```

### Chạy với chế độ debug cụ thể

```bash
# Debug mode (mặc định)
flutter run

# Profile mode (tối ưu performance)
flutter run --profile

# Release mode (tối ưu tối đa)
flutter run --release
```

### Build APK/IPA

#### Build APK (Android):
```bash
cd frontend-mobile/EcoCheck_User  # hoặc EcoCheck_Worker
flutter build apk --release
# File APK sẽ ở: build/app/outputs/flutter-apk/app-release.apk
```

#### Build App Bundle (Android):
```bash
flutter build appbundle --release
```

#### Build iOS (macOS only):
```bash
flutter build ios --release
```

---

## 📦 Cài Đặt Dependencies Mới

Khi thêm package mới vào `pubspec.yaml`:

```bash
flutter pub get
```

Hoặc nếu dùng VS Code, file sẽ tự động chạy lệnh này khi save.

---

## 🐛 Xử Lý Lỗi Thường Gặp

### Lỗi: "No devices found"

**Giải pháp:**
- Bật Android Emulator hoặc kết nối thiết bị thực
- Kiểm tra với `flutter devices`

### Lỗi: "Gradle build failed"

**Giải pháp:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Lỗi: "Pod install failed" (iOS)

**Giải pháp:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

### Lỗi: "Version solving failed"

**Giải pháp:**
```bash
flutter clean
rm pubspec.lock
flutter pub get
```

### Lỗi kết nối backend

Kiểm tra file cấu hình API endpoint trong code (thường ở `lib/core/constants/` hoặc `lib/config/`)

---

## 🔄 Workflow Phát Triển

### 1. Clone repository

```bash
git clone <repository-url>
cd EcoCheck-OLP-2025
```

### 2. Checkout branch mới

```bash
git checkout -b feature/ten-tinh-nang
```

### 3. Khởi động app để test

```bash
cd frontend-mobile/EcoCheck_User
flutter pub get
flutter run -d chrome
```

### 4. Code và test

- Sửa code trong thư mục `lib/`
- Sử dụng Hot Reload (`r`) để xem thay đổi ngay lập tức
- Test trên nhiều devices/platforms nếu có thể

### 5. Build và kiểm tra

```bash
# Kiểm tra lỗi
flutter analyze

# Format code
flutter format .

# Chạy tests (nếu có)
flutter test
```

### 6. Commit và push

```bash
git add .
git commit -m "feat: thêm tính năng X"
git push origin feature/ten-tinh-nang
```

---

## 📱 Chạy Đồng Thời 2 Apps

### Tùy chọn 1: Dùng 2 terminal

**Terminal 1:**
```bash
cd frontend-mobile/EcoCheck_User
flutter run -d chrome --web-port=5000
```

**Terminal 2:**
```bash
cd frontend-mobile/EcoCheck_Worker
flutter run -d chrome --web-port=5001
```

### Tùy chọn 2: Dùng VS Code

1. Mở 2 VS Code windows
2. Window 1: Mở folder `frontend-mobile/EcoCheck_User`
3. Window 2: Mở folder `frontend-mobile/EcoCheck_Worker`
4. Nhấn F5 hoặc Run > Start Debugging ở mỗi window

---

## 📝 Cấu Trúc Code

### EcoCheck_User & EcoCheck_Worker

```
lib/
├── main.dart                 # Entry point
├── core/                     # Core functionality
│   ├── constants/           # Constants, configs
│   ├── utils/              # Utility functions
│   └── widgets/            # Reusable widgets
├── data/                    # Data layer
│   ├── models/             # Data models
│   ├── repositories/       # Data repositories
│   └── services/           # API services
└── presentation/           # UI layer
    ├── screens/            # App screens
    ├── widgets/            # Screen-specific widgets
    └── providers/          # State management
```

---

## 🔗 Kết Nối Backend

Đảm bảo backend đang chạy trước khi test app:

```bash
# Từ root project
cd backend
npm install
npm start
```

Hoặc dùng Docker:

```bash
docker-compose up
```

---

## 📞 Liên Hệ & Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra file `CONTRIBUTING.md` trong root project
2. Tạo issue trên GitHub repository
3. Liên hệ team lead

---

## ✅ Checklist Trước Khi Push Code

- [ ] Code đã được format: `flutter format .`
- [ ] Không có lỗi analyze: `flutter analyze`
- [ ] App chạy được trên ít nhất 1 platform
- [ ] Đã test các tính năng mới
- [ ] Đã commit với message rõ ràng
- [ ] Đã pull code mới nhất từ branch chính

---

**Chúc bạn code vui vẻ! 🎉**
