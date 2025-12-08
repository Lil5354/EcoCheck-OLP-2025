/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - AI Waste Analysis Service using Google Gemini 1.5 Flash
 * Multimodal AI that can analyze images and estimate weight
 * 
 * CHECKPOINT: This is the new Gemini implementation
 * Old Hugging Face implementation is in: ai_waste_analysis_service_huggingface_backup.dart
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

/// AI Analysis Result
class WasteAnalysisResult {
  final String wasteType; // 'household', 'recyclable', 'bulky'
  final String weightCategory; // 'small', 'medium', 'large'
  final double confidence; // 0.0 - 1.0
  final String? description;
  final int? estimatedWeightKg; // Estimated weight in kg

  WasteAnalysisResult({
    required this.wasteType,
    required this.weightCategory,
    required this.confidence,
    this.description,
    this.estimatedWeightKg,
  });
}

/// AI Waste Analysis Service using Google Gemini 1.5 Flash
class AIWasteAnalysisServiceGemini {
  // Gemini API Key - Get from: https://makersuite.google.com/app/apikey
  // Or set via environment variable: GEMINI_API_KEY
  static const String _defaultApiKey = 'AIzaSyDsYOlyPw4PlmNXqz8bB4vkuhmnmOxA2O0';
  static String get _apiKey {
    // Try to get from environment variable first
    const String envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    return envKey.isNotEmpty ? envKey : _defaultApiKey;
  }

  // Model: Gemini 2.5 Flash (latest, fast, free tier)
  // List of models to try in order (fallback if one fails)
  static const List<String> _modelNames = [
    'gemini-2.5-flash',         // Latest Gemini 2.5 Flash ✅
  ];

  /// Analyze waste image and return waste type and weight estimate
  static Future<WasteAnalysisResult> analyzeImage(dynamic imageSource) async {
    if (kDebugMode) {
      print('🤖 [Gemini AI] analyzeImage called with type: ${imageSource.runtimeType}');
    }

    try {
      // Convert image to bytes
      Uint8List imageBytes;
      if (imageSource is File) {
        if (kDebugMode) {
          print('🤖 [Gemini AI] Reading File: ${imageSource.path}');
        }
        imageBytes = await imageSource.readAsBytes();
      } else if (imageSource is XFile) {
        if (kDebugMode) {
          print('🤖 [Gemini AI] Reading XFile: ${imageSource.path}');
        }
        imageBytes = await imageSource.readAsBytes();
      } else if (imageSource is Uint8List) {
        if (kDebugMode) {
          print('🤖 [Gemini AI] Using Uint8List: ${imageSource.length} bytes');
        }
        imageBytes = imageSource;
      } else {
        throw Exception('Unsupported image source type: ${imageSource.runtimeType}');
      }

      if (kDebugMode) {
        print('🤖 [Gemini AI] Image bytes: ${imageBytes.length} bytes');
      }

      // Create prompt for waste analysis
      const prompt = '''
Analyze this waste image and provide:
1. Waste type: Choose ONE from: "household", "recyclable", "bulky", or "hazardous"
   - "household": General household waste, organic waste, food scraps
   - "recyclable": Plastic bottles, paper, cardboard, metal cans, glass
   - "bulky": Large items, furniture, appliances, construction waste
   - "hazardous": Industrial waste, batteries, pesticides, chemicals, toxic materials, 
                  electronic waste with batteries, medical waste, paint, oil, 
                  anything dangerous or requiring special disposal

2. Weight estimate: Estimate the weight in kilograms (kg) based on:
   - Size of objects in the image
   - Type of waste (density)
   - Visible quantity

3. Confidence: Rate your confidence (0.0 to 1.0)

IMPORTANT: If you see batteries, pesticides, chemicals, toxic substances, or industrial waste, 
you MUST classify as "hazardous".

Respond in JSON format:
{
  "wasteType": "household|recyclable|bulky|hazardous",
  "estimatedWeightKg": <number>,
  "confidence": <0.0-1.0>,
  "description": "<brief explanation>"
}
''';

      // Try each model until one works
      Exception? lastError;
      for (final modelName in _modelNames) {
        try {
          if (kDebugMode) {
            print('🤖 [Gemini AI] Trying model: $modelName');
          }

          // Initialize Gemini model
          final model = GenerativeModel(
            model: modelName,
            apiKey: _apiKey,
          );

          // Call Gemini API
          final content = [
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', imageBytes),
            ])
          ];

          final response = await model.generateContent(content);
          final text = response.text;

          if (text != null && text.isNotEmpty) {
            if (kDebugMode) {
              print('✅ [Gemini AI] Success with model: $modelName');
              print('🤖 [Gemini AI] Response: $text');
            }
            // Parse and return result
            final result = _parseGeminiResponse(text, imageBytes.length);

            if (kDebugMode) {
              print('✅ [Gemini AI] Analysis result:');
              print('   Waste Type: ${result.wasteType}');
              print('   Weight: ${result.estimatedWeightKg}kg (${result.weightCategory})');
              print('   Confidence: ${result.confidence}');
            }

            return result;
          } else {
            // Empty response, try next model
            if (kDebugMode) {
              print('⚠️ [Gemini AI] Model $modelName returned empty response, trying next...');
            }
            continue;
          }
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
          if (kDebugMode) {
            print('⚠️ [Gemini AI] Model $modelName failed: $e');
          }
          // Continue to next model
          continue;
        }
      }

      // All models failed
      throw lastError ?? Exception('All Gemini models failed');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Gemini AI] Error: $e');
      }
      // Return fallback result
      // Try to get image size if available
      int imageSize = 0;
      try {
        if (imageSource is File) {
          imageSize = await imageSource.length();
        } else if (imageSource is XFile) {
          final bytes = await imageSource.readAsBytes();
          imageSize = bytes.length;
        } else if (imageSource is Uint8List) {
          imageSize = imageSource.length;
        }
      } catch (_) {
        // Ignore errors getting image size
      }
      return _fallbackAnalysis(imageSize);
    }
  }

  /// Parse Gemini response text to WasteAnalysisResult
  static WasteAnalysisResult _parseGeminiResponse(String text, int imageSize) {
    try {
      // Try to extract JSON from response (may be wrapped in markdown code blocks)
      String jsonText = text.trim();
      
      // Remove markdown code blocks if present
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      } else if (jsonText.startsWith('```')) {
        jsonText = jsonText.substring(3);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      // Parse JSON
      final json = jsonDecode(jsonText) as Map<String, dynamic>;

      final wasteType = (json['wasteType'] as String? ?? 'household').toLowerCase();
      final estimatedWeightKg = (json['estimatedWeightKg'] as num?)?.toInt() ?? 2;
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.7;
      final description = json['description'] as String?;

      // Validate waste type
      String validWasteType = 'household';
      if (wasteType == 'recyclable' || 
          wasteType == 'bulky' || 
          wasteType == 'hazardous') {
        validWasteType = wasteType;
      }

      // Determine weight category
      String weightCategory = 'small';
      if (estimatedWeightKg >= 20) {
        weightCategory = 'large';
      } else if (estimatedWeightKg >= 5) {
        weightCategory = 'medium';
      }

      return WasteAnalysisResult(
        wasteType: validWasteType,
        weightCategory: weightCategory,
        confidence: confidence.clamp(0.0, 1.0),
        description: description ?? 'Phân tích bằng Gemini AI',
        estimatedWeightKg: estimatedWeightKg,
      );
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [Gemini AI] Failed to parse JSON, using fallback: $e');
      }
      // Fallback: try to extract information from text
      return _parseTextResponse(text, imageSize);
    }
  }

  /// Fallback: Parse text response if JSON parsing fails
  static WasteAnalysisResult _parseTextResponse(String text, int imageSize) {
    String wasteType = 'household';
    int estimatedWeightKg = 2;
    double confidence = 0.5;

    final lowerText = text.toLowerCase();

    // Try to detect waste type from text - check hazardous first (highest priority)
    if (lowerText.contains('hazardous') || 
        lowerText.contains('battery') || 
        lowerText.contains('batteries') ||
        lowerText.contains('pesticide') ||
        lowerText.contains('chemical') ||
        lowerText.contains('toxic') ||
        lowerText.contains('industrial') ||
        lowerText.contains('pin') ||
        lowerText.contains('thuốc trừ sâu') ||
        (lowerText.contains('thuốc') && lowerText.contains('sâu')) ||
        lowerText.contains('dangerous') ||
        lowerText.contains('medical waste') ||
        lowerText.contains('paint') ||
        lowerText.contains('oil') && lowerText.contains('waste')) {
      wasteType = 'hazardous';
      confidence = 0.7;
    } else if (lowerText.contains('recyclable') || 
        lowerText.contains('plastic') || 
        lowerText.contains('paper') ||
        lowerText.contains('cardboard') ||
        lowerText.contains('bottle') ||
        lowerText.contains('can')) {
      wasteType = 'recyclable';
      confidence = 0.6;
    } else if (lowerText.contains('bulky') || 
               lowerText.contains('large') ||
               lowerText.contains('furniture') ||
               lowerText.contains('appliance')) {
      wasteType = 'bulky';
      confidence = 0.6;
    }

    // Try to extract weight from text
    final weightMatch = RegExp(r'(\d+)\s*kg').firstMatch(lowerText);
    if (weightMatch != null) {
      estimatedWeightKg = int.tryParse(weightMatch.group(1) ?? '') ?? 2;
    }

    // Try to extract confidence
    final confidenceMatch = RegExp(r'confidence[:\s]+([\d.]+)').firstMatch(lowerText);
    if (confidenceMatch != null) {
      confidence = double.tryParse(confidenceMatch.group(1) ?? '') ?? 0.5;
    }

    String weightCategory = 'small';
    if (estimatedWeightKg >= 20) {
      weightCategory = 'large';
    } else if (estimatedWeightKg >= 5) {
      weightCategory = 'medium';
    }

    return WasteAnalysisResult(
      wasteType: wasteType,
      weightCategory: weightCategory,
      confidence: confidence,
      description: 'Phân tích bằng Gemini AI (text parsing)',
      estimatedWeightKg: estimatedWeightKg,
    );
  }

  /// Fallback analysis when API fails
  static WasteAnalysisResult _fallbackAnalysis(int imageSize) {
    if (kDebugMode) {
      print('⚠️ [Gemini AI] Using fallback analysis');
    }

    // Estimate based on image size
    String weightCategory = 'small';
    int estimatedWeightKg = 2;

    if (imageSize > 500000) {
      // Large image might mean more waste
      weightCategory = 'medium';
      estimatedWeightKg = 5;
    }

    return WasteAnalysisResult(
      wasteType: 'household',
      weightCategory: weightCategory,
      confidence: 0.3,
      description: 'Không thể phân tích bằng AI, sử dụng giá trị mặc định',
      estimatedWeightKg: estimatedWeightKg,
    );
  }
}

