/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import '../../../data/models/worker_route.dart';

class ShiftIndicator extends StatelessWidget {
  final WorkerRoute route;

  const ShiftIndicator({
    super.key,
    required this.route,
  });

  String _getShiftText() {
    return route.getShiftName();
  }

  Color _getShiftColor() {
    final shift = _getShiftText().toLowerCase();
    if (shift.contains('sáng') || shift.contains('morning')) {
      return Colors.orange;
    } else if (shift.contains('chiều') || shift.contains('afternoon')) {
      return Colors.blue;
    } else {
      return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getShiftColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getShiftColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 14,
            color: _getShiftColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _getShiftText(),
            style: TextStyle(
              color: _getShiftColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

