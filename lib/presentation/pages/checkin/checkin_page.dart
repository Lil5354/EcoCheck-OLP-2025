import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/widgets/buttons/primary_button.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';
import 'widgets/waste_type_selector.dart';
import 'widgets/weight_selector.dart';

/// Check-in Page - Chức năng cốt lõi "Tôi có rác"
class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  String _selectedWasteType = 'household'; // household, recyclable, bulky
  String _selectedWeight = 'medium'; // small, medium, large

  // Mock GPS location
  final double _latitude = 10.762622;
  final double _longitude = 106.660172;
  final String _address = '123 Nguyễn Huệ, Q1, TP.HCM';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Rác'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tôi có rác!',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Giúp hệ thống biết bạn có rác cần thu gom',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Loại rác
            Text('1. Loại rác *', style: AppTextStyles.h5),
            const SizedBox(height: 4),
            Text(
              'Chọn loại rác bạn cần thu gom',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 12),

            WasteTypeSelector(
              selectedType: _selectedWasteType,
              onChanged: (value) {
                setState(() {
                  _selectedWasteType = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Khối lượng
            Text('2. Khối lượng ước tính *', style: AppTextStyles.h5),
            const SizedBox(height: 4),
            Text(
              'Ước tính số lượng rác',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 12),

            WeightSelector(
              selectedWeight: _selectedWeight,
              onChanged: (value) {
                setState(() {
                  _selectedWeight = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Vị trí
            Text('3. Vị trí của bạn', style: AppTextStyles.h5),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đã lấy vị trí GPS',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_address, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_latitude.toStringAsFixed(6)}, Long: ${_longitude.toStringAsFixed(6)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Rewards info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: AppColors.warning, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phần thưởng',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRewardText(),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            PrimaryButton(
              text: 'Check-in ngay',
              icon: Icons.check_circle,
              onPressed: _submitCheckIn,
            ),

            const SizedBox(height: 16),

            // Info text
            Center(
              child: Text(
                'Dữ liệu sẽ được gửi đến hệ thống theo thời gian thực',
                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRewardText() {
    int points = 10;
    if (_selectedWasteType == 'recyclable') {
      points = 20;
    } else if (_selectedWasteType == 'bulky') {
      points = 30;
    }

    if (_selectedWeight == 'large') {
      points += 10;
    }

    return '+$points điểm xanh khi xe đến thu gom';
  }

  Future<void> _submitCheckIn() async {
    // Show loading
    showLoadingDialog(context);

    // Mock API call - send to FIWARE Orion Context Broker
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Hide loading
    Navigator.of(context).pop();

    // Show success
    showSuccessDialog(
      context,
      'Check-in thành công!',
      'Dữ liệu đã được gửi lên hệ thống. Bạn sẽ nhận thông báo khi xe rác đến gần.',
      onConfirm: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Back to home
      },
    );
  }
}
