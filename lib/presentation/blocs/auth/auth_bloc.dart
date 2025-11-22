import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eco_check/data/models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
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
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation
      if (event.phone == '0901234567' && event.password == '123456') {
        final user = UserModel(
          id: 'user-123',
          phone: event.phone,
          fullName: 'Nguyễn Văn A',
          role: 'citizen',
          address: '123 Nguyễn Huệ, Q1, TP.HCM',
          latitude: 10.762622,
          longitude: 106.660172,
          isVerified: true,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        emit(Authenticated(user));
      } else {
        emit(const AuthError('Số điện thoại hoặc mật khẩu không đúng'));
      }
    } catch (e) {
      emit(AuthError('Đã xảy ra lỗi: ${e.toString()}'));
    }
  }

  /// Handle Register
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Mock success
      emit(const RegistrationSuccess());
    } catch (e) {
      emit(AuthError('Đăng ký thất bại: ${e.toString()}'));
    }
  }

  /// Handle Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      // Simulate logout
      await Future.delayed(const Duration(milliseconds: 500));
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
      // Simulate checking stored token
      await Future.delayed(const Duration(seconds: 1));

      // Mock: Check if user is logged in
      // TODO: Check from SharedPreferences/SecureStorage
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
