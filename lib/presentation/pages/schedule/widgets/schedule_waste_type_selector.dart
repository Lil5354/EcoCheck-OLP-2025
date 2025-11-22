import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';

/// Waste Type Selector for Create Schedule
class ScheduleWasteTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const ScheduleWasteTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      {
        'id': AppConstants.wasteTypeOrganic,
        'label': 'Rác hữu cơ',
        'icon': Icons.eco,
      },
      {
        'id': AppConstants.wasteTypeRecyclable,
        'label': 'Rác tái chế',
        'icon': Icons.recycling,
      },
      {
        'id': AppConstants.wasteTypeHazardous,
        'label': 'Rác nguy hại',
        'icon': Icons.warning,
      },
      {
        'id': AppConstants.wasteTypeElectronic,
        'label': 'Rác điện tử',
        'icon': Icons.phone_android,
      },
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = selectedType == type['id'];
        final color = AppColors.getWasteTypeColor(type['id'] as String);

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                type['icon'] as IconData,
                size: 18,
                color: isSelected ? AppColors.white : color,
              ),
              const SizedBox(width: 8),
              Text(type['label'] as String),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) onChanged(type['id'] as String);
          },
          selectedColor: color,
          backgroundColor: color.withOpacity(0.1),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? AppColors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
