/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'color_constants.dart';

/// App Text Styles
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  // Base font family
  static const String fontFamily = 'Roboto';

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
    fontFamily: fontFamily,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
    fontFamily: fontFamily,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    fontFamily: fontFamily,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    fontFamily: fontFamily,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    fontFamily: fontFamily,
  );

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
    fontFamily: fontFamily,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGrey,
    fontFamily: fontFamily,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
    fontFamily: fontFamily,
    height: 1.5,
  );

  // Button Text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
    fontFamily: fontFamily,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.grey,
    fontFamily: fontFamily,
  );

  // Overline
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.grey,
    fontFamily: fontFamily,
    letterSpacing: 1.5,
  );

  // Special Text Styles
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGrey,
    fontFamily: fontFamily,
  );

  static const TextStyle hint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
    fontFamily: fontFamily,
  );

  static const TextStyle error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    fontFamily: fontFamily,
  );

  static const TextStyle link = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    fontFamily: fontFamily,
    decoration: TextDecoration.underline,
  );

  // Number styles
  static const TextStyle numberLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: fontFamily,
  );

  static const TextStyle numberMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: fontFamily,
  );
}

/// App Text Strings (i18n ready)
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'EcoCheck';
  static const String appTagline = 'Thu gom rác thải thông minh';

  // Auth
  static const String login = 'Đăng nhập';
  static const String register = 'Đăng ký';
  static const String logout = 'Đăng xuất';
  static const String phone = 'Số điện thoại';
  static const String password = 'Mật khẩu';
  static const String confirmPassword = 'Xác nhận mật khẩu';
  static const String fullName = 'Họ và tên';
  static const String email = 'Email';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String dontHaveAccount = 'Chưa có tài khoản?';
  static const String alreadyHaveAccount = 'Đã có tài khoản?';

  // Home
  static const String home = 'Trang chủ';
  static const String welcome = 'Xin chào';
  static const String quickActions = 'Hành động nhanh';
  static const String upcomingSchedule = 'Lịch tiếp theo';
  static const String statistics = 'Thống kê';
  static const String ecoTips = 'Mẹo sinh thái';

  // Schedule
  static const String schedule = 'Lịch thu gom';
  static const String createSchedule = 'Tạo lịch thu gom';
  static const String editSchedule = 'Sửa lịch';
  static const String scheduleDetail = 'Chi tiết lịch';
  static const String scheduleDate = 'Ngày thu gom';
  static const String timeSlot = 'Khung giờ';
  static const String wasteType = 'Loại rác';
  static const String estimatedWeight = 'Ước tính khối lượng';
  static const String address = 'Địa chỉ';
  static const String specialInstructions = 'Ghi chú đặc biệt';
  static const String status = 'Trạng thái';

  // Time Slots
  static const String morning = 'Buổi sáng';
  static const String afternoon = 'Buổi chiều';
  static const String evening = 'Buổi tối';

  // Waste Types
  static const String organic = 'Hữu cơ';
  static const String recyclable = 'Tái chế';
  static const String hazardous = 'Nguy hại';
  static const String general = 'Thông thường';

  // Status
  static const String pending = 'Chờ xác nhận';
  static const String confirmed = 'Đã xác nhận';
  static const String assigned = 'Đã phân công';
  static const String inProgress = 'Đang thu gom';
  static const String completed = 'Hoàn thành';
  static const String cancelled = 'Đã hủy';

  // Tracking
  static const String tracking = 'Theo dõi';
  static const String liveTracking = 'Theo dõi xe';
  static const String vehicleLocation = 'Vị trí xe';
  static const String eta = 'Dự kiến đến';
  static const String distance = 'Khoảng cách';

  // Statistics
  static const String totalWeight = 'Tổng khối lượng';
  static const String co2Saved = 'CO2 tiết kiệm';
  static const String pointsEarned = 'Điểm tích lũy';
  static const String achievements = 'Thành tích';
  static const String leaderboard = 'Bảng xếp hạng';

  // Notifications
  static const String notifications = 'Thông báo';
  static const String markAllRead = 'Đánh dấu đã đọc';
  static const String noNotifications = 'Không có thông báo';

  // Profile
  static const String profile = 'Hồ sơ';
  static const String editProfile = 'Sửa hồ sơ';
  static const String settings = 'Cài đặt';
  static const String about = 'Về ứng dụng';
  static const String help = 'Trợ giúp';
  static const String language = 'Ngôn ngữ';
  static const String darkMode = 'Chế độ tối';

  // Actions
  static const String save = 'Lưu';
  static const String cancel = 'Hủy';
  static const String delete = 'Xóa';
  static const String edit = 'Sửa';
  static const String submit = 'Gửi';
  static const String confirm = 'Xác nhận';
  static const String ok = 'OK';
  static const String yes = 'Có';
  static const String no = 'Không';
  static const String retry = 'Thử lại';

  // Messages
  static const String loading = 'Đang tải...';
  static const String success = 'Thành công';
  static const String error = 'Có lỗi xảy ra';
  static const String noInternet = 'Không có kết nối Internet';
  static const String scheduleCreatedSuccess = 'Tạo lịch thành công';
  static const String scheduleUpdatedSuccess = 'Cập nhật lịch thành công';
  static const String scheduleDeletedSuccess = 'Xóa lịch thành công';
  static const String confirmDelete = 'Bạn có chắc muốn xóa?';

  // Validation
  static const String fieldRequired = 'Trường này là bắt buộc';
  static const String invalidPhone = 'Số điện thoại không hợp lệ';
  static const String invalidEmail = 'Email không hợp lệ';
  static const String passwordTooShort = 'Mật khẩu phải có ít nhất 6 ký tự';
  static const String passwordNotMatch = 'Mật khẩu không khớp';
}
