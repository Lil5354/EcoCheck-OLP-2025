import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';

/// Widget hiển thị header của profile - tách ra để dễ quản lý
class ProfileHeader extends StatelessWidget {
  final UserModel? worker;

  const ProfileHeader({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.white,
              child: worker?.avatarUrl != null && worker!.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        worker!.avatarUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.primary,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              worker?.fullName ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              worker?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white.withOpacity(0.9),
              ),
            ),
            if (worker?.role != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  worker!.role.toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: AppColors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
