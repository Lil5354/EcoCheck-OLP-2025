import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/app_constants.dart';
import 'package:eco_check/presentation/widgets/buttons/primary_button.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_bloc.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_event.dart';
import 'package:eco_check/presentation/blocs/schedule/schedule_state.dart';
import 'widgets/waste_type_selector.dart';

/// Create Waste Collection Request Page - Unified "Schedule" & "Check-in"
class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  // Waste type
  String _selectedWasteType = AppConstants.wasteTypeOrganic;

  // Weight estimation
  double _estimatedWeight = 5.0; // kg

  // Schedule date & time
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String _timeSlot = AppConstants.timeSlotMorning;

  // GPS location - will be fetched from device
  double? _latitude;
  double? _longitude;
  String _address = 'Đang lấy vị trí...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Get current GPS location from device
  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _address = 'Dịch vụ vị trí chưa được bật. Vui lòng bật GPS.';
          });
        }
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _address = 'Bạn cần cấp quyền truy cập vị trí';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _address =
                'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng bật trong Cài đặt.';
          });
        }
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }

      print('📍 [GPS] Location: $_latitude, $_longitude');

      // Convert GPS coordinates to address using Geocoding
      await _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      print('📍 [GPS] Error: $e');
      if (mounted) {
        setState(() {
          _address = 'Không thể lấy vị trí. Vui lòng thử lại.';
          // Set default location for testing (Ho Chi Minh City)
          _latitude = 10.762622;
          _longitude = 106.660172;
        });
      }
    }
  }

  /// Convert GPS coordinates to readable address
  Future<void> _getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final addressParts = <String>[];

        // Build address from components
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        final fullAddress = addressParts.isNotEmpty
            ? addressParts.join(', ')
            : '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

        setState(() {
          _address = fullAddress;
        });

        print('📍 [Geocoding] Address: $fullAddress');
      }
    } catch (e) {
      print('📍 [Geocoding] Error: $e');
      // Fallback to coordinates if geocoding fails
      if (mounted) {
        setState(() {
          _address =
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
        if (state is ScheduleCreating) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );
        } else if (state is ScheduleCreated) {
          Navigator.of(context).pop(); // Close loading
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Yêu cầu thành công!'),
              content: const Text(
                'Lịch thu gom đã được tạo. Bạn sẽ nhận thông báo khi xe rác được điều phối.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Back to home
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (state is ScheduleError) {
          Navigator.of(context).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yêu cầu thu gom rác'),
          centerTitle: true,
        ),
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
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đặt lịch thu gom rác tại nhà bạn',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 1. Loại rác
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

              // 2. Khối lượng ước tính
              Text('2. Khối lượng ước tính (kg) *', style: AppTextStyles.h5),
              const SizedBox(height: 4),
              Text(
                'Ước tính khối lượng rác',
                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
              ),
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

              const SizedBox(height: 32),

              // 3. Ngày thu gom
              Text('3. Ngày thu gom *', style: AppTextStyles.h5),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _scheduledDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() {
                      _scheduledDate = date;
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
                      const Icon(
                        Icons.calendar_today,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_scheduledDate),
                        style: AppTextStyles.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Khung giờ
              Text('4. Khung giờ *', style: AppTextStyles.h5),
              const SizedBox(height: 12),
              _buildTimeSlotSelector(),

              const SizedBox(height: 32),

              // 5. Vị trí
              Text('5. Vị trí của bạn', style: AppTextStyles.h5),
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
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${_latitude!.toStringAsFixed(6)}, Long: ${_longitude!.toStringAsFixed(6)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
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
                text: 'Tạo yêu cầu',
                icon: Icons.check_circle,
                onPressed: _submitRequest,
              ),

              const SizedBox(height: 16),

              // Info text
              Center(
                child: Text(
                  'Dữ liệu sẽ được gửi đến hệ thống và bạn sẽ nhận thông báo khi có xe được điều phối',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    final timeSlots = [
      {'value': AppConstants.timeSlotMorning, 'label': 'Sáng (6:00 - 11:00)'},
      {
        'value': AppConstants.timeSlotAfternoon,
        'label': 'Chiều (13:00 - 17:00)',
      },
      {'value': AppConstants.timeSlotEvening, 'label': 'Tối (17:00 - 20:00)'},
    ];

    return Column(
      children: timeSlots.map((slot) {
        final isSelected = _timeSlot == slot['value'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _timeSlot = slot['value'] as String;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: isSelected ? AppColors.primary : AppColors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  slot['label'] as String,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? AppColors.primary : AppColors.black,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    final weekday = weekdays[date.weekday % 7];
    return '$weekday, ${date.day}/${date.month}/${date.year}';
  }

  String _getRewardText() {
    int points = 10;
    if (_selectedWasteType == AppConstants.wasteTypeRecyclable) {
      points = 20;
    } else if (_selectedWasteType == AppConstants.wasteTypeHazardous) {
      points = 30;
    }

    if (_estimatedWeight >= 10) {
      points += 10;
    } else if (_estimatedWeight >= 20) {
      points += 20;
    }

    return '+$points điểm xanh khi thu gom hoàn tất';
  }

  void _submitRequest() {
    // Validate location is available
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang lấy vị trí GPS. Vui lòng thử lại.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Dispatch event to ScheduleBloc
    context.read<ScheduleBloc>().add(
      ScheduleCreateRequested(
        scheduledDate: _scheduledDate,
        timeSlot: _timeSlot,
        wasteType: _selectedWasteType,
        estimatedWeight: _estimatedWeight,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address,
      ),
    );
  }
}
