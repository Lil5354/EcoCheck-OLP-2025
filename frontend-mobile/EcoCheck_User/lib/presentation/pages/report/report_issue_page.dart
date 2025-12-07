/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'package:flutter/material.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/presentation/widgets/buttons/primary_button.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';
import 'widgets/issue_type_selector.dart';
import 'widgets/photo_picker.dart';

/// Report Issue Page - Báo cáo sự cố & sai phạm
class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String _selectedIssueType = 'illegal_dump'; // illegal_dump, violation, other
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _photosPaths = []; // Mock photo paths

  // Mock GPS
  final double _latitude = 10.762622;
  final double _longitude = 106.660172;
  final String _address = '123 Nguyễn Huệ, Q1, TP.HCM';

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo Sự cố')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.report_problem,
                    color: AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Góp phần giữ gìn môi trường',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Báo cáo giúp cải thiện dịch vụ thu gom',
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

            const SizedBox(height: 24),

            // Issue type
            Text('1. Loại sự cố *', style: AppTextStyles.h5),
            const SizedBox(height: 12),

            IssueTypeSelector(
              selectedType: _selectedIssueType,
              onChanged: (value) {
                setState(() {
                  _selectedIssueType = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // Photos
            Text('2. Hình ảnh *', style: AppTextStyles.h5),
            const SizedBox(height: 4),
            Text(
              'Chụp ảnh hiện trường để minh chứng',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 12),

            PhotoPicker(
              photos: _photosPaths,
              onAddPhoto: _addPhoto,
              onRemovePhoto: (index) {
                setState(() {
                  _photosPaths.removeAt(index);
                });
              },
            ),

            const SizedBox(height: 24),

            // Location
            Text('3. Vị trí *', style: AppTextStyles.h5),
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
                        Icons.location_on,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Vị trí GPS đã được gắn',
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

            const SizedBox(height: 24),

            // Description
            Text('4. Mô tả chi tiết', style: AppTextStyles.h5),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết về sự cố...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.white,
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            PrimaryButton(
              text: 'Gửi báo cáo',
              icon: Icons.send,
              onPressed: _submitReport,
            ),
          ],
        ),
      ),
    );
  }

  void _addPhoto() {
    // Mock add photo
    setState(() {
      _photosPaths.add('photo_${_photosPaths.length + 1}.jpg');
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã thêm ảnh (mock)')));
  }

  Future<void> _submitReport() async {
    if (_photosPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng thêm ít nhất 1 ảnh')),
      );
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
      'Báo cáo đã được gửi!',
      'Cảm ơn bạn đã góp phần cải thiện môi trường. Chúng tôi sẽ xử lý trong thời gian sớm nhất.',
      onConfirm: () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.of(context).pop(); // Back
      },
    );
  }
}
