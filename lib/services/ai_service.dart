import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class AIService {
  /// The backend endpoint that proxies Gemini API calls server-side.
  /// GEMINI_API_KEY is never passed to Flutter — it lives exclusively in
  /// Vercel server-side environment variables.
  ///
  /// On web (Vercel): calls /api/recommend (same origin, relative URL).
  /// On Android/iOS/desktop: uses the full Vercel production URL via
  ///   --dart-define=AI_BACKEND_URL=https://your-project.vercel.app
  static String get _backendUrl {
    // On web the app is served from the same origin as the API.
    if (kIsWeb) return '/api/recommend';

    // For Android/iOS builds, the backend URL is provided at compile time.
    // No secret is embedded — only a public URL.
    const configured = String.fromEnvironment('AI_BACKEND_URL');
    if (configured.isNotEmpty) return '$configured/api/recommend';

    // Fallback for local development on Android emulator.
    return 'http://10.0.2.2:3000/api/recommend';
  }

  static Future<String> getStyleRecommendation(String promptDetails) async {
    final trimmed = promptDetails.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a description to get AI styling advice.';
    }
    if (trimmed.length > 2000) {
      return 'Your prompt is too long (max 2000 characters). Please shorten it.';
    }

    try {
      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': trimmed}),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return (body['recommendation'] as String?)?.trim() ??
            'No recommendation generated.';
      }

      // Surface the server-side error message to the user.
      final serverMsg = body['error'] as String? ?? 'Unknown error.';
      return 'AI service error: $serverMsg';
    } on http.ClientException catch (e) {
      return 'Network error: could not reach AI service. ($e)';
    } catch (e) {
      return 'Error generating AI recommendation: $e';
    }
  }
}
