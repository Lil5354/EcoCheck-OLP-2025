# EcoCheck Worker App 👷

Ứng dụng mobile dành cho nhân viên thu gom rác thải, quản lý lịch trình và thực hiện các nhiệm vụ thu gom.

## 📱 Mô tả

EcoCheck Worker App là một phần của hệ thống EcoCheck - nền tảng quản lý thu gom rác thải thông minh. Ứng dụng giúp nhân viên:

- 📋 **Quản lý lịch trình**: Xem danh sách lịch thu gom được phân công
- 🗺️ **Điều hướng**: Xem vị trí và đường đi đến địa điểm thu gom
- ✅ **Cập nhật trạng thái**: Bắt đầu, hoàn thành công việc thu gom
- 📊 **Thống kê công việc**: Theo dõi số lượng lịch đã hoàn thành
- 🔔 **Thông báo**: Nhận cập nhật về lịch mới và thay đổi
- 👤 **Quản lý tài khoản**: Đăng nhập, xem thông tin cá nhân

## 🏗️ Cấu trúc dự án

```
lib/
├── main.dart                          # Entry point của ứng dụng
├── core/                              # Cấu hình và utilities chung
│   ├── config/                        # App configuration
│   ├── constants/                     # Constants (colors, texts, API)
│   │   ├── api_constants.dart         # API endpoints
│   │   ├── app_colors.dart           # Color palette
│   │   └── app_strings.dart          # Text strings
│   ├── di/                            # Dependency Injection
│   │   └── injection_container.dart   # Service locator setup
│   ├── network/                       # Network layer
│   │   ├── api_client.dart           # Dio HTTP client
│   │   └── api_exception.dart        # Custom exceptions
│   └── utils/                         # Helper utilities
│
├── data/                              # Data layer
│   ├── models/                        # Data models
│   │   ├── user_model.dart           # User/Worker entity
│   │   ├── schedule_model.dart       # Schedule entity
│   │   └── route_model.dart          # Route entity
│   └── repositories/                  # Repository implementations
│       └── ecocheck_repository.dart  # Main repository
│
└── presentation/                      # Presentation layer
    ├── blocs/                         # BLoC state management
    │   ├── auth/                      # Authentication BLoC
    │   ├── collection/                # Collection schedule BLoC
    │   └── route/                     # Route BLoC
    │
    ├── screens/                       # UI screens
    │   ├── login_screen.dart          # Login page
    │   ├── main_screen.dart           # Main navigation
    │   ├── dashboard_screen.dart      # Dashboard/Home
    │   ├── schedule_screen.dart       # Schedule list
    │   ├── route_screen.dart          # Route map
    │   └── profile_screen.dart        # Worker profile
    │
    └── widgets/                       # Reusable widgets
        ├── custom_button.dart         # Custom buttons
        ├── custom_text_field.dart     # Custom text fields
        ├── collection_card.dart       # Schedule card
        └── profile/                   # Profile widgets
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: BLoC (flutter_bloc 8.1.6)
- **Networking**: Dio 5.4.0
- **Local Storage**: SharedPreferences, Flutter Secure Storage
- **Maps**: Google Maps Flutter
- **Location**: Geolocator
- **DI**: GetIt 7.7.0
- **UI**: Material Design 3

## 📋 Prerequisites

Trước khi chạy ứng dụng, đảm bảo bạn đã cài đặt:

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode (cho Android/iOS development)
- Git

## 🚀 Cách chạy ứng dụng

### 1. Clone repository

```bash
git clone https://github.com/Lil5354/EcoCheck-OLP-2025.git
cd EcoCheck-OLP-2025/frontend-mobile/EcoCheck_Worker
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Cấu hình Backend

Đảm bảo backend đang chạy tại `http://localhost:3000` (hoặc update URL trong `lib/core/constants/api_constants.dart`)

**Nếu chạy trên Android Emulator:**
- Backend URL: `http://10.0.2.2:3000`

**Nếu chạy trên thiết bị thật:**
- Backend URL: `http://<YOUR_LOCAL_IP>:3000`

### 4. Chạy ứng dụng

**Android:**
```bash
flutter run
```

**iOS:**
```bash
flutter run
```

**Chọn thiết bị cụ thể:**
```bash
flutter devices                    # Xem danh sách devices
flutter run -d <device_id>        # Chạy trên device cụ thể
```

### 5. Build APK/IPA

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🔧 Cấu hình môi trường

### API Configuration

File: `lib/core/constants/api_constants.dart`

```dart
class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:3000';  // Android Emulator
  // static const String baseUrl = 'http://localhost:3000';  // iOS Simulator
  // static const String baseUrl = 'http://192.168.1.x:3000';  // Real Device
  
  static const String apiPrefix = '/api';
}
```

### Google Maps API Key

**Android:** `android/app/src/main/AndroidManifest.xml`
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**iOS:** `ios/Runner/AppDelegate.swift`
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

## 👥 Tài khoản demo

Để test ứng dụng, sử dụng tài khoản worker sau:

```
Số điện thoại: 0987654321
Mật khẩu: 123456
```

## 🧪 Testing

Chạy tests:
```bash
flutter test
```

Chạy tests với coverage:
```bash
flutter test --coverage
```

## 📱 Features chính

### 1. Authentication
- Đăng nhập với số điện thoại
- Tự động đăng nhập khi mở app
- Quản lý phiên đăng nhập

### 2. Dashboard
- Xem tổng quan công việc trong ngày
- Hiển thị danh sách lịch thu gom hôm nay
- Trạng thái: Assigned, In Progress, Completed

### 3. Schedule Management
- Xem danh sách lịch thu gom được phân công
- Lọc theo trạng thái (Assigned, In Progress, Completed)
- Xem chi tiết lịch thu gom (địa chỉ, loại rác, khối lượng)
- Mức độ ưu tiên: Normal, High, Urgent

### 4. Route & Navigation
- Xem route thu gom trên bản đồ
- Điều hướng đến vị trí thu gom
- Cập nhật vị trí hiện tại

### 5. Work Status Updates
- Bắt đầu công việc thu gom
- Cập nhật khối lượng thực tế
- Hoàn thành công việc
- Báo cáo sự cố (nếu có)

### 6. Profile
- Xem thông tin cá nhân
- Thống kê công việc đã hoàn thành
- Đăng xuất

## 📊 Dữ liệu mẫu

Ứng dụng hiện có **15 lịch thu gom mẫu** được assign cho worker demo:
- Schedules từ User App (dữ liệu thực)
- Các loại rác: Organic, Recyclable, Household, Bulky, Hazardous
- Trạng thái đa dạng: Assigned, In Progress, Scheduled, Completed

## 🔗 Related Projects

- **Backend API**: `backend/`
- **Web Manager**: `frontend-web-manager/`
- **User App**: `frontend-mobile/EcoCheck_User/`
- **Database**: `db/`

## 📄 License

MIT License - Copyright (c) 2025 Lil5354

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📞 Support

- Email: doanda22@uef.edu.vn , @Lil5354
- GitHub Issues: [Create Issue](https://github.com/Lil5354/EcoCheck-OLP-2025/issues)

---


