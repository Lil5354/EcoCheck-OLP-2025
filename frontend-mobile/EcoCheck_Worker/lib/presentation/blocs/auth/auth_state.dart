/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

/// Base state cho Auth
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// State: Chưa xác thực
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State: Đang loading
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State: Đã xác thực thành công
class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// State: Chưa xác thực / Đã đăng xuất
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State: Xác thực thất bại
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
