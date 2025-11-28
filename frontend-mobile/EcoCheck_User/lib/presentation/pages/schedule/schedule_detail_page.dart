import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:eco_check/data/models/schedule_model.dart';
import 'package:eco_check/presentation/widgets/buttons/primary_button.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';

class ScheduleDetailPage extends StatelessWidget {
  final ScheduleModel? schedule;
  final String? scheduleId;

  const ScheduleDetailPage({super.key, this.schedule, this.scheduleId});

  ScheduleModel get _schedule =>
      schedule ??
      ScheduleModel(
        id: scheduleId ?? 'unknown',
        citizenId: 'user123',
        scheduledDate: DateTime.now().add(const Duration(days: 2)),
        timeSlot: AppConstants.timeSlotMorning,
        wasteType: AppConstants.wasteTypeRecyclable,
        estimatedWeight: 5.5,
        latitude: 10.762622,
        longitude: 106.660172,
        address: '123 Nguyễn Huệ, Quận 1, TP.HCM',
        status: AppConstants.statusConfirmed,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;
    final canEdit = schedule.isEditable;
    final canCancel =
        schedule.status == AppConstants.statusPending ||
        schedule.status == AppConstants.statusConfirmed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết lịch'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng chỉnh sửa đang phát triển'),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: AppColors.getStatusColor(schedule.status).withOpacity(0.1),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(schedule.status),
                    size: 48,
                    color: AppColors.getStatusColor(schedule.status),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    schedule.statusDisplay,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.getStatusColor(schedule.status),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Waste Type Info
                  _SectionTitle(title: 'Loại rác'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getWasteTypeColor(
                            schedule.wasteType,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: AppColors.getWasteTypeColor(
                            schedule.wasteType,
                          ),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              schedule.wasteTypeDisplay,
                              style: AppTextStyles.h5,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Khối lượng ước tính: ${schedule.estimatedWeight?.toStringAsFixed(1)}kg',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                            if (schedule.actualWeight != null)
                              Text(
                                'Khối lượng thực tế: ${schedule.actualWeight!.toStringAsFixed(1)}kg',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Schedule Info
                  _SectionTitle(title: 'Thời gian & địa điểm'),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Ngày thu gom',
                    value: _formatDate(schedule.scheduledDate),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Khung giờ',
                    value: schedule.timeSlotDisplay,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Địa chỉ',
                    value: schedule.address,
                  ),

                  const SizedBox(height: 24),

                  // Timeline
                  _SectionTitle(title: 'Lịch sử'),
                  const SizedBox(height: 12),
                  _Timeline(schedule: schedule),

                  if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Ghi chú'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        schedule.notes!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action Buttons
                  if (canCancel)
                    SecondaryButton(
                      text: 'Hủy lịch',
                      onPressed: () => _cancelSchedule(context, schedule),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.statusPending:
        return Icons.access_time;
      case AppConstants.statusConfirmed:
        return Icons.check_circle;
      case AppConstants.statusInProgress:
        return Icons.local_shipping;
      case AppConstants.statusCompleted:
        return Icons.done_all;
      case AppConstants.statusCancelled:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _cancelSchedule(
    BuildContext context,
    ScheduleModel schedule,
  ) async {
    final confirmed = await showConfirmationDialog(
      context,
      'Xác nhận hủy lịch',
      'Bạn có chắc chắn muốn hủy lịch thu gom này không?',
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading
    showLoadingDialog(context);

    // Mock API call
    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;

    // Hide loading
    Navigator.of(context).pop();

    // Show success
    showSuccessDialog(
      context,
      'Đã hủy lịch',
      'Lịch thu gom đã được hủy thành công.',
      onConfirm: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Back to list
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.h5);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
              ),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  final ScheduleModel schedule;

  const _Timeline({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          icon: Icons.add_circle,
          title: 'Đã tạo lịch',
          time: _formatDateTime(schedule.createdAt),
          isFirst: true,
        ),
        if (schedule.status != AppConstants.statusPending)
          _TimelineItem(
            icon: Icons.check_circle,
            title: 'Đã xác nhận',
            time: _formatDateTime(schedule.updatedAt),
          ),
        if (schedule.status == AppConstants.statusCompleted)
          _TimelineItem(
            icon: Icons.done_all,
            title: 'Đã hoàn thành',
            time: schedule.completedAt != null
                ? _formatDateTime(schedule.completedAt!)
                : 'N/A',
            isLast: true,
          ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.time,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              if (!isFirst)
                Container(width: 2, height: 12, color: AppColors.primary),
              Icon(icon, color: AppColors.primary, size: 24),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.primary)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
