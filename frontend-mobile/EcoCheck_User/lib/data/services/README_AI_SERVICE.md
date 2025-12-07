# AI Service Configuration

## Checkpoint System

This directory contains multiple AI service implementations with a checkpoint system for easy rollback:

### Files:
- **`ai_waste_analysis_service.dart`** - Main wrapper service (routes to configured provider)
- **`ai_waste_analysis_service_gemini.dart`** - Google Gemini 1.5 Flash implementation (NEW)
- **`ai_waste_analysis_service_huggingface_backup.dart`** - Hugging Face implementation (BACKUP)
- **`ai_service_config.dart`** - Configuration file to switch between providers

## Switching AI Providers

### To use Gemini (Recommended):
1. Open `ai_service_config.dart`
2. Set `currentProvider = AIProvider.gemini`
3. Get your Gemini API key from: https://makersuite.google.com/app/apikey
4. Update `_defaultApiKey` in `ai_waste_analysis_service_gemini.dart`

### To rollback to Hugging Face:
1. Open `ai_service_config.dart`
2. Set `currentProvider = AIProvider.huggingFace`
3. The old implementation will be used automatically

## Gemini API Key Setup

1. Go to https://makersuite.google.com/app/apikey
2. Create a new API key
3. Copy the key
4. Update `_defaultApiKey` in `ai_waste_analysis_service_gemini.dart`:
   ```dart
   static const String _defaultApiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```

Or set via environment variable:
```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

## Why Gemini 1.5 Flash?

1. **Free Tier**: Generous free package for development
2. **Multimodal**: Can "see" images and understand context
3. **Better Classification**: Uses logical reasoning, not just image recognition
4. **Weight Estimation**: Can estimate weight based on object size in image
5. **Easy Integration**: Direct Flutter support via `google_generative_ai` package

## Troubleshooting

### If Gemini fails:
- Check API key is correct
- Check internet connection
- Check API quota (free tier has limits)
- Rollback to Hugging Face if needed

### If you need to rollback:
1. Change `currentProvider` in `ai_service_config.dart` to `AIProvider.huggingFace`
2. Hot restart the app
3. Old implementation will be used

