/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:equatable/equatable.dart';

/// Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Login Event
class LoginRequested extends AuthEvent {
  final String phone;
  final String password;

  const LoginRequested({required this.phone, required this.password});

  @override
  List<Object?> get props => [phone, password];
}

/// Register Event
class RegisterRequested extends AuthEvent {
  final String phone;
  final String fullName;
  final String? email;
  final String password;

  const RegisterRequested({
    required this.phone,
    required this.fullName,
    this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [phone, fullName, email, password];
}

/// Logout Event
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Check Auth Status Event
class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

/// OTP Verification Event
class OtpVerificationRequested extends AuthEvent {
  final String phone;
  final String otpCode;

  const OtpVerificationRequested({required this.phone, required this.otpCode});

  @override
  List<Object?> get props => [phone, otpCode];
}
