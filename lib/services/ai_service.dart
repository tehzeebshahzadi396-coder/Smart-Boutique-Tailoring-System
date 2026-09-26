import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String apiKey =
      'AQ.Ab8RN6JrH-YTsUzIMVt-RjqhCtyB5vsmlsumTunU9jkW-Es4mw';

  static Future<String> getStyleRecommendation(String promptDetails) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final prompt =
          'As an expert boutique fashion designer, provide styling and tailoring advice for: $promptDetails';
      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ?? 'No recommendation generated.';
    } catch (e) {
      return 'Error generating AI recommendation: $e';
    }
  }
}
