/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 */

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:eco_check/core/network/api_client.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';
import 'package:eco_check/presentation/blocs/auth/auth_bloc.dart';
import 'package:eco_check/presentation/blocs/auth/auth_state.dart';
import 'package:eco_check/data/repositories/ecocheck_repository.dart';
import 'package:eco_check/data/services/image_upload_service.dart';

// Class to store photo metadata
class PhotoWithMetadata {
  final XFile photo;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? address;

  PhotoWithMetadata({
    required this.photo,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    this.address,
  });
}

class CreateSchedulePage extends StatefulWidget {
  const CreateSchedulePage({super.key});

  @override
  State<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends State<CreateSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final EcoCheckRepository _repository;
  final ImageUploadService _imageUploadService = ImageUploadService();

  String _selectedWasteType = AppConstants.wasteTypeOrganic;
  String _selectedTimeSlot = AppConstants.timeSlotMorning;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  double _estimatedWeight = 5.0;
  String _address = '';
  String _notes = '';
  List<PhotoWithMetadata> _photos = [];

  @override
  void initState() {
    super.initState();
    _repository = EcoCheckRepository(ApiClient());
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  Future<void> _takePhoto() async {
    try {
      // Get current location before taking photo
      final position = await _getCurrentLocation();

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        final photoWithMetadata = PhotoWithMetadata(
          photo: photo,
          capturedAt: DateTime.now(),
          latitude: position?.latitude,
          longitude: position?.longitude,
        );

        setState(() {
          _photos.add(photoWithMetadata);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã chụp ảnh ${_photos.length}/3${position != null ? " (có vị trí GPS)" : ""}',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chụp ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yêu cầu thu gom rác',
          style: TextStyle(color: AppColors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header with icon
            _buildHeader(),
            const SizedBox(height: 24),

            // Waste Type Selection
            _buildLabel('1. Loại rác *'),
            const SizedBox(height: 12),
            _buildWasteTypeCards(),
            const SizedBox(height: 24),

            // Weight Slider
            _buildLabel('2. Khối lượng ước tính (kg) *'),
            const SizedBox(height: 12),
            _buildWeightSliderNew(),
            const SizedBox(height: 24),

            // Date Picker
            _buildLabel('3. Ngày thu gom *'),
            const SizedBox(height: 12),
            _buildDatePickerNew(),
            const SizedBox(height: 24),

            // Time Slot Selection
            _buildLabel('4. Khung giờ *'),
            const SizedBox(height: 12),
            _buildTimeSlotCards(),
            const SizedBox(height: 24),

            // Address
            _buildLabel('5. Vị trí của bạn'),
            const SizedBox(height: 12),
            _buildAddressCard(),
            const SizedBox(height: 24),

            // Photo Upload
            _buildLabel('6. Hình ảnh rác (tùy chọn)'),
            const SizedBox(height: 12),
            _buildPhotoSection(),
            const SizedBox(height: 24),

            // Reward Info
            _buildRewardCard(),
            const SizedBox(height: 32),

            // Submit Button
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tôi có rác!',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Đặt lịch thu gom rác tại nhà bạn',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.black,
      ),
    );
  }

  Widget _buildWasteTypeCards() {
    final types = [
      {
        'id': AppConstants.wasteTypeOrganic,
        'label': 'Rác sinh hoạt',
        'sublabel': 'Rác hữu cơ, thực phẩm',
        'icon': Icons.eco,
        'color': AppColors.wasteOrganic,
      },
      {
        'id': AppConstants.wasteTypeRecyclable,
        'label': 'Rác tái chế',
        'sublabel': 'Giấy, nhựa, kim loại, thủy tinh',
        'icon': Icons.recycling,
        'color': AppColors.wasteRecyclable,
      },
      {
        'id': AppConstants.wasteTypeHazardous,
        'label': 'Rác công nghiệp',
        'sublabel': 'Hóa chất, pin, thuốc trừ sâu',
        'icon': Icons.warning,
        'color': AppColors.wasteHazardous,
      },
    ];

    return Column(
      children: types.map((type) {
        final isSelected = _selectedWasteType == type['id'];
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedWasteType = type['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? (type['color'] as Color).withOpacity(0.12)
                  : AppColors.lightGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? (type['color'] as Color)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (type['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    type['icon'] as IconData,
                    color: type['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type['label'] as String,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['sublabel'] as String,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: type['color'] as Color,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeightSliderNew() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.scale, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                '${_estimatedWeight.toStringAsFixed(1)} kg',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _estimatedWeight,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.primary.withOpacity(0.2),
            onChanged: (value) {
              setState(() => _estimatedWeight = value);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 kg',
                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
              ),
              Text(
                '50 kg',
                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerNew() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Text(
              'T${_selectedDate.weekday}, ${_formatDate(_selectedDate)}',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCards() {
    final slots = [
      {
        'id': AppConstants.timeSlotMorning,
        'label': 'Sáng (6:00 - 11:00)',
        'icon': Icons.wb_sunny,
      },
      {
        'id': AppConstants.timeSlotAfternoon,
        'label': 'Chiều (13:00 - 17:00)',
        'icon': Icons.wb_twilight,
      },
      {
        'id': AppConstants.timeSlotEvening,
        'label': 'Tối (17:00 - 20:00)',
        'icon': Icons.nights_stay,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: slots.map((slot) {
          final isSelected = _selectedTimeSlot == slot['id'];
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedTimeSlot = slot['id'] as String),
            child: Container(
              margin: const EdgeInsets.all(4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    slot['icon'] as IconData,
                    color: isSelected ? AppColors.white : AppColors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    slot['label'] as String,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected ? AppColors.white : AppColors.black,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vị trí vứt rác',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1600 Amphitheatre Pkwy, Mountain View, California',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: 37.421998 Long: -122.084056',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phần thưởng',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+10 điểm khi rác được hoàn thu gom',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _submitSchedule,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 24),
            const SizedBox(width: 12),
            Text(
              'Tạo yêu cầu',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Requirement notice
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _photos.isEmpty
                ? AppColors.error.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _photos.isEmpty
                  ? AppColors.error.withOpacity(0.3)
                  : AppColors.success.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _photos.isEmpty ? Icons.warning : Icons.check_circle,
                size: 20,
                color: _photos.isEmpty ? AppColors.error : AppColors.success,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _photos.isEmpty
                      ? 'Bắt buộc: Chụp từ 1-3 ảnh hiện trường rác thải'
                      : 'Đã chụp ${_photos.length}/3 ảnh',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _photos.isEmpty
                        ? AppColors.error
                        : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Display photos with metadata
        if (_photos.isNotEmpty) ...[
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                final photoData = _photos[index];
                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      // Photo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(photoData.photo.path),
                          width: 160,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Dark overlay for metadata
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Time
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      dateFormat.format(photoData.capturedAt),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // GPS Location
                              Row(
                                children: [
                                  Icon(
                                    photoData.latitude != null
                                        ? Icons.location_on
                                        : Icons.location_off,
                                    size: 12,
                                    color: photoData.latitude != null
                                        ? Colors.greenAccent
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      photoData.latitude != null
                                          ? '${photoData.latitude!.toStringAsFixed(5)}, ${photoData.longitude!.toStringAsFixed(5)}'
                                          : 'Không có GPS',
                                      style: TextStyle(
                                        color: photoData.latitude != null
                                            ? Colors.greenAccent
                                            : Colors.grey,
                                        fontSize: 9,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Delete button
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removePhoto(index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Photo counter
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${index + 1}/${_photos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Camera button only (no gallery option)
        if (_photos.length < 3)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt, size: 24),
              label: Text(
                _photos.isEmpty
                    ? 'Chụp ảnh hiện trường (Bắt buộc)'
                    : 'Chụp thêm ảnh (${_photos.length}/3)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _photos.isEmpty
                    ? AppColors.error
                    : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submitSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate photos are required
    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp ít nhất 1 ảnh hiện trường rác thải'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Get current user from AuthBloc
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn cần đăng nhập để đặt lịch'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    final user = authState.user;

    // Show loading
    showLoadingDialog(context);

    try {
      // Upload images to backend
      List<String> photoUrls = [];
      print('📤 Uploading ${_photos.length} images with metadata...');
      try {
        // Convert PhotoWithMetadata to File
        final imageFiles = _photos
            .map((photoData) => File(photoData.photo.path))
            .toList();
        photoUrls = await _imageUploadService.uploadMultipleImages(imageFiles);
        print('✅ Images uploaded: ${photoUrls.length} URLs received');
        // Log metadata for debugging
        for (var i = 0; i < _photos.length; i++) {
          print(
            '  Photo $i: ${_photos[i].capturedAt} @ (${_photos[i].latitude}, ${_photos[i].longitude})',
          );
        }
      } catch (e) {
        print('❌ Image upload failed: $e');
        if (!mounted) return;
        Navigator.of(context).pop(); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh lên: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get user's location (use default if not available)
      final latitude = user.latitude ?? 10.762622;
      final longitude = user.longitude ?? 106.660172;

      // Create schedule via repository
      print('📤 Creating schedule...');
      final schedule = await _repository.createSchedule(
        citizenId: user.id,
        scheduledDate: _selectedDate,
        timeSlot: _selectedTimeSlot,
        wasteType: _selectedWasteType,
        estimatedWeight: _estimatedWeight,
        address: _address.isEmpty
            ? (user.address ?? 'Địa chỉ chưa cập nhật')
            : _address,
        latitude: latitude,
        longitude: longitude,
        notes: _notes.isEmpty ? null : _notes,
        photoUrls: photoUrls.isEmpty ? null : photoUrls,
      );

      print('✅ Schedule created: ${schedule.id}');

      if (!mounted) return;

      // Hide loading
      Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;

      // Show success message with SnackBar instead
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đặt lịch thành công! Lịch thu gom đã được tạo với ${photoUrls.length} ảnh hiện trường.',
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back to list
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      print('❌ Schedule creation failed: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // Hide loading

      // Extract clean error message
      String errorMessage = e.toString();
      if (errorMessage.contains('Exception: ')) {
        errorMessage = errorMessage.replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $errorMessage'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Đóng',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}
