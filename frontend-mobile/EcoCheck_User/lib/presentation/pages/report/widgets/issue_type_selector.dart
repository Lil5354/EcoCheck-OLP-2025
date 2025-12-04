/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Issue Type Selector Widget
class IssueTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const IssueTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final types = [
      {
        'id': 'illegal_dump',
        'label': 'Rác thải tự phát',
        'icon': Icons.delete_forever,
        'description': 'Điểm đổ rác bậy, không đúng nơi quy định',
      },
      {
        'id': 'violation',
        'label': 'Hành vi vi phạm',
        'icon': Icons.warning,
        'description': 'Nhân viên trộn rác, không thu gom đúng',
      },
      {
        'id': 'other',
        'label': 'Vấn đề khác',
        'icon': Icons.report,
        'description': 'Các vấn đề khác liên quan đến rác thải',
      },
    ];

    return Column(
      children: types.map((type) {
        final isSelected = selectedType == type['id'];

        return IssueTypeCard(
          type: type,
          isSelected: isSelected,
          onTap: () => onChanged(type['id'] as String),
        );
      }).toList(),
    );
  }
}

/// Issue Type Card Widget
class IssueTypeCard extends StatelessWidget {
  final Map<String, dynamic> type;
  final bool isSelected;
  final VoidCallback onTap;

  const IssueTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
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
          color: isSelected
              ? AppColors.error.withOpacity(0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            _IssueTypeIcon(icon: type['icon'] as IconData),
            const SizedBox(width: 16),
            Expanded(
              child: _IssueTypeInfo(
                label: type['label'] as String,
                description: type['description'] as String,
                isSelected: isSelected,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.error, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Issue Type Icon
class _IssueTypeIcon extends StatelessWidget {
  final IconData icon;

  const _IssueTypeIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.error, size: 24),
    );
  }
}

/// Issue Type Info
class _IssueTypeInfo extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;

  const _IssueTypeInfo({
    required this.label,
    required this.description,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.error : AppColors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
        ),
      ],
    );
  }
}
