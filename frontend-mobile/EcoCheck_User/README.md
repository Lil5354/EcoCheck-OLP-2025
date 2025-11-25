# EcoCheck User App 🌱

Ứng dụng mobile dành cho người dân quản lý và đặt lịch thu gom rác thải, tích lũy điểm thưởng và theo dõi hoạt động môi trường.

## 📱 Mô tả

EcoCheck User App là một phần của hệ thống EcoCheck - nền tảng quản lý thu gom rác thải thông minh. Ứng dụng giúp người dân:

- 🗓️ **Đặt lịch thu gom**: Lên lịch thu gom rác tại nhà với các khung giờ linh hoạt
- 📍 **Check-in thông minh**: Ghi nhận vị trí và loại rác thải khi đặt lịch
- 📊 **Thống kê cá nhân**: Theo dõi lượng rác đã thu gom, điểm số và thành tích
- 🏆 **Gamification**: Tích lũy điểm, nhận huy hiệu, xếp hạng trong cộng đồng
- 🔔 **Thông báo**: Nhận cập nhật về lịch thu gom và phần thưởng
- 👤 **Quản lý tài khoản**: Đăng ký, đăng nhập, chỉnh sửa thông tin cá nhân

## 🏗️ Cấu trúc dự án

```
lib/
├── main.dart                          # Entry point của ứng dụng
├── core/                              # Cấu hình và utilities chung
│   ├── config/                        # App configuration
│   ├── constants/                     # Constants (colors, texts, API)
│   │   ├── api_constants.dart         # API endpoints
│   │   ├── app_constants.dart         # App-wide constants
│   │   ├── color_constants.dart       # Color palette
│   │   └── text_constants.dart        # Text styles
│   ├── di/                            # Dependency Injection
│   │   └── injection_container.dart   # Service locator setup
│   ├── network/                       # Network layer
│   │   ├── api_client.dart           # Dio HTTP client
│   │   └── api_exception.dart        # Custom exceptions
│   └── utils/                         # Helper utilities
│
├── data/                              # Data layer
│   ├── models/                        # Data models
│   │   ├── user_model.dart           # User entity
│   │   ├── schedule_model.dart       # Schedule entity
│   │   ├── checkin_model.dart        # Check-in entity
│   │   ├── statistics_model.dart     # Statistics entity
│   │   └── gamification_model.dart   # Gamification entity
│   ├── repositories/                  # Repository implementations
│   │   └── ecocheck_repository.dart  # Main repository
│   └── services/                      # External services
│       └── sync_service.dart         # Data synchronization
│
└── presentation/                      # Presentation layer
    ├── blocs/                         # BLoC state management
    │   ├── auth/                      # Authentication BLoC
    │   ├── schedule/                  # Schedule BLoC
    │   ├── checkin/                   # Check-in BLoC
    │   ├── statistics/                # Statistics BLoC
    │   └── gamification/              # Gamification BLoC
    │
    ├── pages/                         # UI screens
    │   ├── auth/                      # Login, Register
    │   ├── home/                      # Home dashboard
    │   ├── schedule/                  # Schedule list, detail, create
    │   ├── checkin/                   # Check-in creation
    │   ├── statistics/                # Statistics & charts
    │   ├── gamification/              # Leaderboard, badges
    │   └── profile/                   # User profile
    │
    └── widgets/                       # Reusable widgets
        ├── buttons/                   # Custom buttons
        ├── inputs/                    # Custom text fields
        ├── dialogs/                   # Dialogs & modals
        └── cards/                     # Custom cards
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: BLoC (flutter_bloc)
- **Networking**: Dio
- **Local Storage**: SharedPreferences, Flutter Secure Storage
- **Maps**: Google Maps Flutter
- **Location**: Geolocator, Geocoding
- **DI**: GetIt
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
cd EcoCheck-OLP-2025/frontend-mobile/EcoCheck_User
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

Để test ứng dụng, sử dụng tài khoản sau:

```
Số điện thoại: 0901234567
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
- Đăng ký tài khoản mới
- Đăng nhập với số điện thoại
- Tự động đăng nhập khi mở app
- Quản lý phiên đăng nhập

### 2. Schedule Management
- Tạo lịch thu gom với thông tin chi tiết
- Chọn khung giờ (sáng, chiều, tối)
- Chọn loại rác (hữu cơ, tái chế, nguy hại, điện tử)
- Xem danh sách lịch (Đã xác nhận, Hoàn thành)
- Xem chi tiết lịch thu gom

### 3. Check-in & Location
- Check-in tại vị trí thu gom
- Tự động lấy tọa độ GPS
- Reverse geocoding để lấy địa chỉ
- Hiển thị bản đồ vị trí

### 4. Statistics
- Thống kê tổng lượng rác đã thu gom
- Biểu đồ theo tháng
- Phân loại theo loại rác
- Lượng CO₂ tiết kiệm được

### 5. Gamification
- Hệ thống điểm thưởng (10 điểm/kg)
- Huy hiệu thành tích (Đồng, Bạc, Vàng, Bạch Kim)
- Bảng xếp hạng cộng đồng
- Theo dõi tiến độ cá nhân

## 🔗 Related Projects

- **Backend API**: `backend/`
- **Web Manager**: `frontend-web-manager/`
- **Worker App**: `frontend-mobile/EcoCheck_Worker/`
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


