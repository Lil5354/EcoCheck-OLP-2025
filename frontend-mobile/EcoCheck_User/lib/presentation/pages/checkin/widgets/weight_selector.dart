/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';

/// Weight Selector Widget
class WeightSelector extends StatelessWidget {
  final String selectedWeight;
  final ValueChanged<String> onChanged;

  const WeightSelector({
    super.key,
    required this.selectedWeight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final weights = [
      {
        'id': 'small',
        'label': 'Ít',
        'description': '1 túi nhỏ',
        'icon': Icons.shopping_bag,
        'fillingLevel': 0.3,
      },
      {
        'id': 'medium',
        'label': 'Vừa',
        'description': '1-2 túi',
        'icon': Icons.shopping_basket,
        'fillingLevel': 0.6,
      },
      {
        'id': 'large',
        'label': 'Nhiều',
        'description': '≥3 túi / thùng',
        'icon': Icons.inventory,
        'fillingLevel': 0.9,
      },
    ];

    return Row(
      children: weights.map((weight) {
        final isSelected = selectedWeight == weight['id'];

        return Expanded(
          child: WeightCard(
            weight: weight,
            isSelected: isSelected,
            onTap: () => onChanged(weight['id'] as String),
          ),
        );
      }).toList(),
    );
  }
}

/// Weight Card Widget
class WeightCard extends StatelessWidget {
  final Map<String, dynamic> weight;
  final bool isSelected;
  final VoidCallback onTap;

  const WeightCard({
    super.key,
    required this.weight,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: weight['id'] != 'large' ? 8 : 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              weight['icon'] as IconData,
              color: isSelected ? AppColors.primary : AppColors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              weight['label'] as String,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              weight['description'] as String,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
