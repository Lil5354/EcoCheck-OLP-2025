import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/ecocheck_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC quản lý xác thực - sử dụng backend thực
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final EcoCheckRepository _repository;
  final SharedPreferences _prefs;

  AuthBloc({
    required EcoCheckRepository repository,
    required SharedPreferences prefs,
  }) : _repository = repository,
       _prefs = prefs,
       super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<AutoLoginRequested>(_onAutoLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
  }

  /// Handler: Login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.login(
        phone: event.email, // Using email field for phone
        password: event.password,
      );

      // Save user data
      await _prefs.setString('user_id', user.id);
      await _prefs.setString('user_phone', user.phone);

      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
      emit(const Unauthenticated());
    }
  }

  /// Handler: Auto Login
  Future<void> _onAutoLoginRequested(
    AutoLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final userId = _prefs.getString('user_id');

      if (userId != null) {
        final user = await _repository.getCurrentUser(userId);
        emit(Authenticated(user: user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(const Unauthenticated());
    }
  }

  /// Handler: Logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    await _prefs.remove('user_id');
    await _prefs.remove('user_phone');
    emit(const Unauthenticated());
  }

  /// Handler: Update Profile
  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is Authenticated) {
      emit(const AuthLoading());

      try {
        // TODO: Implement update profile in repository
        final updatedUser = event.user;
        emit(Authenticated(user: updatedUser));
      } catch (e) {
        emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
        // Restore previous state
        emit(Authenticated(user: event.user));
      }
    }
  }
}
