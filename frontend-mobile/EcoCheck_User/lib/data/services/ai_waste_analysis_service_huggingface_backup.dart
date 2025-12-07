/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - AI Waste Analysis Service
 * Uses Hugging Face API to analyze waste images
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:eco_check/core/constants/api_constants.dart';

/// AI Analysis Result
class WasteAnalysisResult {
  final String wasteType; // 'household', 'recyclable', 'bulky'
  final String weightCategory; // 'small', 'medium', 'large'
  final double confidence; // 0.0 - 1.0
  final String? description;

  WasteAnalysisResult({
    required this.wasteType,
    required this.weightCategory,
    required this.confidence,
    this.description,
  });
}

/// AI Waste Analysis Service using Backend Proxy (to avoid CORS)
class AIWasteAnalysisService {
  // Use backend proxy to avoid CORS issues on Flutter Web
  static String get _proxyUrl => ApiConstants.baseUrl;

  /// Analyze waste image and return waste type and weight estimate
  static Future<WasteAnalysisResult> analyzeImage(dynamic imageSource) async {
    if (kDebugMode) {
      print('🤖 [AI Service] analyzeImage called with type: ${imageSource.runtimeType}');
    }

    try {
      // Convert image to bytes
      Uint8List imageBytes;
      if (imageSource is File) {
        if (kDebugMode) {
          print('🤖 [AI Service] Reading File: ${imageSource.path}');
        }
        imageBytes = await imageSource.readAsBytes();
      } else if (imageSource is XFile) {
        if (kDebugMode) {
          print('🤖 [AI Service] Reading XFile: ${imageSource.name}, path: ${imageSource.path}');
        }
        imageBytes = await imageSource.readAsBytes();
      } else if (imageSource is Uint8List) {
        if (kDebugMode) {
          print('🤖 [AI Service] Using Uint8List: ${imageSource.length} bytes');
        }
        imageBytes = imageSource;
      } else {
        if (kDebugMode) {
          print('❌ [AI Service] Unsupported image source type: ${imageSource.runtimeType}');
        }
        throw Exception('Unsupported image source type: ${imageSource.runtimeType}');
      }

      if (kDebugMode) {
        print('🤖 [AI Service] Image bytes length: ${imageBytes.length}');
      }

      // Call backend proxy (avoids CORS issues on Flutter Web)
      return await _callBackendProxy(imageBytes);
    } catch (e) {
      if (kDebugMode) {
        print('AI Analysis Error: $e');
      }
      // Fallback to default analysis
      return _fallbackAnalysis(0);
    }
  }

  /// Call backend proxy to avoid CORS issues
  static Future<WasteAnalysisResult> _callBackendProxy(
    Uint8List imageBytes,
  ) async {
    final proxyUrl = '$_proxyUrl/api/ai/analyze-waste';
    if (kDebugMode) {
      print('🤖 [AI Service] Calling backend proxy: $proxyUrl');
      print('🤖 [AI Service] Image size: ${imageBytes.length} bytes');
    }

    try {
      // Convert image to base64 for JSON transport
      final base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse(proxyUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'image': base64Image,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('API request timeout after 30 seconds');
        },
      );

      if (kDebugMode) {
        print('🤖 [AI Service] Proxy Response status: ${response.statusCode}');
        print('🤖 [AI Service] Proxy Response body length: ${response.body.length}');
        if (response.body.length < 1000) {
          print('🤖 [AI Service] Proxy Response preview: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      }

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (result['ok'] == true && result['data'] != null) {
          final aiResult = result['data'];
          
          // Handle both array and object responses
          List<dynamic> predictions;
          if (aiResult is List) {
            predictions = aiResult;
          } else if (aiResult is Map && aiResult.containsKey('error')) {
            // Model is loading
            if (kDebugMode) {
              print('⚠️ [AI Service] Model is loading, retrying...');
            }
            await Future.delayed(const Duration(seconds: 5));
            return _callBackendProxy(imageBytes); // Retry
          } else if (aiResult is Map && aiResult.containsKey('label')) {
            // Single prediction object
            predictions = [aiResult];
          } else {
            predictions = [aiResult];
          }
          return _parseAIResult(predictions, imageBytes.length);
        } else {
          throw Exception('Proxy returned error: ${result['error'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 503) {
        // Model is loading, wait and retry
        if (kDebugMode) {
          print('⚠️ [AI Service] Model is loading (503), retrying...');
        }
        await Future.delayed(const Duration(seconds: 5));
        return _callBackendProxy(imageBytes);
      } else {
        // API error
        final errorData = json.decode(response.body);
        throw Exception('Proxy Error ${response.statusCode}: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AI Service] Proxy error: $e');
      }
      rethrow;
    }
  }

  /// Parse AI result and map to waste categories
  static WasteAnalysisResult _parseAIResult(
    List<dynamic> aiResult,
    int imageSize,
  ) {
    // AI returns list of predictions with labels and scores
    // Example: [{"label": "plastic bottle", "score": 0.95}, ...]
    
    String wasteType = 'household';
    String weightCategory = 'medium';
    double confidence = 0.5;
    String? description;

    if (aiResult.isNotEmpty) {
      if (kDebugMode) {
        print('🤖 [AI Parse] Raw AI result: $aiResult');
      }

      // Analyze ALL predictions, not just top 1
      int recyclableScore = 0;
      int bulkyScore = 0;
      int householdScore = 0;
      double totalConfidence = 0.0;
      List<String> detectedLabels = [];

      // Check top 10 predictions for better accuracy (increased from 5)
      final topPredictions = aiResult.take(10).toList();
      
      for (final prediction in topPredictions) {
        // Handle different response formats
        String label;
        double score;
        
        if (prediction is Map) {
          // Standard format: {"label": "...", "score": 0.95}
          label = ((prediction['label'] ?? prediction['Label'] ?? '').toString()).toLowerCase();
          score = ((prediction['score'] ?? prediction['Score'] ?? 0.0) as num).toDouble();
        } else {
          // Skip invalid predictions
          if (kDebugMode) {
            print('⚠️ [AI Parse] Skipping invalid prediction: $prediction');
          }
          continue;
        }
        
        if (label.isEmpty || score <= 0) {
          continue; // Skip empty or invalid predictions
        }
        
        detectedLabels.add(label);
        totalConfidence += score;

        if (kDebugMode) {
          print('🤖 [AI Parse] Checking label: "$label" (score: ${score.toStringAsFixed(3)})');
        }

        // Score each category with weighted scoring
        // Higher score predictions get more weight
        final weightedScore = (score * 100).round();
        
        if (_isRecyclable(label)) {
          // Give extra weight to recyclable items (multiply by 2.0 for priority)
          recyclableScore += (weightedScore * 2.0).round();
          if (kDebugMode) {
            print('  ✅ Recyclable detected! Added ${(weightedScore * 2.0).round()} points. Total: $recyclableScore');
          }
        }
        if (_isBulky(label)) {
          bulkyScore += weightedScore;
          if (kDebugMode) {
            print('  ✅ Bulky detected! Added $weightedScore points. Total: $bulkyScore');
          }
        }
        if (_isHousehold(label)) {
          householdScore += weightedScore;
          if (kDebugMode) {
            print('  ✅ Household detected! Added $weightedScore points. Total: $householdScore');
          }
        }
      }

      // Determine waste type based on highest score
      // Priority: recyclable > bulky > household
      // If recyclable has ANY score, prioritize it (even if small)
      if (recyclableScore > 0 && recyclableScore >= bulkyScore && recyclableScore >= householdScore) {
        wasteType = 'recyclable';
        confidence = recyclableScore / 100.0;
        description = 'Phát hiện vật liệu tái chế: ${detectedLabels.take(3).join(", ")}';
        if (kDebugMode) {
          print('  ✅ Selected RECYCLABLE (score: $recyclableScore)');
        }
      } else if (bulkyScore > recyclableScore && bulkyScore > householdScore) {
        wasteType = 'bulky';
        confidence = bulkyScore / 100.0;
        description = 'Phát hiện rác cồng kềnh: ${detectedLabels.take(3).join(", ")}';
        if (kDebugMode) {
          print('  ✅ Selected BULKY (score: $bulkyScore)');
        }
      } else {
        wasteType = 'household';
        confidence = householdScore > 0 ? householdScore / 100.0 : totalConfidence / topPredictions.length;
        description = 'Phát hiện rác sinh hoạt: ${detectedLabels.take(3).join(", ")}';
        if (kDebugMode) {
          print('  ✅ Selected HOUSEHOLD (score: $householdScore)');
        }
      }

      if (kDebugMode) {
        print('🤖 [AI Parse] Final decision:');
        print('  - Recyclable score: $recyclableScore');
        print('  - Bulky score: $bulkyScore');
        print('  - Household score: $householdScore');
        print('  - Selected waste type: $wasteType');
        print('  - Confidence: $confidence');
      }

      // Estimate weight based on image size, number of objects, and waste type
      weightCategory = _estimateWeight(imageSize, aiResult.length, wasteType);
    }

    return WasteAnalysisResult(
      wasteType: wasteType,
      weightCategory: weightCategory,
      confidence: confidence,
      description: description,
    );
  }

  /// Check if label indicates recyclable waste
  static bool _isRecyclable(String label) {
    final recyclableKeywords = [
      // Plastic items (most common)
      'bottle', 'bottles', 'plastic', 'plastics', 'container', 'containers',
      'bag', 'bags', 'packaging', 'wrapper', 'wrappers', 'wrapping',
      'cup', 'cups', 'dish', 'dishes', 'utensil', 'utensils', 'straw', 'straws',
      'lid', 'lids', 'cap', 'caps', 'tube', 'tubes', 'jug', 'jugs',
      // Metal items
      'can', 'cans', 'metal', 'metals', 'aluminum', 'aluminium', 'steel', 'tin', 'tins', 'foil',
      // Glass items
      'glass', 'jar', 'jars', 'bottle', 'bottles',
      // Paper items
      'paper', 'papers', 'cardboard', 'newspaper', 'newspapers', 'magazine', 'magazines',
      'book', 'books', 'box', 'boxes', 'carton', 'cartons', 'envelope', 'envelopes', 'folder', 'folders',
      // General recyclable
      'recyclable', 'recycle', 'recycling', 'recycled',
      // Additional common items
      'soda', 'drink', 'drinks', 'beverage', 'beverages', 'water bottle',
    ];
    
    // Check if label contains any recyclable keyword
    final isRecyclable = recyclableKeywords.any((keyword) => label.contains(keyword));
    
    if (kDebugMode && isRecyclable) {
      print('  🔍 Recyclable keyword matched in "$label"');
    }
    
    return isRecyclable;
  }

  /// Check if label indicates household waste
  static bool _isHousehold(String label) {
    final householdKeywords = [
      'food', 'organic', 'garbage', 'trash', 'waste', 'rubbish',
      'kitchen', 'leftover', 'compost', 'vegetable', 'fruit',
      'banana', 'apple', 'orange', 'bread', 'meat', 'fish',
      'egg', 'rice', 'noodle', 'soup', 'dirty', 'soiled',
    ];
    return householdKeywords.any((keyword) => label.contains(keyword));
  }

  /// Check if label indicates bulky waste
  static bool _isBulky(String label) {
    final bulkyKeywords = [
      'furniture', 'appliance', 'mattress', 'sofa', 'chair',
      'table', 'cabinet', 'refrigerator', 'washing machine',
      'television', 'computer', 'electronic', 'bulky',
    ];
    return bulkyKeywords.any((keyword) => label.contains(keyword));
  }

  /// Estimate weight category based on image analysis
  static String _estimateWeight(int imageSize, int objectCount, String wasteType) {
    if (kDebugMode) {
      print('🤖 [AI Weight] Estimating weight:');
      print('  - Image size: $imageSize bytes');
      print('  - Object count: $objectCount');
      print('  - Waste type: $wasteType');
    }

    // Base weight estimation on image size (larger images = more waste visible)
    // Adjusted thresholds for better accuracy
    int sizeThreshold;
    
    // Different thresholds based on waste type
    if (wasteType == 'bulky') {
      // Bulky items are heavier
      sizeThreshold = 300000; // Lower threshold for bulky
    } else if (wasteType == 'recyclable') {
      // Recyclable items can be dense
      sizeThreshold = 400000;
    } else {
      // Household waste
      sizeThreshold = 500000;
    }

    // Estimate based on image size (primary factor)
    String weightCategory;
    if (imageSize > sizeThreshold * 2 || objectCount > 8) {
      weightCategory = 'large'; // 10kg+
      if (kDebugMode) {
        print('  ✅ Large weight detected (>${sizeThreshold * 2} bytes or >8 objects)');
      }
    } else if (imageSize > sizeThreshold || objectCount > 3) {
      weightCategory = 'medium'; // 5kg
      if (kDebugMode) {
        print('  ✅ Medium weight detected (>$sizeThreshold bytes or >3 objects)');
      }
    } else {
      weightCategory = 'small'; // 2kg
      if (kDebugMode) {
        print('  ✅ Small weight detected (<=$sizeThreshold bytes and <=3 objects)');
      }
    }

    return weightCategory;
  }

  /// Fallback analysis when AI fails
  static WasteAnalysisResult _fallbackAnalysis(int imageSize) {
    return WasteAnalysisResult(
      wasteType: 'household',
      weightCategory: imageSize > 300000 ? 'medium' : 'small',
      confidence: 0.3,
      description: 'Không thể phân tích bằng AI, sử dụng giá trị mặc định',
    );
  }
}

