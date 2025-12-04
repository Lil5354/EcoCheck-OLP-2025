/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
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

  static const TextStyle numberSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    fontFamily: fontFamily,
  );

  // Status badge text
  static const TextStyle badge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: fontFamily,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
    fontFamily: fontFamily,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    fontFamily: fontFamily,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    fontFamily: fontFamily,
  );
}

/// App String Constants
class AppStrings {
  AppStrings._();

  // Common
  static const String appName = 'EcoCheck Worker';
  static const String ok = 'OK';
  static const String cancel = 'Hủy';
  static const String confirm = 'Xác nhận';
  static const String save = 'Lưu';
  static const String delete = 'Xóa';
  static const String edit = 'Sửa';
  static const String search = 'Tìm kiếm';
  static const String filter = 'Lọc';
  static const String sort = 'Sắp xếp';
  static const String loading = 'Đang tải...';
  static const String retry = 'Thử lại';
  static const String viewAll = 'Xem tất cả';

  // Auth
  static const String login = 'Đăng nhập';
  static const String logout = 'Đăng xuất';
  static const String email = 'Email';
  static const String password = 'Mật khẩu';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String loginSuccess = 'Đăng nhập thành công';
  static const String logoutConfirm = 'Bạn có chắc muốn đăng xuất?';

  // Navigation
  static const String home = 'Trang chủ';
  static const String routes = 'Tuyến đường';
  static const String schedule = 'Lịch trình';
  static const String profile = 'Tài khoản';

  // Schedule Status
  static const String statusPending = 'Chờ xử lý';
  static const String statusScheduled = 'Đã lên lịch';
  static const String statusAssigned = 'Đã phân công';
  static const String statusInProgress = 'Đang thực hiện';
  static const String statusCompleted = 'Hoàn thành';
  static const String statusCancelled = 'Đã hủy';

  // Waste Types
  static const String wasteOrganic = 'Hữu cơ';
  static const String wasteRecyclable = 'Tái chế';
  static const String wasteHazardous = 'Nguy hại';
  static const String wasteGeneral = 'Thông thường';
  static const String wasteElectronic = 'Điện tử';

  // Errors
  static const String errorGeneric = 'Có lỗi xảy ra, vui lòng thử lại';
  static const String errorNetwork = 'Không có kết nối mạng';
  static const String errorServer = 'Lỗi máy chủ';
  static const String errorInvalidInput = 'Dữ liệu không hợp lệ';
}
