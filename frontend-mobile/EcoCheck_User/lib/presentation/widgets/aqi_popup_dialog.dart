/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * AQI Popup Dialog - Shows air quality recommendation
 */

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/text_constants.dart';
import '../../data/services/air_quality_service.dart';

/// AQI Popup Dialog Widget
class AQIPopupDialog extends StatelessWidget {
  final AirQualityData aqiData;

  const AQIPopupDialog({
    super.key,
    required this.aqiData,
  });

  /// Show AQI popup dialog
  static Future<void> show(
    BuildContext context,
    AirQualityData aqiData,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AQIPopupDialog(aqiData: aqiData);
      },
    );
  }

  /// Get AQI color
  Color _getAQIColor() {
    switch (aqiData.category.toLowerCase()) {
      case 'good':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'unhealthy for sensitive groups':
        return Colors.deepOrange;
      case 'unhealthy':
        return Colors.red;
      case 'very unhealthy':
        return Colors.purple;
      case 'hazardous':
        return const Color(0xFF7E0023); // Maroon
      default:
        return AppColors.grey;
    }
  }

  /// Get AQI icon
  IconData _getAQIIcon() {
    switch (aqiData.category.toLowerCase()) {
      case 'good':
        return Icons.check_circle;
      case 'moderate':
        return Icons.info;
      case 'unhealthy for sensitive groups':
        return Icons.warning;
      case 'unhealthy':
      case 'very unhealthy':
      case 'hazardous':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aqiColor = _getAQIColor();
    final aqiIcon = _getAQIIcon();

    // Debug: Log healthRecommendation
    if (kDebugMode) {
      debugPrint('🌬️ [AQI Dialog] Building dialog:');
      debugPrint('   healthRecommendation: ${aqiData.healthRecommendation}');
      debugPrint('   Has recommendation: ${aqiData.healthRecommendation != null && aqiData.healthRecommendation!.isNotEmpty}');
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: aqiColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    aqiIcon,
                    color: aqiColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chất lượng không khí',
                        style: AppTextStyles.h4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aqiData.location,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // AQI Value
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: aqiColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: aqiColor,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${aqiData.aqi}',
                          style: AppTextStyles.h1.copyWith(
                            color: aqiColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          aqiData.category,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: aqiColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildMetric('PM2.5', '${aqiData.pm25.toStringAsFixed(1)} µg/m³'),
                      const SizedBox(width: 16),
                      _buildMetric('PM10', '${aqiData.pm10.toStringAsFixed(1)} µg/m³'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recommendation - Always show, use fallback if missing
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khuyến nghị',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            aqiData.healthRecommendation ?? 
                            _getDefaultRecommendation(aqiData.category),
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Đã hiểu'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Get default recommendation if backend doesn't provide one
  String _getDefaultRecommendation(String category) {
    switch (category.toLowerCase()) {
      case 'good':
        return 'Chất lượng không khí tốt. Mọi người có thể hoạt động ngoài trời bình thường.';
      case 'moderate':
        return 'Chất lượng không khí ở mức chấp nhận được. Những người nhạy cảm nên hạn chế hoạt động ngoài trời.';
      case 'unhealthy for sensitive groups':
      case 'unhealthyforsensitivegroups':
        return 'Nhóm nhạy cảm (trẻ em, người già, người mắc bệnh hô hấp) nên hạn chế hoạt động ngoài trời. Người khỏe mạnh có thể hoạt động bình thường.';
      case 'unhealthy':
        return 'Mọi người nên hạn chế hoạt động ngoài trời. Nhóm nhạy cảm nên tránh hoàn toàn. Đeo khẩu trang khi ra ngoài.';
      case 'very unhealthy':
      case 'veryunhealthy':
        return 'CẢNH BÁO: Chất lượng không khí rất kém. Mọi người nên tránh hoạt động ngoài trời. Đóng cửa sổ và sử dụng máy lọc không khí.';
      case 'hazardous':
        return 'CẢNH BÁO NGUY HIỂM: Chất lượng không khí cực kỳ nguy hiểm. Ở trong nhà, đóng tất cả cửa sổ. Chỉ ra ngoài khi thực sự cần thiết và đeo khẩu trang N95.';
      default:
        return 'Chất lượng không khí ở mức chấp nhận được. Những người nhạy cảm nên hạn chế hoạt động ngoài trời.';
    }
  }
}

