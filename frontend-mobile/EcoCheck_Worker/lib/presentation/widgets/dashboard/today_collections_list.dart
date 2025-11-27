import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/schedule_model.dart';
import '../collection_card.dart';

/// Widget hiển thị danh sách collections hôm nay - tách ra để dễ quản lý
class TodayCollectionsList extends StatelessWidget {
  final List<ScheduleModel> todayRequests;
  final bool isLoading;
  final VoidCallback onViewAll;

  const TodayCollectionsList({
    super.key,
    required this.todayRequests,
    required this.isLoading,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhiệm vụ hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('Xem tất cả')),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // List Content
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (todayRequests.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: const [
                  Icon(Icons.inbox_outlined, size: 64, color: AppColors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có nhiệm vụ nào hôm nay',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: todayRequests.length > 3 ? 3 : todayRequests.length,
            itemBuilder: (context, index) {
              final request = todayRequests[index];
              return CollectionCard(
                request: request,
                onTap: () {
                  // TODO: Navigate to detail
                },
              );
            },
          ),
      ],
    );
  }
}
