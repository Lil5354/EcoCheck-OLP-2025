import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:eco_check/presentation/widgets/buttons/primary_button.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';
import 'widgets/schedule_waste_type_selector.dart';
import 'widgets/time_slot_selector.dart';

class CreateSchedulePage extends StatefulWidget {
  const CreateSchedulePage({super.key});

  @override
  State<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends State<CreateSchedulePage> {
  final _formKey = GlobalKey<FormState>();

  String _selectedWasteType = AppConstants.wasteTypeOrganic;
  String _selectedTimeSlot = AppConstants.timeSlotMorning;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  double _estimatedWeight = 5.0;
  String _address = '123 Nguyễn Huệ, Quận 1, TP.HCM';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lịch thu gom')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Waste Type Selection
            Text('Loại rác', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            ScheduleWasteTypeSelector(
              selectedType: _selectedWasteType,
              onChanged: (value) {
                setState(() {
                  _selectedWasteType = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Date Selection
            Text('Ngày thu gom', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(_selectedDate),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Time Slot Selection
            Text('Khung giờ', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            TimeSlotSelector(
              selectedSlot: _selectedTimeSlot,
              onChanged: (value) {
                setState(() {
                  _selectedTimeSlot = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Weight Estimation
            Text('Khối lượng ước tính (kg)', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _estimatedWeight,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_estimatedWeight.toStringAsFixed(1)}kg',
                    onChanged: (value) {
                      setState(() {
                        _estimatedWeight = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_estimatedWeight.toStringAsFixed(1)}kg',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Address
            Text('Địa chỉ thu gom', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _address,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Nhập địa chỉ',
              ),
              maxLines: 2,
              onChanged: (value) {
                _address = value;
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập địa chỉ';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Notes
            Text('Ghi chú (tùy chọn)', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.note),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Thêm ghi chú nếu cần',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Submit Button
            PrimaryButton(text: 'Đặt lịch', onPressed: _submitSchedule),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submitSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading
    showLoadingDialog(context);

    // Mock API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Hide loading
    Navigator.of(context).pop();

    // Show success
    showSuccessDialog(
      context,
      'Đặt lịch thành công!',
      'Lịch thu gom của bạn đã được ghi nhận. Chúng tôi sẽ xác nhận trong thời gian sớm nhất.',
      onConfirm: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Back to list
      },
    );
  }
}
