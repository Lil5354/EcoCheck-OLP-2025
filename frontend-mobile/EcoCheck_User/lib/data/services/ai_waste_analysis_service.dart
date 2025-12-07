/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - AI Waste Analysis Service (Wrapper)
 * Switches between Hugging Face and Gemini based on config
 * 
 * CHECKPOINT: This is the main service that routes to either:
 * - ai_waste_analysis_service_huggingface_backup.dart (old Hugging Face)
 * - ai_waste_analysis_service_gemini.dart (new Gemini)
 */

import 'ai_service_config.dart' show AIServiceConfig, AIProvider;
import 'ai_waste_analysis_service_gemini.dart' as gemini;
import 'ai_waste_analysis_service_huggingface_backup.dart' as huggingface;

/// Re-export WasteAnalysisResult
export 'ai_waste_analysis_service_gemini.dart' show WasteAnalysisResult;

/// AI Waste Analysis Service - Routes to configured provider
class AIWasteAnalysisService {
  /// Analyze waste image and return waste type and weight estimate
  static Future<gemini.WasteAnalysisResult> analyzeImage(dynamic imageSource) {
    switch (AIServiceConfig.currentProvider) {
      case AIProvider.gemini:
        return gemini.AIWasteAnalysisServiceGemini.analyzeImage(imageSource);
      case AIProvider.huggingFace:
        // Convert Hugging Face result to Gemini format
        return huggingface.AIWasteAnalysisService
            .analyzeImage(imageSource)
            .then((result) => gemini.WasteAnalysisResult(
                  wasteType: result.wasteType,
                  weightCategory: result.weightCategory,
                  confidence: result.confidence,
                  description: result.description,
                  estimatedWeightKg: _convertWeightCategoryToKg(result.weightCategory),
                ));
    }
  }

  /// Convert weight category to estimated kg
  static int _convertWeightCategoryToKg(String category) {
    switch (category) {
      case 'small':
        return 2;
      case 'medium':
        return 5;
      case 'large':
        return 10;
      default:
        return 2;
    }
  }
}
