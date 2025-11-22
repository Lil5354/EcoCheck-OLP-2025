import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/data/models/schedule_model.dart';

/// Upcoming Schedule Card Widget
class UpcomingScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;
  final int daysUntil;

  const UpcomingScheduleCard({
    super.key,
    required this.schedule,
    required this.daysUntil,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScheduleHeader(schedule: schedule),
            const Divider(height: 24),
            _ScheduleDateTime(schedule: schedule),
            const SizedBox(height: 8),
            _ScheduleLocation(address: schedule.address),
            const SizedBox(height: 8),
            _ScheduleCountdown(daysUntil: daysUntil),
          ],
        ),
      ),
    );
  }
}

/// Schedule Header with Icon and Status
class _ScheduleHeader extends StatelessWidget {
  final ScheduleModel schedule;

  const _ScheduleHeader({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.getWasteTypeColor(
              schedule.wasteType,
            ).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delete_outline,
            color: AppColors.getWasteTypeColor(schedule.wasteType),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(schedule.wasteTypeDisplay, style: AppTextStyles.h5),
              Text(
                '${schedule.estimatedWeight?.toStringAsFixed(1)}kg',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.getStatusColor(schedule.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            schedule.statusDisplay,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.getStatusColor(schedule.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Schedule Date Time Display
class _ScheduleDateTime extends StatelessWidget {
  final ScheduleModel schedule;

  const _ScheduleDateTime({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: AppColors.grey),
        const SizedBox(width: 8),
        Text(
          '${_formatDate(schedule.scheduledDate)} - ${schedule.timeSlotDisplay}',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Schedule Location Display
class _ScheduleLocation extends StatelessWidget {
  final String address;

  const _ScheduleLocation({required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: AppColors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: AppTextStyles.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Schedule Countdown Display
class _ScheduleCountdown extends StatelessWidget {
  final int daysUntil;

  const _ScheduleCountdown({required this.daysUntil});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 16, color: AppColors.grey),
        const SizedBox(width: 8),
        Text(
          'Còn $daysUntil ngày',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
