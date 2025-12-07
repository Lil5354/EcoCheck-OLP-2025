/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Air Quality Service - Fetches AQI data from backend
 */

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Air Quality Data Model
class AirQualityData {
  final int aqi;
  final double pm25;
  final double pm10;
  final String category;
  final String? healthRecommendation;
  final String location;
  final double? distance;
  final String? source;
  final String? lastUpdated;

  AirQualityData({
    required this.aqi,
    required this.pm25,
    required this.pm10,
    required this.category,
    this.healthRecommendation,
    required this.location,
    this.distance,
    this.source,
    this.lastUpdated,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    return AirQualityData(
      aqi: json['aqi'] as int? ?? 0,
      pm25: (json['pm25'] as num?)?.toDouble() ?? 0.0,
      pm10: (json['pm10'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Unknown',
      healthRecommendation: json['healthRecommendation'] as String?,
      location: json['location'] as String? ?? 'Unknown',
      distance: (json['distance'] as num?)?.toDouble(),
      source: json['source'] as String?,
      lastUpdated: json['lastUpdated'] as String?,
    );
  }

  /// Get AQI color based on category
  String get aqiColor {
    switch (category.toLowerCase()) {
      case 'good':
        return 'green';
      case 'moderate':
        return 'yellow';
      case 'unhealthy for sensitive groups':
        return 'orange';
      case 'unhealthy':
        return 'red';
      case 'very unhealthy':
        return 'purple';
      case 'hazardous':
        return 'maroon';
      default:
        return 'grey';
    }
  }
}

/// Air Quality Service
class AirQualityService {
  final ApiClient _apiClient = ApiClient();

  /// Get air quality data for a location
  Future<AirQualityData> getAirQuality({
    required double lat,
    required double lon,
  }) async {
    try {
      if (kDebugMode) {
        print('🌬️ [AirQuality] Fetching AQI for lat: $lat, lon: $lon');
      }

      final response = await _apiClient.get(
        ApiConstants.airQuality,
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['ok'] == true && data['data'] != null) {
          final aqiData = AirQualityData.fromJson(data['data']);
          if (kDebugMode) {
            print('✅ [AirQuality] AQI: ${aqiData.aqi}, Category: ${aqiData.category}');
            print('   Recommendation: ${aqiData.healthRecommendation}');
          }
          return aqiData;
        } else {
          throw Exception(data['error'] ?? 'Failed to get air quality data');
        }
      } else {
        throw Exception('Invalid response from server');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AirQuality] Error: $e');
      }
      rethrow;
    }
  }

  /// Get air quality for Ho Chi Minh City (default location)
  Future<AirQualityData> getAirQualityHCMC() async {
    // Default HCMC coordinates
    const double hcmcLat = 10.8231;
    const double hcmcLon = 106.6297;
    return getAirQuality(lat: hcmcLat, lon: hcmcLon);
  }
}

