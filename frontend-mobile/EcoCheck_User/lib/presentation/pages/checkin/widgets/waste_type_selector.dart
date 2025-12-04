/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Waste Type Selector Widget
class WasteTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const WasteTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      {
        'id': 'household',
        'label': 'Rác sinh hoạt',
        'icon': Icons.delete,
        'color': AppColors.wasteOrganic,
        'description': 'Rác thải hàng ngày',
        'points': '+10 điểm',
      },
      {
        'id': 'recyclable',
        'label': 'Rác tái chế',
        'icon': Icons.recycling,
        'color': AppColors.wasteRecyclable,
        'description': 'Giấy, nhựa, kim loại, thủy tinh',
        'points': '+20 điểm',
      },
      {
        'id': 'bulky',
        'label': 'Rác cồng kềnh',
        'icon': Icons.inventory_2,
        'color': AppColors.wasteHazardous,
        'description': 'Đồ nội thất, đồ điện tử lớn',
        'points': '+30 điểm',
      },
    ];

    return Column(
      children: types.map((type) {
        final isSelected = selectedType == type['id'];
        final color = type['color'] as Color;

        return WasteTypeCard(
          type: type,
          isSelected: isSelected,
          color: color,
          onTap: () => onChanged(type['id'] as String),
        );
      }).toList(),
    );
  }
}

/// Waste Type Card
class WasteTypeCard extends StatelessWidget {
  final Map<String, dynamic> type;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const WasteTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _WasteTypeIcon(icon: type['icon'] as IconData, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: _WasteTypeInfo(
                type: type,
                isSelected: isSelected,
                color: color,
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Waste Type Icon
class _WasteTypeIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _WasteTypeIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

/// Waste Type Info
class _WasteTypeInfo extends StatelessWidget {
  final Map<String, dynamic> type;
  final bool isSelected;
  final Color color;

  const _WasteTypeInfo({
    required this.type,
    required this.isSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              type['label'] as String,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : AppColors.black,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                type['points'] as String,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          type['description'] as String,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
        ),
      ],
    );
  }
}
