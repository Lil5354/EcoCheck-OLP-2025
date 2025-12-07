/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Air Quality Widget - Displays air quality indicator for Worker
 */

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/ecocheck_repository.dart';
import '../../../core/di/injection_container.dart';

class AirQualityWidget extends StatefulWidget {
  const AirQualityWidget({super.key});

  @override
  State<AirQualityWidget> createState() => _AirQualityWidgetState();
}

class _AirQualityWidgetState extends State<AirQualityWidget> {
  Map<String, dynamic>? _aqiData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAirQuality();
  }

  Future<void> _loadAirQuality() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final repository = getIt<EcoCheckRepository>();
      final aqiData = await repository.getAirQuality(
        lat: position.latitude,
        lon: position.longitude,
      );

      setState(() {
        _aqiData = aqiData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getAQIColor(int? aqi) {
    if (aqi == null) return AppColors.grey;
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }

  IconData _getAQIIcon(int? aqi) {
    if (aqi == null) return Icons.help_outline;
    if (aqi <= 50) return Icons.air;
    if (aqi <= 100) return Icons.air_outlined;
    if (aqi <= 150) return Icons.warning_amber_rounded;
    if (aqi <= 200) return Icons.warning;
    if (aqi <= 300) return Icons.dangerous;
    return Icons.dangerous;
  }

  String _getAQICategory(String? category) {
    if (category == null) return 'Không xác định';
    switch (category) {
      case 'Good':
        return 'Tốt';
      case 'Moderate':
        return 'Trung bình';
      case 'Unhealthy for Sensitive Groups':
        return 'Không tốt cho nhóm nhạy cảm';
      case 'Unhealthy':
        return 'Không tốt';
      case 'Very Unhealthy':
        return 'Rất không tốt';
      case 'Hazardous':
        return 'Nguy hiểm';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Đang tải...',
              style: TextStyle(fontSize: 12, color: AppColors.white),
            ),
          ],
        ),
      );
    }

    if (_error != null || _aqiData == null) {
      return GestureDetector(
        onTap: _loadAirQuality,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, size: 16, color: AppColors.white),
              SizedBox(width: 8),
              Text(
                'Không thể tải dữ liệu',
                style: TextStyle(fontSize: 12, color: AppColors.white),
              ),
            ],
          ),
        ),
      );
    }

    final aqi = _aqiData?['aqi'] as int?;
    final category = _aqiData?['category'] as String?;
    final pm25 = _aqiData?['pm25'] as double?;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Chất lượng không khí'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AQI: ${aqi ?? "N/A"}'),
                Text('PM2.5: ${pm25?.toStringAsFixed(1) ?? "N/A"} μg/m³'),
                Text('Mức độ: ${_getAQICategory(category)}'),
                if (_aqiData?['location'] != null)
                  Text('Vị trí: ${_aqiData!['location']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getAQIColor(aqi).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getAQIColor(aqi).withOpacity(0.7),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getAQIIcon(aqi),
              size: 20,
              color: AppColors.white,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AQI: ${aqi ?? "N/A"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  _getAQICategory(category),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

