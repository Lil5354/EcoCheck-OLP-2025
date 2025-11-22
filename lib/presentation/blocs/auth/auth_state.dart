import 'package:equatable/equatable.dart';
import 'package:eco_check/data/models/user_model.dart';

/// Auth States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial State
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading State
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated State
class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated State
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Auth Error State
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Registration Success State
class RegistrationSuccess extends AuthState {
  const RegistrationSuccess();
}

/// OTP Sent State
class OtpSent extends AuthState {
  final String phone;

  const OtpSent(this.phone);

  @override
  List<Object?> get props => [phone];
}
