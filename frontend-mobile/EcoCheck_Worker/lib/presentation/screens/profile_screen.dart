/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/worker_info_card.dart';
import '../widgets/profile/settings_section.dart';
import '../widgets/profile/logout_button.dart';

/// Profile Screen - ĐÃ TÁCH LOGIC RA CÁC WIDGETS NHỎ
///
/// Structure:
/// - ProfileHeader: Avatar, name, email, team (profile_header.dart)
/// - ProfileStats: Thống kê 4 cards (profile_stats.dart)
/// - WorkerInfoCard: Thông tin nhân viên (worker_info_card.dart)
/// - SettingsSection: Cài đặt (settings_section.dart)
/// - LogoutButton: Nút đăng xuất (logout_button.dart)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = (state is Authenticated) ? state.user : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: const Text(
              AppStrings.profile,
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                ProfileHeader(worker: user),

                const SizedBox(height: 24),

                // Worker Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: WorkerInfoCard(worker: user),
                ),

                const SizedBox(height: 24),

                // Settings Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SettingsSection(),
                ),

                const SizedBox(height: 24),

                // Logout Button
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LogoutButton(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
