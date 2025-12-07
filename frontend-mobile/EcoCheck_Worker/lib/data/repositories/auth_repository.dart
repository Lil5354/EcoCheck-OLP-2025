/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';
import '../services/mock_data_service.dart';
import '../services/api_client.dart';
import '../../core/constants/api_constants.dart';

/// Repository cho xác thực - tách logic API/Storage ra khỏi BLoC
class AuthRepository {
  final SharedPreferences _prefs;
  final ApiClient _apiClient = ApiClient();

  AuthRepository(this._prefs);

  /// Đăng nhập - Kết nối với backend API
  Future<Worker> login(String email, String password) async {
    try {
      // Call backend API
      final response = await _apiClient.post(
        ApiConstants.loginEndpoint,
        {
          'email': email,
          'password': password,
        },
      );

      if (response['ok'] == true && response['data'] != null) {
        final userData = response['data'];
        
        // Check if user is a worker
        if (userData['role'] != 'worker') {
          throw Exception('Tài khoản này không phải là nhân viên');
        }

        // Get personnel info if available
        final workerId = userData['workerId'];
        final workerName = userData['workerName'] ?? userData['fullName'];
        final workerRole = userData['workerRole'] ?? 'collector';
        final depotId = userData['depotId'];
        final depotName = userData['depotName'];

        // Create Worker model
        final worker = Worker(
          id: workerId ?? userData['id'],
          userId: userData['id'],
          fullName: workerName,
          email: userData['email'],
          phoneNumber: userData['phone'],
          avatar: null,
          vehicleType: 'truck', // Default, can be updated later
          vehiclePlate: 'N/A', // Default, can be updated later
          status: userData['isActive'] == true ? 'active' : 'inactive',
          teamId: depotId,
          teamName: depotName,
          createdAt: DateTime.parse(userData['createdAt'] ?? DateTime.now().toIso8601String()),
          updatedAt: userData['updatedAt'] != null 
              ? DateTime.parse(userData['updatedAt']) 
              : null,
        );

        // Save credentials
        await _prefs.setString('worker_id', worker.id);
        await _prefs.setString('worker_user_id', worker.userId);
        await _prefs.setString('worker_email', email);

        return worker;
      } else {
        throw Exception(response['error'] ?? 'Email hoặc mật khẩu không đúng');
      }
    } catch (e) {
      // Fallback to mock for development if API fails
      print('API login failed, using mock: ${e.toString()}');
      
      // Mock validation for development
      if (email == 'worker@ecocheck.com' && password == '123456') {
        final worker = MockDataService.getCurrentWorker();
        await _prefs.setString('worker_id', worker.id);
        await _prefs.setString('worker_email', email);
        return worker;
      }
      
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Auto login từ saved credentials
  Future<Worker?> autoLogin() async {
    final workerId = _prefs.getString('worker_id');

    if (workerId != null) {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));
      return MockDataService.getCurrentWorker();
    }

    return null;
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _prefs.remove('worker_id');
    await _prefs.remove('worker_email');
  }

  /// Cập nhật profile
  Future<Worker> updateProfile(Worker worker) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Call API to update worker profile
    // final response = await api.put('/workers/${worker.id}', data: worker.toJson());

    return worker;
  }
}
