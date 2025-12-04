/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck Worker
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../../../data/services/image_upload_service.dart';
import '../../../data/repositories/ecocheck_repository.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/constants/color_constants.dart';

class CreateReportDialog extends StatefulWidget {
  final String category; // 'violation' or 'damage'

  const CreateReportDialog({super.key, required this.category});

  @override
  State<CreateReportDialog> createState() => _CreateReportDialogState();
}

class _CreateReportDialogState extends State<CreateReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _imageUploadService = ImageUploadService();
  final _repository = di.sl<EcoCheckRepository>();

  String? _selectedType;
  late List<File> _images;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    _images = [];
    // Auto fetch GPS location when dialog opens
    _getCurrentLocation();
    print('🖼️ CreateReportDialog initialized - Category: ${widget.category}');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  List<String> get _typeOptions {
    if (widget.category == 'violation') {
      return [
        'illegal_dump',
        'wrong_classification',
        'overloaded_bin',
        'littering',
        'burning_waste',
        'worker_not_collected',
      ];
    } else {
      return [
        'broken_bin',
        'damaged_equipment',
        'road_damage',
        'facility_damage',
      ];
    }
  }

  String _getTypeLabel(String type) {
    const typeMap = {
      // Violations
      'illegal_dump': 'Vứt rác trái phép',
      'wrong_classification': 'Phân loại sai',
      'overloaded_bin': 'Thùng rác quá tải',
      'littering': 'Xả rác bừa bãi',
      'burning_waste': 'Đốt rác',
      'worker_not_collected': 'Nhân viên không dọn rác',
      // Damages
      'broken_bin': 'Thùng rác hỏng',
      'damaged_equipment': 'Thiết bị hư hỏng',
      'road_damage': 'Đường bị hư',
      'facility_damage': 'Cơ sở vật chất hư hỏng',
    };
    return typeMap[type] ?? type;
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() => _isLoadingLocation = true);
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            _currentAddress =
                '${place.street}, ${place.subAdministrativeArea}, ${place.administrativeArea}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi lấy vị trí: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _pickImages() async {
    print('🖼️ _pickImages called - Current images count: ${_images.length}');
    print('🖼️ Images paths: ${_images.map((f) => f.path).toList()}');

    if (_images.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tối đa 5 ảnh')));
      return;
    }

    // Show dialog to choose camera or gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn nguồn ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      print('🖼️ User cancelled source selection');
      return;
    }

    print('🖼️ User selected source: $source');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      print('🖼️ Picked file: ${pickedFile.path}');
      _images.add(File(pickedFile.path));
      print('🖼️ Image added - Total count: ${_images.length}');
      if (mounted) {
        setState(() {});
      }
    } else {
      print('🖼️ No file picked');
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại báo cáo')),
      );
      return;
    }

    // Validate that at least one image is uploaded
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp ít nhất 1 ảnh để xác nhận'),
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận gửi báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Loại: ${_getTypeLabel(_selectedType!)}'),
            const SizedBox(height: 8),
            Text('Số ảnh: ${_images.length}'),
            if (_currentAddress != null) ...[
              const SizedBox(height: 8),
              Text('Vị trí: $_currentAddress'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Bạn có chắc chắn muốn gửi báo cáo này?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
      _isUploadingImages = true;
    });

    try {
      print('📝 [Submit] Starting image upload...');
      // Upload images to server
      final imageUrls = await _imageUploadService.uploadMultipleImages(_images);

      if (mounted) {
        setState(() => _isUploadingImages = false);
      }

      print('📝 [Submit] Upload result: ${imageUrls.length} URLs received');

      if (imageUrls.isEmpty) {
        throw Exception(
          'Không thể tải ảnh lên. Vui lòng kiểm tra kết nối mạng và thử lại.',
        );
      }

      print('📝 [Submit] Getting user info from AuthBloc...');
      // Get user info from AuthBloc
      String userId = 'guest_user';
      String? userName;
      String? userPhone;

      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        userId = authState.user.id;
        userName = authState.user.fullName;
        userPhone = authState.user.phone;
        print('📝 [Submit] User: $userName ($userId)');
      }

      print('📝 [Submit] Creating incident report...');
      // Call API to create incident report
      final incident = await _repository.createIncident(
        reporterId: userId,
        reporterName: userName,
        reporterPhone: userPhone,
        reportCategory: widget.category,
        type: _selectedType!,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : 'Báo cáo ${widget.category == "violation" ? "vi phạm" : "hư hỏng"}',
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        locationAddress: _currentAddress,
        imageUrls: imageUrls,
        priority: 'medium',
      );

      print('✅ [Submit] Incident created successfully: ${incident['id']}');

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Báo cáo đã được gửi thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [Submit] Error: $e');
      if (mounted) {
        // Show user-friendly error message
        String errorMessage = 'Lỗi gửi báo cáo';

        if (e.toString().contains('Failed host lookup') ||
            e.toString().contains('SocketException')) {
          errorMessage =
              'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng.';
        } else if (e.toString().contains('upload')) {
          errorMessage = 'Lỗi tải ảnh lên. Vui lòng thử lại.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Yêu cầu quá thời gian. Vui lòng thử lại.';
        } else {
          errorMessage = 'Lỗi: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploadingImages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.category == 'violation'
                        ? Icons.warning_amber_rounded
                        : Icons.build_circle_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.category == 'violation'
                          ? 'Báo cáo vi phạm'
                          : 'Báo cáo hư hỏng',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type selection
                      const Text(
                        'Loại báo cáo *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('Chọn loại'),
                        items: _typeOptions.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeLabel(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (mounted) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Description with helper text
                      const Text(
                        'Mô tả chi tiết *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mô tả rõ ràng giúp xử lý nhanh hơn (tối thiểu 10 ký tự)',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'Ví dụ: Thùng rác bị đầy tràn, có mùi hôi, cần xử lý gấp...',
                          counterText: '',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập mô tả';
                          }
                          if (value.trim().length < 10) {
                            return 'Mô tả phải có ít nhất 10 ký tự';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Location
                      const Text(
                        'Vị trí',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_currentAddress != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _currentAddress!,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: _isLoadingLocation
                            ? null
                            : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          _currentAddress == null
                              ? 'Lấy vị trí hiện tại'
                              : 'Cập nhật vị trí',
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Images section with better UI
                      Row(
                        children: [
                          const Text(
                            'Hình ảnh *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _images.isEmpty
                                  ? Colors.red[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_images.length}/5',
                              style: TextStyle(
                                fontSize: 12,
                                color: _images.isEmpty
                                    ? Colors.red[700]
                                    : Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chụp ảnh hiện trường để minh chứng',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Vui lòng chụp ảnh hiện trường để xác nhận',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (_images.isNotEmpty) ...[
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_images[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: InkWell(
                                      onTap: () {
                                        _images.removeAt(index);
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
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
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_images.length < 5)
                        OutlinedButton.icon(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Thêm hình ảnh'),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isUploadingImages
                                    ? 'Đang tải ảnh...'
                                    : 'Đang gửi...',
                              ),
                            ],
                          )
                        : const Text('Gửi báo cáo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
