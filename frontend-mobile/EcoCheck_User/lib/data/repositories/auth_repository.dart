/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

/// Repository cho xác thực User app
class AuthRepository {
  final SharedPreferences _prefs;
  final Dio _dio;

  AuthRepository(this._prefs, this._dio);

  /// Đăng nhập
  Future<UserModel> login(String phoneOrEmail, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.loginUrl,
        data: phoneOrEmail.contains('@')
            ? {'email': phoneOrEmail, 'password': password}
            : {'phone': phoneOrEmail, 'password': password},
      );

      if (response.data['ok'] == true && response.data['data'] != null) {
        final userData = response.data['data'];
        final user = UserModel.fromJson(userData);

        // Save credentials
        await _prefs.setString('user_id', user.id);
        await _prefs.setString('user_phone', user.phone);
        await _prefs.setString('user_email', user.email ?? '');

        return user;
      } else {
        throw Exception(response.data['error'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? 'Lỗi kết nối');
      }
      throw Exception(e.toString());
    }
  }

  /// Đăng ký
  Future<UserModel> register({
    required String phone,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.registerUrl,
        data: {
          'phone': phone,
          'email': email,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.data['ok'] == true && response.data['data'] != null) {
        final userData = response.data['data'];
        final user = UserModel.fromJson(userData);

        // Save credentials
        await _prefs.setString('user_id', user.id);
        await _prefs.setString('user_phone', user.phone);
        await _prefs.setString('user_email', user.email ?? '');

        return user;
      } else {
        throw Exception(response.data['error'] ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['error'] ?? 'Lỗi kết nối');
      }
      throw Exception(e.toString());
    }
  }

  /// Kiểm tra đăng nhập tự động
  Future<UserModel?> autoLogin() async {
    final userId = _prefs.getString('user_id');
    if (userId == null) return null;

    try {
      final response = await _dio.get(
        ApiConstants.profileUrl,
        queryParameters: {'user_id': userId},
      );
      if (response.data['ok'] == true && response.data['data'] != null) {
        return UserModel.fromJson(response.data['data']);
      }
    } catch (e) {
      // Auto login failed, clear saved credentials
      await logout();
    }
    return null;
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _prefs.remove('user_id');
    await _prefs.remove('user_phone');
    await _prefs.remove('user_email');
  }
}
