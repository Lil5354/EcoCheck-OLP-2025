/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/worker.dart';
import '../services/mock_data_service.dart';

class AuthProvider with ChangeNotifier {
  Worker? _currentWorker;
  bool _isLoading = false;
  String? _errorMessage;

  Worker? get currentWorker => _currentWorker;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentWorker != null;

  // Login method
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if (email == 'worker@ecocheck.com' && password == '123456') {
        _currentWorker = MockDataService.getCurrentWorker();

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('worker_id', _currentWorker!.id);
        await prefs.setString('worker_email', email);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Email hoặc mật khẩu không đúng';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Auto login from saved credentials
  Future<bool> autoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workerId = prefs.getString('worker_id');

      if (workerId != null) {
        _currentWorker = MockDataService.getCurrentWorker();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _currentWorker = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('worker_id');
    await prefs.remove('worker_email');

    notifyListeners();
  }

  // Update worker profile
  Future<bool> updateProfile(Worker updatedWorker) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _currentWorker = updatedWorker;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể cập nhật thông tin';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
