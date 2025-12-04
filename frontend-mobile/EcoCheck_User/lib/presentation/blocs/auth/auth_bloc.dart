/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eco_check/data/models/user_model.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/data/services/sync_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final EcoCheckRepository _repository;
  final SharedPreferences _prefs;
  final SyncService _syncService;

  AuthBloc({
    required EcoCheckRepository repository,
    required SharedPreferences prefs,
    required SyncService syncService,
  }) : _repository = repository,
       _prefs = prefs,
       _syncService = syncService,
       super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<OtpVerificationRequested>(_onOtpVerificationRequested);
  }

  /// Handle Login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Call real backend API
      final user = await _repository.login(
        phone: event.phone,
        password: event.password,
      );

      // Save user data using SyncService
      await _syncService.saveUserData(user);

      // Legacy SharedPreferences for backward compatibility
      await _prefs.setString('user_id', user.id);
      await _prefs.setString('user_phone', user.phone);
      await _prefs.setString('user_name', user.fullName);
      await _prefs.setBool('is_logged_in', true);

      // Start auto-sync
      _syncService.startAutoSync();

      print('🔐 [AUTH] Login successful: ${user.phone} (${user.id})');
      print('🔄 [AUTH] Auto-sync started');
      emit(Authenticated(user));
    } catch (e) {
      print('🔐 [AUTH] Login error: $e');

      if (e.toString().contains('Invalid phone or password')) {
        emit(const AuthError('Số điện thoại hoặc mật khẩu không đúng'));
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        emit(const AuthError('Không thể kết nối đến server'));
      } else {
        emit(AuthError('Đã xảy ra lỗi: ${e.toString()}'));
      }
    }
  }

  /// Handle Register
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Call real backend API
      final user = await _repository.register(
        phone: event.phone,
        password: event.password,
        email: event.email,
        fullName: event.fullName,
      );

      print('👤 [AUTH] Registration successful: ${event.phone}');

      // Save user data using SyncService
      await _syncService.saveUserData(user);

      // Legacy SharedPreferences for backward compatibility
      await _prefs.setString('user_id', user.id);
      await _prefs.setString('user_phone', user.phone);
      await _prefs.setString('user_name', user.fullName);
      await _prefs.setBool('is_logged_in', true);

      // Start auto-sync
      _syncService.startAutoSync();

      print('🔐 [AUTH] Auto-sync started after registration');

      // Emit RegistrationSuccess briefly to show dialog
      emit(const RegistrationSuccess());

      // Wait a bit for dialog to show, then authenticate
      await Future.delayed(const Duration(milliseconds: 500));
      emit(Authenticated(user));
    } catch (e) {
      print('👤 [AUTH] Register error: $e');

      String errorMessage;
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('already registered') ||
          errorStr.contains('phone') && errorStr.contains('exist')) {
        errorMessage = 'Số điện thoại đã được đăng ký';
      } else if (errorStr.contains('duplicate') && errorStr.contains('email')) {
        errorMessage = 'Email đã được sử dụng. Vui lòng dùng email khác';
      } else if (errorStr.contains('duplicate') && errorStr.contains('phone')) {
        errorMessage = 'Số điện thoại đã được đăng ký';
      } else if (errorStr.contains('invalid email')) {
        errorMessage = 'Email không hợp lệ';
      } else if (errorStr.contains('invalid phone')) {
        errorMessage = 'Số điện thoại không hợp lệ';
      } else if (errorStr.contains('network') ||
          errorStr.contains('connection')) {
        errorMessage = 'Không thể kết nối đến server';
      } else if (errorStr.contains('timeout')) {
        errorMessage = 'Yêu cầu quá hạn. Vui lòng thử lại';
      } else {
        errorMessage = 'Đăng ký thất bại. Vui lòng thử lại sau';
      }

      emit(AuthError(errorMessage));
    }
  }

  /// Handle Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Clear all synced data
      await _syncService.clearAllData();

      // Clear legacy SharedPreferences
      await _prefs.remove('user_id');
      await _prefs.remove('user_phone');
      await _prefs.remove('user_name');
      await _prefs.setBool('is_logged_in', false);

      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError('Đăng xuất thất bại: ${e.toString()}'));
    }
  }

  /// Check Auth Status
  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Check if user is logged in using SyncService
      if (_syncService.isLoggedIn()) {
        // Try to get cached user data first
        var user = _syncService.getCachedUserData();

        if (user != null) {
          // Start auto-sync for logged in users
          _syncService.startAutoSync();

          // Emit cached data immediately for faster startup
          emit(Authenticated(user));

          // Sync fresh data in background if needed
          if (_syncService.shouldSync()) {
            print('🔄 [AUTH] Background sync triggered');
            final freshUser = await _syncService.syncUserData();
            if (freshUser != null) {
              emit(Authenticated(freshUser));
            }
          }
          return;
        }
      }

      // Fallback to legacy check
      final isLoggedIn = _prefs.getBool('is_logged_in') ?? false;

      if (isLoggedIn) {
        final userId = _prefs.getString('user_id');

        if (userId != null && userId.isNotEmpty) {
          try {
            final user = await _repository.getCurrentUser(userId);
            await _syncService.saveUserData(user);
            _syncService.startAutoSync();
            emit(Authenticated(user));
            return;
          } catch (e) {
            print('🔑 [AUTH] Failed to fetch user data: $e');
            final userPhone = _prefs.getString('user_phone') ?? '';
            final userName = _prefs.getString('user_name') ?? '';

            if (userPhone.isNotEmpty) {
              final user = UserModel(
                id: userId,
                phone: userPhone,
                fullName: userName,
                role: 'citizen',
                address: '',
                isVerified: true,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              emit(Authenticated(user));
              return;
            }
          }
        }
      }

      emit(const Unauthenticated());
    } catch (e) {
      emit(const Unauthenticated());
    }
  }

  /// Handle OTP Verification
  Future<void> _onOtpVerificationRequested(
    OtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Simulate OTP verification
      await Future.delayed(const Duration(seconds: 2));

      // Mock success
      final user = UserModel(
        id: 'user-123',
        phone: event.phone,
        fullName: 'Người dùng mới',
        role: 'citizen',
        isVerified: true,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Xác thực OTP thất bại: ${e.toString()}'));
    }
  }
}
