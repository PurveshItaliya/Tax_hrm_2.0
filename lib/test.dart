
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // TODO: Move API key to a secure backend for production.
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  // Available model selection
  static const String flashModel = 'gemini-2.5-flash';
  static const String flashLiteModel = 'gemini-2.5-flash-lite';
  static const String proModel = 'gemini-2.5-pro';

  /// MASTER GEMINI API FUNCTION
  ///
  /// Supports:
  /// 1. Text-based prompts
  /// 2. Single or multiple image analysis
  /// 3. Custom system instructions
  /// 4. Dynamic model selection
  /// 5. Temperature and token configuration
  /// 6. Structured error handling

  static Future<String> generate({
    required String prompt,

    // Optional image support
    List<File>? images,

    // Model selection
    String model = flashModel,

    // Optional system instruction
    String? systemInstruction,

    // Generation configuration
    double temperature = 0.2,
    int maxOutputTokens = 2048,

    // Response format: text, application/json
    String? responseMimeType,
  }) async {
    try {
      final gemini = GenerativeModel(
        model: model,
        apiKey: _apiKey,
        systemInstruction: systemInstruction != null
            ? Content.system(systemInstruction)
            : null,
        generationConfig: GenerationConfig(
          temperature: temperature,
          maxOutputTokens: maxOutputTokens,
          responseMimeType: responseMimeType,
        ),
      );

      // Build request content
      final List<Part> parts = [
        TextPart(prompt),
      ];

      // Attach multiple images if provided
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          final bytes = await image.readAsBytes();

          final extension = image.path.split('.').last.toLowerCase();
          final mimeType = extension == 'png'
              ? 'image/png'
              : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

          parts.add(
            DataPart(mimeType, bytes),
          );
        }
      }

      // Generate response
      final response = await gemini.generateContent([
        Content.multi(parts),
      ]);

      return response.text ?? '';
    } on GenerativeAIException catch (e) {
      throw Exception('Gemini API Error: ${e.message}');
    } catch (e) {
      throw Exception('Gemini Error: $e');
    }
  }
}
