import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC quản lý xác thực - tách logic ra khỏi UI
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
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
      final worker = await _authRepository.login(event.email, event.password);
      emit(Authenticated(worker: worker));
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
      final worker = await _authRepository.autoLogin();

      if (worker != null) {
        emit(Authenticated(worker: worker));
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
    await _authRepository.logout();
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
        final updatedWorker = await _authRepository.updateProfile(event.worker);
        emit(Authenticated(worker: updatedWorker));
      } catch (e) {
        emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
        // Restore previous state
        emit(Authenticated(worker: event.worker));
      }
    }
  }
}
