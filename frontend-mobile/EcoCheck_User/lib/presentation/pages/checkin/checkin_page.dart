/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - EcoCheck User
 * Check-in Page with AI Image Analysis
 */

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:eco_check/core/constants/color_constants.dart';
import 'package:eco_check/core/constants/text_constants.dart';
import 'package:eco_check/core/constants/api_constants.dart';
import 'package:eco_check/core/utils/image_helper.dart';
import 'package:eco_check/presentation/widgets/buttons/primary_button.dart';
import 'package:eco_check/presentation/widgets/dialogs/dialogs.dart';
import 'package:eco_check/data/services/image_upload_service.dart';
import 'package:eco_check/data/services/ai_waste_analysis_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'widgets/waste_type_selector.dart';
import 'widgets/weight_selector.dart';
import '../report/report_issue_page.dart';

/// Check-in Page - Chức năng cốt lõi "Tôi có rác"
class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  String _selectedWasteType = 'household'; // household, recyclable, bulky
  String _selectedWeight = 'medium'; // small, medium, large

  // Location (chỉ lấy 1 lần duy nhất khi vào page)
  double? _latitude;
  double? _longitude;
  String _address = 'Đang lấy vị trí...';
  bool _isLoadingLocation = true;

  // Image
  File? _selectedImage;
  XFile? _selectedImageXFile; // For Web platform
  String? _uploadedImageUrl;
  bool _isUploading = false;

  // AI Analysis
  bool _isAnalyzing = false;
  String? _aiAnalysisDescription;
  WasteAnalysisResult? _aiResult;

  final ImageUploadService _imageService = ImageUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _address = 'Vui lòng bật định vị';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _address = 'Quyền truy cập vị trí bị từ chối';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Reverse geocoding
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _address = [
              place.street,
              place.subLocality,
              place.locality,
            ].where((s) => s != null && s.isNotEmpty).join(', ');
          });
        }
      } catch (e) {
        setState(() {
          _address =
              '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Không thể lấy vị trí';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn nguồn ảnh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );

      if (image != null) {
        if (kDebugMode) {
          print('📸 [Image] Selected image: ${image.name}, path: ${image.path}');
        }

        setState(() {
          // Handle Web vs Mobile differently
          if (kIsWeb) {
            _selectedImageXFile = image; // Lưu XFile cho Web
            _selectedImage = null;
          } else {
            _selectedImage = File(image.path);
            _selectedImageXFile = null;
          }
          _uploadedImageUrl = null;
          _aiAnalysisDescription = null;
          _aiResult = null;
        });

        // Analyze image with AI
        await _analyzeImageWithAI(image);
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) {
          print('❌ [Image] Error picking image: $e');
        }
        showErrorDialog(
          context,
          title: 'Lỗi',
          message:
              'Không thể ${source == ImageSource.camera ? 'chụp' : 'chọn'} ảnh: $e',
        );
      }
    }
  }

  /// Analyze image with AI and auto-fill form
  Future<void> _analyzeImageWithAI(XFile image) async {
    if (kDebugMode) {
      print('🤖 [AI] Starting analysis for image: ${image.name}');
    }

    setState(() {
      _isAnalyzing = true;
      _aiAnalysisDescription = null;
    });

    try {
      final result = await AIWasteAnalysisService.analyzeImage(image);

      if (kDebugMode) {
        print('🤖 [AI] Analysis result:');
        print('  - Waste Type: ${result.wasteType}');
        print('  - Weight: ${result.weightCategory}');
        print('  - Estimated Weight: ${result.estimatedWeightKg}kg');
        print('  - Confidence: ${result.confidence}');
        print('  - Description: ${result.description}');
      }

      // Validate weight - nếu > 50kg thì hiển thị thông báo
      if (result.estimatedWeightKg != null && result.estimatedWeightKg! > 50) {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });
          
          // Hiển thị dialog thông báo
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Rác vượt quy định')),
                ],
              ),
              content: const Text(
                'Đối với rác vượt ngoài quy định (trên 50kg), bạn có thể gửi đến "Báo cáo sự cố" để được xử lý.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to Report Issue page
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReportIssuePage(),
                      ),
                    );
                  },
                  child: const Text('Đến Báo cáo sự cố'),
                ),
              ],
            ),
          );
        }
        return; // Dừng xử lý, không auto-fill form
      }

      if (mounted) {
        if (kDebugMode) {
          print('🤖 [AI] Before setState:');
          print('  - Current wasteType: $_selectedWasteType');
          print('  - Current weight: $_selectedWeight');
          print('  - New wasteType: ${result.wasteType}');
          print('  - New weight: ${result.weightCategory}');
        }

        setState(() {
          _isAnalyzing = false;
          _aiResult = result;
          _aiAnalysisDescription = result.description;

          // Auto-fill form based on AI result
          _selectedWasteType = result.wasteType;
          _selectedWeight = result.weightCategory;
        });

        if (kDebugMode) {
          print('🤖 [AI] After setState:');
          print('  - _selectedWasteType: $_selectedWasteType');
          print('  - _selectedWeight: $_selectedWeight');
          print('  - _aiResult: $_aiResult');
          print('  - _aiAnalysisDescription: $_aiAnalysisDescription');
        }

        // Show success message if AI analysis was successful
        if (result.confidence > 0.3) {
          // Giảm threshold từ 0.5 xuống 0.3 để hiển thị thông báo nhiều hơn
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.description ?? 'AI đã phân tích ảnh và tự động điền form!',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        if (kDebugMode) {
          print('❌ [AI] Analysis Error: $e');
          print('Stack trace: $stackTrace');
        }
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI phân tích thất bại, vui lòng nhập thủ công'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user_id: $e');
      }
      return null;
    }
  }

  Future<void> _submitCheckIn() async {
    if (_selectedImage == null && _selectedImageXFile == null && _uploadedImageUrl == null) {
      showErrorDialog(
        context,
        title: 'Thiếu ảnh',
        message: 'Vui lòng chụp ảnh hoặc chọn ảnh rác trước khi check-in',
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      showErrorDialog(
        context,
        title: 'Thiếu vị trí',
        message: 'Vui lòng đợi hệ thống lấy vị trí của bạn',
      );
      return;
    }

    // Get user_id
    final userId = await _getUserId();
    if (userId == null || userId.isEmpty) {
      showErrorDialog(context, title: 'Lỗi', message: 'Vui lòng đăng nhập');
      return;
    }

    if (mounted) {
      showLoadingDialog(context, message: 'Đang gửi check-in...');
    }

    try {
      // Calculate filling_level and weight from selector
      double fillingLevel = 0.5;
      double estimatedWeight = 2.0;

      if (_selectedWeight == 'small') {
        fillingLevel = 0.3;
        estimatedWeight = 1.0;
      } else if (_selectedWeight == 'medium') {
        fillingLevel = 0.5;
        estimatedWeight = 2.0;
      } else if (_selectedWeight == 'large') {
        fillingLevel = 0.8;
        estimatedWeight = 5.0;
      }

      // Upload image if not already uploaded
      String? finalImageUrl = _uploadedImageUrl;
      if (finalImageUrl == null) {
        if (_selectedImage != null) {
          finalImageUrl = await _imageService.uploadImage(_selectedImage!);
        } else if (_selectedImageXFile != null) {
          // For Web, convert XFile to File temporarily for upload
          // Note: This might need adjustment based on your upload service
          if (kDebugMode) {
            print('⚠️ [Upload] XFile upload on Web - may need special handling');
          }
          // Try to upload XFile directly if service supports it
          // Otherwise, you may need to modify ImageUploadService to accept XFile
        }
      }

      // Submit check-in
      final baseUrl = ApiConstants.baseUrl;
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/user/checkin'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'waste_type': _selectedWasteType,
              'filling_level': fillingLevel,
              'estimated_weight_kg': estimatedWeight,
              'photo_url': finalImageUrl,
              'latitude': _latitude,
              'longitude': _longitude,
              'address': _address,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          if (mounted) {
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
        } else {
          throw Exception(data['error'] ?? 'Check-in thất bại');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          errorData['error'] ?? 'Lỗi server: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        showErrorDialog(
          context,
          title: 'Lỗi',
          message: 'Check-in thất bại: $e',
        );
      }
    }
  }

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
                    'Chụp ảnh rác và thêm thông tin để gửi yêu cầu thu gom',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Image Capture Section
            Text('0. Chụp/Chọn ảnh rác *', style: AppTextStyles.h5),
            const SizedBox(height: 4),
            Text(
              'Chụp ảnh mới hoặc chọn ảnh có sẵn từ thư viện',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: (_selectedImage != null || _selectedImageXFile != null)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ImageHelper.buildImage(
                              imageSource: _selectedImage ?? _selectedImageXFile!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // AI Analysis indicator
                          if (_isAnalyzing)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'AI đang phân tích...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // AI Result badge
                          if (_aiResult != null && !_isAnalyzing)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI: ${(_aiResult!.confidence * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Change image button
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: FloatingActionButton.small(
                              onPressed: _showImageSourceDialog,
                              backgroundColor: AppColors.primary,
                              child: const Icon(Icons.camera_alt),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 64,
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chạm để chụp/chọn ảnh',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI sẽ tự động phân tích và điền form',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // AI Analysis Description
            if (_aiAnalysisDescription != null && !_isAnalyzing) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _aiAnalysisDescription!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Loại rác
            Text('1. Loại rác *', style: AppTextStyles.h5),
            if (kDebugMode && _aiResult != null)
              Text(
                '🤖 AI đã chọn: $_selectedWasteType',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            const SizedBox(height: 12),
            WasteTypeSelector(
              key: ValueKey('waste_$_selectedWasteType'), // Force rebuild when value changes
              selectedType: _selectedWasteType,
              onChanged: (value) {
                if (kDebugMode) {
                  print('👤 [User] Manually changed waste type to: $value');
                }
                setState(() {
                  _selectedWasteType = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Khối lượng ước tính *
            Text('2. Khối lượng ước tính *', style: AppTextStyles.h5),
            if (kDebugMode && _aiResult != null)
              Text(
                '🤖 AI đã chọn: $_selectedWeight',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            const SizedBox(height: 12),
            WeightSelector(
              key: ValueKey('weight_$_selectedWeight'), // Force rebuild when value changes
              selectedWeight: _selectedWeight,
              onChanged: (value) {
                if (kDebugMode) {
                  print('👤 [User] Manually changed weight to: $value');
                }
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
              child: _isLoadingLocation
                  ? const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Đang lấy vị trí...'),
                      ],
                    )
                  : Column(
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
                        if (_latitude != null && _longitude != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Lat: ${_latitude!.toStringAsFixed(6)}, Long: ${_longitude!.toStringAsFixed(6)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.grey,
                              ),
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
              text: _isUploading ? 'Đang xử lý...' : 'Check-in ngay',
              icon: Icons.check_circle,
              onPressed: _isUploading ? null : _submitCheckIn,
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
}
