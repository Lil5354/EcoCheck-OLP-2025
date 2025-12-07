/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * AI Service Configuration
 * Switch between Hugging Face and Gemini AI
 */

/// AI Provider Type
enum AIProvider {
  huggingFace, // Old implementation (backup)
  gemini,      // New Gemini implementation
}

/// AI Service Configuration
class AIServiceConfig {
  // Change this to switch between AI providers
  // Temporarily using Hugging Face because Gemini models are not available
  static const AIProvider currentProvider = AIProvider.huggingFace;

  /// Get the current provider name
  static String get providerName {
    switch (currentProvider) {
      case AIProvider.huggingFace:
        return 'Hugging Face';
      case AIProvider.gemini:
        return 'Google Gemini';
    }
  }
}

