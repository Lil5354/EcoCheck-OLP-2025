import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Dialog xác nhận hoàn thành route với các thông tin chi tiết
class RouteCompletionDialog extends StatefulWidget {
  final int completedPoints;
  final int totalPoints;
  final Function(double? actualDistanceKm, String? notes) onConfirm;

  const RouteCompletionDialog({
    super.key,
    required this.completedPoints,
    required this.totalPoints,
    required this.onConfirm,
  });

  @override
  State<RouteCompletionDialog> createState() => _RouteCompletionDialogState();
}

class _RouteCompletionDialogState extends State<RouteCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon with gradient background
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.completed.withOpacity(0.2),
                        AppColors.completed.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.completed.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.celebration,
                    size: 45,
                    color: AppColors.completed,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  '🎉 Chúc mừng!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                // Message with badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.completed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.completed.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Đã hoàn thành',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${widget.completedPoints}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.completed,
                            ),
                          ),
                          Text(
                            '/${widget.totalPoints}',
                            style: TextStyle(
                              fontSize: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'điểm',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section title
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Thông tin chuyến đi (tùy chọn)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Distance input - Modern design
                TextFormField(
                  controller: _distanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Quãng đường thực tế (km)',
                    hintText: 'Ví dụ: 15.5',
                    prefixIcon: const Icon(Icons.route),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final distance = double.tryParse(value);
                    if (distance == null || distance <= 0) {
                      return 'Quãng đường không hợp lệ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Notes input
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    hintText: 'Nhập ghi chú về chuyến đi...',
                    prefixIcon: const Icon(Icons.note_alt),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final distance = _distanceController.text.isNotEmpty
                                ? double.tryParse(_distanceController.text)
                                : null;
                            final notes = _notesController.text.isNotEmpty
                                ? _notesController.text
                                : null;

                            Navigator.pop(context);
                            widget.onConfirm(distance, notes);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.completed,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Hoàn thành',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function
Future<void> showRouteCompletionDialog({
  required BuildContext context,
  required int completedPoints,
  required int totalPoints,
  required Function(double? actualDistanceKm, String? notes) onConfirm,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => RouteCompletionDialog(
      completedPoints: completedPoints,
      totalPoints: totalPoints,
      onConfirm: onConfirm,
    ),
  );
}
