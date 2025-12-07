/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterChipBar extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onDateFilterTap;
  final VoidCallback? onClearAll;

  const FilterChipBar({
    super.key,
    this.startDate,
    this.endDate,
    required this.onDateFilterTap,
    this.onClearAll,
  });

  bool get hasActiveFilter => startDate != null || endDate != null;

  @override
  Widget build(BuildContext context) {
    if (!hasActiveFilter && onClearAll == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (hasActiveFilter)
            InkWell(
              onTap: onDateFilterTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.date_range, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      startDate != null && endDate != null
                          ? '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}'
                          : startDate != null
                              ? 'Từ ${DateFormat('dd/MM').format(startDate!)}'
                              : 'Đến ${DateFormat('dd/MM').format(endDate!)}',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hasActiveFilter && onClearAll != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onClearAll,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.clear, size: 16, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}



