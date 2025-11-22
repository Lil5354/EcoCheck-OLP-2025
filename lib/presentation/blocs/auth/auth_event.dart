import 'package:equatable/equatable.dart';
import '../../../data/models/worker.dart';

/// Base event cho Auth
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event: Đăng nhập
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event: Auto login khi mở app
class AutoLoginRequested extends AuthEvent {
  const AutoLoginRequested();
}

/// Event: Đăng xuất
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event: Cập nhật profile
class UpdateProfileRequested extends AuthEvent {
  final Worker worker;

  const UpdateProfileRequested({required this.worker});

  @override
  List<Object?> get props => [worker];
}
