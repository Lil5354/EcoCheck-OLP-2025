import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';

/// Time Slot Selector Widget
class TimeSlotSelector extends StatelessWidget {
  final String selectedSlot;
  final ValueChanged<String> onChanged;

  const TimeSlotSelector({
    super.key,
    required this.selectedSlot,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final slots = [
      {
        'id': AppConstants.timeSlotMorning,
        'label': 'Sáng (7h-11h)',
        'icon': Icons.wb_sunny,
      },
      {
        'id': AppConstants.timeSlotAfternoon,
        'label': 'Chiều (13h-17h)',
        'icon': Icons.wb_twilight,
      },
      {
        'id': AppConstants.timeSlotEvening,
        'label': 'Tối (18h-21h)',
        'icon': Icons.nights_stay,
      },
    ];

    return Column(
      children: slots.map((slot) {
        final isSelected = selectedSlot == slot['id'];

        return RadioListTile<String>(
          value: slot['id'] as String,
          groupValue: selectedSlot,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          title: Row(
            children: [
              Icon(
                slot['icon'] as IconData,
                color: isSelected ? AppColors.primary : AppColors.grey,
              ),
              const SizedBox(width: 12),
              Text(slot['label'] as String),
            ],
          ),
          activeColor: AppColors.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        );
      }).toList(),
    );
  }
}
